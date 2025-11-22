import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/chat_model.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/services/chat_service.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  late final ChatService _chatService;
  
  final List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  final Map<String, StreamSubscription<List<Message>>?> _messageSubscriptions = {};
  final Map<String, bool> _streamInitialized = {};
  
  bool _isLoading = false;
  String? _error;
  bool _isConnected = true;
  
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<List<Message>> _activeChatController = StreamController<List<Message>>.broadcast();

  ChatProvider(this._supabase) {
    _chatService = ChatService(_supabase);
    _setupConnectionMonitoring();
  }

  List<Chat> get chats => List.unmodifiable(_chats);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<List<Message>> get activeChatStream => _activeChatController.stream;

  List<Message> getMessages(String chatId) => List.unmodifiable(_messages[chatId] ?? []);

  void _setupConnectionMonitoring() {
    try {
      final realtime = _supabase.realtime;
      final onStatusChange = (realtime as dynamic).onStatusChange;
      if (onStatusChange is Stream) {
        onStatusChange.listen((status) {
          final statusStr = status?.toString() ?? '';
          final newConnectionState = statusStr.toLowerCase().contains('connected');

          if (_isConnected != newConnectionState) {
            _isConnected = newConnectionState;
            _connectionController.add(_isConnected);
            AppLogger.d(_isConnected ? '✅ Conexión restaurada' : '❌ Conexión perdida');
            notifyListeners();
          }
        });
      } else {
        AppLogger.w('onStatusChange no disponible en RealtimeClient; omitiendo monitoreo activo.');
      }
    } catch (e) {
      AppLogger.w('No se pudo configurar monitoreo de conexión: $e');
    }
  }

  Future<void> loadUserChats(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📥 Cargando chats para usuario: $userId');
      
      final response = await _supabase
          .from('chats')
          .select('''
            id, 
            product_id, 
            buyer_id, 
            seller_id, 
            created_at, 
            updated_at,
            products (
              titulo,
              imagen_url,
              precio,
              moneda,
              disponible,
              user_id
            )
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('updated_at', ascending: false);

      _chats.clear();
      _chats.addAll((response as List)
          .map((data) => Chat.fromMap(Map<String, dynamic>.from(data)))
          .toList());
         
      AppLogger.d('✅ ${_chats.length} chats cargados');
      
      await _loadUnreadCounts(userId);
      _setupChatsRealTime(userId);
    } catch (e) {
      _error = 'Error al cargar chats: $e';
      AppLogger.e('Error loadUserChats', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    try {
      AppLogger.d('📨 Configurando stream para chat: $chatId');
      
      // ✅ VERIFICAR SI EL STREAM YA ESTÁ INICIALIZADO
      if (_streamInitialized[chatId] == true) {
        AppLogger.d('✅ Stream ya inicializado para chat: $chatId');
        return;
      }
      
      _messageSubscriptions[chatId]?.cancel();

      final initialMessages = await _chatService.loadMessages(chatId);
      _messages[chatId] = initialMessages;
      _activeChatController.add(initialMessages);

      // ✅ INICIALIZAR STREAM SOLO UNA VEZ
      final subscription = _chatService.getMessagesStream(chatId).listen(
        (messages) {
          _messages[chatId] = messages;
          _activeChatController.add(messages);
          AppLogger.d('🔄 ${messages.length} mensajes actualizados en tiempo real');
        },
        onError: (error) {
          AppLogger.e('Error en stream de mensajes para chat $chatId', error);
          _error = 'Error en conexión de mensajes: $error';
          notifyListeners();
        }
      );

      _messageSubscriptions[chatId] = subscription;
      _streamInitialized[chatId] = true;
      
    } catch (e) {
      _error = 'Error al cargar mensajes: $e';
      AppLogger.e('Error cargando mensajes', e);
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      AppLogger.d('✉️ Enviando mensaje en chat: $chatId');
      
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        text: text.trim(),
        fromId: fromId,
        createdAt: DateTime.now(),
        read: false,
        isSystem: false,
      );

      _messages[chatId] = [..._messages[chatId] ?? [], tempMessage];
      _activeChatController.add(_messages[chatId]!);
      
      await _chatService.sendMessageOptimistic(
        chatId: chatId,
        text: text,
        fromId: fromId,
      );

      AppLogger.d('✅ Mensaje enviado en chat $chatId');
      
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      AppLogger.e('Error enviando mensaje', e);
      
      final current = _messages[chatId] ?? [];
      _messages[chatId] = current.where((m) => !m.id.startsWith('temp_')).toList();
      _activeChatController.add(_messages[chatId]!);
      
      rethrow;
    }
  }

  // ✅ NUEVO: MÉTODO PARA MENSAJES DEL SISTEMA
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      AppLogger.d('🤖 Enviando mensaje de sistema en chat: $chatId');
      
      final systemMessage = {
        'chat_id': chatId,
        'text': text,
        'from_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'is_system': true,
      };

      await _supabase.from('messages').insert(systemMessage);
      AppLogger.d('✅ Mensaje de sistema enviado');
      
    } catch (e) {
      AppLogger.e('Error enviando mensaje de sistema', e);
    }
  }

  Future<String> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      AppLogger.d('💬 Buscando o creando chat para producto: $productId');
      
      if (buyerId == sellerId) {
        throw Exception('No puedes crear un chat contigo mismo');
      }

      final existingChats = await _supabase
          .from('chats')
          .select('id, product_id, buyer_id, seller_id, created_at')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId);

      if (existingChats.isNotEmpty && existingChats.first['id'] != null) {
        final chatId = existingChats.first['id'] as String;
        AppLogger.d('✅ Chat existente encontrado: $chatId');
        return chatId;
      }

      AppLogger.d('🆕 Creando nuevo chat...');
      final newChat = await _supabase
          .from('chats')
          .insert({
            'product_id': productId,
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id, created_at')
          .single();

      final chatId = newChat['id'] as String;
      AppLogger.d('✅ Nuevo chat creado: $chatId');
      
      return chatId;
    } catch (e) {
      _error = 'Error al crear chat: $e';
      AppLogger.e('Error creando chat', e);
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, currentUserId);

      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos', e);
    }
  }

  Future<void> _loadUnreadCounts(String userId) async {
    try {
      for (final chat in _chats) {
        final unreadResponse = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chat.id)
            .eq('read', false)
            .neq('from_id', userId);

        final unreadCount = unreadResponse.length;
        final chatIndex = _chats.indexWhere((c) => c.id == chat.id);
        if (chatIndex != -1) {
          _chats[chatIndex] = chat.copyWith(unreadCount: unreadCount);
        }
      }
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error cargando conteos no leídos', e);
    }
  }

  void _setupChatsRealTime(String userId) {
    try {
      final channel = _supabase.channel('user_chats:$userId');
      
      // Suscribirse a cambios en la tabla `chats` para buyer_id
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chats',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'buyer_id',
          value: userId,
        ),
        callback: (payload) {
          AppLogger.d('🔄 Actualización en tiempo real de chats (buyer)');
          loadUserChats(userId);
        }
      );

      // También suscribirse a cambios para seller_id
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chats',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'seller_id',
          value: userId,
        ),
        callback: (payload) {
          AppLogger.d('🔄 Actualización en tiempo real de chats (seller)');
          loadUserChats(userId);
        }
      );

      channel.subscribe();
      
    } catch (e) {
      AppLogger.e('Error configurando realtime chats', e);
    }
  }

  // ✅ ELIMINACIÓN REAL DE MENSAJES
  Future<void> deleteMessage(String messageId, String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje permanentemente: $messageId');
      
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      AppLogger.d('✅ Mensaje eliminado permanentemente de Supabase: $messageId');
      
      final messages = _messages[chatId];
      if (messages != null) {
        _messages[chatId] = messages.where((m) => m.id != messageId).toList();
        notifyListeners();
      }
      
    } catch (e) {
      _error = 'Error al eliminar mensaje: $e';
      AppLogger.e('Error eliminando mensaje', e);
      rethrow;
    }
  }

  // ✅ ELIMINACIÓN REAL DE CHAT COMPLETO
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando chat completo permanentemente: $chatId');
      
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

      await _supabase
          .from('chats')
          .delete()
          .eq('id', chatId);

      AppLogger.d('✅ Chat eliminado permanentemente de Supabase: $chatId');
      
      _chats.removeWhere((chat) => chat.id == chatId);
      _messages.remove(chatId);
      _messageSubscriptions[chatId]?.cancel();
      _messageSubscriptions.remove(chatId);
      _streamInitialized.remove(chatId);
      
      notifyListeners();
      
    } catch (e) {
      _error = 'Error al eliminar chat: $e';
      AppLogger.e('Error eliminando chat', e);
      rethrow;
    }
  }

  // ✅ ELIMINACIÓN DE VARIOS MENSAJES A LA VEZ
  Future<void> deleteMultipleMessages(List<String> messageIds, String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando ${messageIds.length} mensajes permanentemente');
      
      // Algunas versiones del cliente no exponen `in_`; eliminar uno por uno.
      for (final id in messageIds) {
        await _supabase.from('messages').delete().eq('id', id);
      }

      AppLogger.d('✅ ${messageIds.length} mensajes eliminados de Supabase');
      
      final messages = _messages[chatId];
      if (messages != null) {
        _messages[chatId] = messages.where((m) => !messageIds.contains(m.id)).toList();
        notifyListeners();
      }
      
    } catch (e) {
      _error = 'Error al eliminar múltiples mensajes: $e';
      AppLogger.e('Error eliminando múltiples mensajes', e);
      rethrow;
    }
  }

  // ✅ FORMATO DE HORA EXACTA
  String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    AppLogger.d('🧹 Dispose ChatProvider');
    
    _messageSubscriptions.forEach((chatId, subscription) {
      subscription?.cancel();
      _chatService.disposeChatStream(chatId);
    });
    _messageSubscriptions.clear();
    _streamInitialized.clear();
    
    _connectionController.close();
    _activeChatController.close();
    
    _chatService.disposeAll();
    
    super.dispose();
  }

  void cancelChatStream(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _streamInitialized.remove(chatId);
    _chatService.disposeChatStream(chatId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> reconnect() async {
    AppLogger.d('🔁 Reconectando ChatProvider...');
    _isConnected = false;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _isConnected = true;
    _connectionController.add(true);
    notifyListeners();
  }
}