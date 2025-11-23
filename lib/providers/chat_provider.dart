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

  // ==========================================
  // CARGA INICIAL DE CHATS (LISTADO)
  // ==========================================
  Future<void> loadUserChats(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📥 Cargando chats para usuario: $userId');
      
      // ✅ ARREGLO CLAVE: Cambiamos 'name' por 'username' en la consulta
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
            ),
            buyer:profiles!chats_buyer_id_fkey(id, username, avatar_url),
            seller:profiles!chats_seller_id_fkey(id, username, avatar_url)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('updated_at', ascending: false);

      _chats.clear();
      
      // ✅ PROCESAR CADA CHAT Y MAPEAR DETALLES DEL PRODUCTO Y USUARIO
      for (var chatData in response) {
        final chat = Chat.fromMap(Map<String, dynamic>.from(chatData));
        
        final isCurrentUserBuyer = chat.buyerId == userId;
        final otherUserProfile = isCurrentUserBuyer 
            ? chatData['seller'] 
            : chatData['buyer'];
        
        // ✅ ARREGLO CLAVE: Leemos 'username' del mapa en lugar de 'name'
        final otherUserName = otherUserProfile?['username'] as String?;
        final otherUserAvatar = otherUserProfile?['avatar_url'] as String?;

        // ✅ AGREGANDO MAPPING DE DETALLES DEL PRODUCTO (Faltaba en tu archivo)
        final productMap = chatData['products'] as Map<String, dynamic>?;
        
        _chats.add(chat.copyWith(
          productTitle: productMap?['titulo'] as String?,
          productImage: productMap?['imagen_url'] as String?,
          productPrice: (productMap?['precio'] as num?)?.toDouble(), // Mapeo de precio
          productCurrency: productMap?['moneda'] as String?,
          productAvailable: productMap?['disponible'] as bool?,
          otherUserName: otherUserName,
          otherUserAvatar: otherUserAvatar,
        ));
      }
         
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

  // ==========================================
  // CARGA DE MENSAJES (PANTALLA DE CHAT)
  // Se mantiene la lógica de tu última versión.
  // ==========================================
  Future<void> loadChatMessages(String chatId) async {
    try {
      AppLogger.d('📨 Configurando stream para chat: $chatId');
      
      if (_streamInitialized[chatId] == true) {
        AppLogger.d('✅ Stream ya inicializado para chat: $chatId');
        return;
      }
      
      _messageSubscriptions[chatId]?.cancel();

      // Usamos loadMessages asumiendo que este método existe en ChatService
      final initialMessages = await _chatService.loadMessages(chatId); 
      _messages[chatId] = initialMessages;
      _activeChatController.add(initialMessages);

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

  // ==========================================
  // LÓGICA DE ENVÍO Y LECTURA
  // ==========================================
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      AppLogger.d('✉️ Enviando mensaje en chat: $chatId');
      
      // ✅ ACTUALIZACIÓN OPTIMISTA
      final tempMessage = Message(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        text: text.trim(),
        fromId: fromId,
        createdAt: DateTime.now(),
        read: false,
        isSystem: false,
      );

      final currentMessages = _messages[chatId] ?? [];
      _messages[chatId] = [...currentMessages, tempMessage];
      _activeChatController.add(_messages[chatId]!);
      
      await _chatService.sendMessageOptimistic(
        chatId: chatId,
        text: text,
        fromId: fromId,
      );

      // Mover el chat al principio de la lista y actualizar el último mensaje
      final chatIndex = _chats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        final chat = _chats.removeAt(chatIndex);
        _chats.insert(0, chat.copyWith(
          lastMessage: text.trim(),
          updatedAt: DateTime.now(),
        ));
      }

      AppLogger.d('✅ Mensaje enviado en chat $chatId');
      
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      AppLogger.e('Error enviando mensaje', e);
      
      // Revertir el estado optimista si falla
      final current = _messages[chatId] ?? [];
      _messages[chatId] = current.where((m) => !m.id.startsWith('temp_')).toList();
      _activeChatController.add(_messages[chatId]!);
      
      rethrow;
    } finally {
      notifyListeners(); // Notificar cambios en la lista de chats o si falló la actualización optimista
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

  // ✅ MÉTODO PARA MENSAJES DEL SISTEMA
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
          .select('id')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .limit(1);

      if (existingChats.isNotEmpty) {
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
          .select('id')
          .single();

      final chatId = newChat['id'] as String;
      AppLogger.d('✅ Nuevo chat creado: $chatId');
      
      loadUserChats(buyerId); // Recargar la lista de chats para incluir el nuevo
      
      return chatId;
    } catch (e) {
      _error = 'Error al crear chat: $e';
      AppLogger.e('Error creando chat', e);
      rethrow;
    }
  }

  // ==========================================
  // UTILIDADES Y REALTIME
  // ==========================================

  Future<void> _loadUnreadCounts(String userId) async {
    try {
      // Recorremos los chats y hacemos una consulta por separado para el conteo de no leídos
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
      // Escuchar cambios donde buyer_id == userId
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chats',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'buyer_id',
          value: 'eq.$userId',
        ),
        callback: (payload) {
          AppLogger.d('🔄 Actualización realtime chats (buyer): ${payload.eventType}');
          loadUserChats(userId);
        }
      );

      // Escuchar cambios donde seller_id == userId
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chats',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'seller_id',
          value: 'eq.$userId',
        ),
        callback: (payload) {
          AppLogger.d('🔄 Actualización realtime chats (seller): ${payload.eventType}');
          loadUserChats(userId);
        }
      );

      channel.subscribe();
      
    } catch (e) {
      AppLogger.e('Error configurando realtime chats', e);
    }
  }

  // ✅ FUNCIONES DE ELIMINACIÓN
  
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
        _activeChatController.add(_messages[chatId]!);
        notifyListeners(); 
      }
      
    } catch (e) {
      _error = 'Error al eliminar mensaje: $e';
      AppLogger.e('Error eliminando mensaje', e);
      rethrow;
    }
  }

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
      cancelChatStream(chatId);
      
      notifyListeners();
      
    } catch (e) {
      _error = 'Error al eliminar chat: $e';
      AppLogger.e('Error eliminando chat', e);
      rethrow;
    }
  }

  Future<void> deleteMultipleMessages(List<String> messageIds, String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando ${messageIds.length} mensajes permanentemente');
      
      // Algunas versiones del cliente no exponen `.in_`; eliminar uno por uno.
      for (final id in messageIds) {
        await _supabase.from('messages').delete().eq('id', id);
      }

      AppLogger.d('✅ ${messageIds.length} mensajes eliminados de Supabase');
      
      final messages = _messages[chatId];
      if (messages != null) {
        _messages[chatId] = messages.where((m) => !messageIds.contains(m.id)).toList();
        _activeChatController.add(_messages[chatId]!);
        notifyListeners(); 
      }
      
    } catch (e) {
      _error = 'Error al eliminar múltiples mensajes: $e';
      AppLogger.e('Error eliminando múltiples mensajes', e);
      rethrow;
    }
  }

  /// Cancela el stream de mensajes y limpia recursos asociados a un chat concreto
  void cancelChatStream(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
    _streamInitialized.remove(chatId);
    _chatService.disposeChatStream(chatId);
  }
  
  // ✅ FORMATO DE HORA
  String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return "Ayer ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
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

}