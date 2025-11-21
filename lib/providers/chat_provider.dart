import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/chat_model.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Chat> _chats = [];
  final Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _error;
  final Map<String, StreamSubscription?> _messageSubscriptions = {};
  final Map<String, StreamSubscription?> _chatSubscriptions = {};

  ChatProvider(this._supabase);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Message> getMessages(String chatId) => _messages[chatId] ?? [];

  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }

  void _cancelAllSubscriptions() {
    _messageSubscriptions.forEach((chatId, subscription) {
      subscription?.cancel();
    });
    _chatSubscriptions.forEach((key, subscription) {
      subscription?.cancel();
    });
    _messageSubscriptions.clear();
    _chatSubscriptions.clear();
  }

  Future<void> loadUserChats(String userId) async {
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

      _chats = (response as List)
          .map((data) => Chat.fromMap(Map<String, dynamic>.from(data)))
          .toList();
         
      AppLogger.d('✅ Chats cargados: ${_chats.length}');
      
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
      _chatSubscriptions['chats']?.cancel();

      final dynamic dyn = (_supabase.from('chats') as dynamic).stream(primaryKey: ['id']);

      try {
        final sub = dyn.eq('buyer_id', userId).or('seller_id.eq.$userId').listen((data) {
          AppLogger.d('🔄 Actualización en tiempo real de chats');
          loadUserChats(userId);
        });
        _chatSubscriptions['chats'] = sub;
      } catch (e) {
        // Fallback: suscribir por separado si `or` no está disponible
        try {
          final subBuyer = dyn.eq('buyer_id', userId).listen((data) {
            AppLogger.d('🔄 Actualización chat (buyer)');
            loadUserChats(userId);
          });
          final subSeller = dyn.eq('seller_id', userId).listen((data) {
            AppLogger.d('🔄 Actualización chat (seller)');
            loadUserChats(userId);
          });
          _chatSubscriptions['chats_buyer'] = subBuyer;
          _chatSubscriptions['chats_seller'] = subSeller;
        } catch (e2) {
          AppLogger.e('Error configurando fallback realtime chats', e2);
        }
      }
    } catch (e) {
      AppLogger.e('Error configurando realtime chats', e);
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    try {
      AppLogger.d('📨 Cargando mensajes para chat: $chatId');
      
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      _messages[chatId] = (response as List)
          .map((data) => Message.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Mensajes cargados: ${_messages[chatId]?.length ?? 0}');
      notifyListeners();
      
      _setupMessageStream(chatId);
    } catch (e) {
      _error = 'Error al cargar mensajes: $e';
      AppLogger.e('Error cargando mensajes', e);
      rethrow;
    }
  }

  void _setupMessageStream(String chatId) {
    try {
      _messageSubscriptions[chatId]?.cancel();

      final subscription = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .listen((data) {
        AppLogger.d('🔄 Nuevos mensajes en tiempo real para chat: $chatId');
        if (data.isNotEmpty) {
          _messages[chatId] = data
              .map((msgData) => Message.fromMap(Map<String, dynamic>.from(msgData)))
              .toList();
          notifyListeners();
        }
      });

      _messageSubscriptions[chatId] = subscription;
    } catch (e) {
      AppLogger.e('Error configurando stream de mensajes', e);
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
      
      final newMessage = {
        'chat_id': chatId,
        'text': text.trim(),
        'from_id': fromId,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'is_system': false,
      };

      await _supabase.from('messages').insert(newMessage);

      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje enviado en chat $chatId');
      
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      AppLogger.e('Error enviando mensaje', e);
      rethrow;
    }
  }

  // ✅ MÉTODO SEGURO PARA MENSAJES DEL SISTEMA
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      AppLogger.d('🤖 Enviando mensaje de sistema en chat: $chatId');
      
      // INTENTO 1: Usar from_id: null (funciona después del ALTER TABLE)
      final systemMessage = {
        'chat_id': chatId,
        'text': text,
        'from_id': null, // ✅ Esto funcionará después del comando SQL
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'is_system': true,
      };

      await _supabase.from('messages').insert(systemMessage);
      AppLogger.d('✅ Mensaje de sistema enviado con from_id: null');
      
    } catch (e) {
      AppLogger.e('Error enviando mensaje de sistema', e);
      // No relanzamos la excepción para no bloquear el flujo
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
      
      await sendSystemMessage(
        chatId: chatId,
        text: '¡Conversación iniciada! Pueden coordinar la transacción aquí.',
      );
      
      return chatId;
    } catch (e) {
      _error = 'Error al crear chat: $e';
      AppLogger.e('Error creando chat', e);
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read': true})
          .eq('chat_id', chatId)
          .neq('from_id', currentUserId)
          .eq('read', false);

      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos', e);
    }
  }

  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, chat_id')
          .eq('read', false)
          .neq('from_id', userId);

      final chatIds = _chats.map((chat) => chat.id).toList();
      final unreadMessages = response.where((msg) => chatIds.contains(msg['chat_id'])).toList();
      
      return unreadMessages.length;
    } catch (e) {
      AppLogger.e('Error obteniendo total de mensajes no leídos', e);
      return 0;
    }
  }

  int getUnreadCountForChat(String chatId) {
    final chat = _chats.firstWhere((chat) => chat.id == chatId, orElse: () => Chat(
      id: '',
      productId: '',
      buyerId: '',
      sellerId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return chat.unreadCount;
  }

  void cancelChatStream(String chatId) {
    _messageSubscriptions[chatId]?.cancel();
    _messageSubscriptions.remove(chatId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshChats(String userId) async {
    await loadUserChats(userId);
  }

  void clearMessages(String chatId) {
    _messages.remove(chatId);
    notifyListeners();
  }
}