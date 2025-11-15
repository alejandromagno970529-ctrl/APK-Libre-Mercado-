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

  ChatProvider(this._supabase);

  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Message> getMessages(String chatId) => _messages[chatId] ?? [];

  Future<void> loadUserChats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📥 Cargando chats para usuario: $userId');
      
      // ✅ Cargar chats básicos
      final response = await _supabase
          .from('chats')
          .select('id, product_id, buyer_id, seller_id, created_at, updated_at')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('updated_at', ascending: false);

      _chats = (response as List)
          .map((data) {
            final createdAt = DateTime.parse(data['created_at']);
            final updatedAt = data['updated_at'] != null
                ? DateTime.parse(data['updated_at'])
                : createdAt;
            return Chat(
              id: data['id'] as String,
              productId: data['product_id'] as String,
              buyerId: data['buyer_id'] as String,
              sellerId: data['seller_id'] as String,
              createdAt: createdAt,
              updatedAt: updatedAt,
            );
          })
          .toList();
         
      AppLogger.d('✅ Chats básicos cargados: ${_chats.length}');
      
      // ✅ Cargar información de productos y últimos mensajes
      await _loadChatsDetailedInfo();
    } catch (e) {
      _error = 'Error al cargar chats: $e';
      AppLogger.e('Error loadUserChats', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Cargar información detallada de chats
  Future<void> _loadChatsDetailedInfo() async {
    try {
      AppLogger.d('🔄 Cargando información detallada de chats...');
      
      final List<Chat> updatedChats = [];
      
      for (final chat in _chats) {
        try {
          // Cargar información del producto
          final productResponse = await _supabase
            .from('products')
            .select('titulo, imagen_url, precio, moneda, disponible, user_id')
            .eq('id', chat.productId)
            .maybeSingle();

          // Cargar último mensaje
          final lastMessageResponse = await _supabase
            .from('messages')
            .select('text, created_at')
            .eq('chat_id', chat.id)
            .order('created_at', ascending: false)
            .limit(1);

          String? lastMessage;
          if (lastMessageResponse.isNotEmpty) {
            lastMessage = lastMessageResponse[0]['text'] as String?;
          }

          if (productResponse != null) {
            final updatedChat = Chat(
              id: chat.id,
              productId: chat.productId,
              buyerId: chat.buyerId,
              sellerId: chat.sellerId,
              createdAt: chat.createdAt,
              updatedAt: chat.updatedAt,
              productTitle: productResponse['titulo'] as String? ?? 'Producto',
              productImage: productResponse['imagen_url'] as String?,
              productPrice: productResponse['precio'] != null
                  ? (productResponse['precio'] is num
                      ? (productResponse['precio'] as num).toDouble()
                      : 0.0)
                  : 0.0,
              productCurrency: productResponse['moneda'] as String? ?? 'CUP',
              lastMessage: lastMessage,
              productAvailable: productResponse['disponible'] as bool? ?? true,
            );
            updatedChats.add(updatedChat);
          } else {
            updatedChats.add(chat);
            AppLogger.w('⚠️ Producto no encontrado: ${chat.productId}');
          }
        } catch (e) {
          updatedChats.add(chat);
          AppLogger.e('Error cargando chat ${chat.id}', e);
        }
      }
      
      _chats = updatedChats;
      AppLogger.d('🎯 Información detallada cargada para ${_chats.length} chats');
      
    } catch (e) {
      AppLogger.e('Error en _loadChatsDetailedInfo', e);
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    try {
      AppLogger.d('📨 Cargando mensajes para chat: $chatId');
      
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at');

      _messages[chatId] = (response as List)
          .map((data) => Message.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Mensajes cargados para chat $chatId: ${_messages[chatId]?.length ?? 0}');
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar mensajes: $e';
      AppLogger.e('Error cargando mensajes', e);
      rethrow;
    }
  }

  Stream<List<Message>> getMessageStream(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((data) => (data as List)
        .map((messageData) => Message.fromMap(Map<String, dynamic>.from(messageData)))
        .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      AppLogger.d('✉️ Enviando mensaje en chat: $chatId');
      
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'text': text.trim(),
        'from_id': fromId,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
      });

      // ✅ Actualizar updated_at del chat
      try {
        await _supabase
            .from('chats')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', chatId);
      } catch (e) {
        AppLogger.w('⚠️ No se pudo actualizar updated_at: $e');
      }

      AppLogger.d('✅ Mensaje enviado en chat $chatId');
      
    } catch (e) {
      _error = 'Error al enviar mensaje: $e';
      AppLogger.e('Error enviando mensaje', e);
      rethrow;
    }
  }

  // ✅ NUEVO: Enviar mensaje de sistema (para acuerdos)
  Future<void> sendSystemMessage({
    required String chatId,
    required String text,
  }) async {
    try {
      AppLogger.d('🤖 Enviando mensaje de sistema en chat: $chatId');
      
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'text': text,
        'from_id': 'system', // ID especial para mensajes del sistema
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'is_system': true,
      });

      AppLogger.d('✅ Mensaje de sistema enviado en chat $chatId');
      
    } catch (e) {
      AppLogger.e('Error enviando mensaje de sistema', e);
      rethrow;
    }
  }

  Future<String> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      AppLogger.d('💬 Buscando o creando chat para producto: $productId');
      
      // Buscar chat existente
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

      // Crear nuevo chat
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
      
      // Enviar mensaje de bienvenida
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

  // ✅ NUEVO: Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read': true})
          .eq('chat_id', chatId)
          .neq('from_id', currentUserId)
          .eq('read', false);
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos', e);
    }
  }

  // ✅ CORREGIDO: Obtener cantidad de mensajes no leídos
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      // Obtener todos los mensajes no leídos de los chats del usuario
      int totalUnread = 0;
      
      for (final chat in _chats) {
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chat.id)
            .eq('read', false)
            .neq('from_id', userId);
           
        totalUnread += response.length;
      }
      
      return totalUnread;
    } catch (e) {
      AppLogger.e('Error obteniendo mensajes no leídos', e);
      return 0;
    }
  }

  // ✅ NUEVO: Método alternativo para contar mensajes no leídos por chat
  Future<Map<String, int>> getUnreadMessagesByChat(String userId) async {
    try {
      final Map<String, int> unreadByChat = {};
      
      for (final chat in _chats) {
        final response = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chat.id)
            .eq('read', false)
            .neq('from_id', userId);
           
        unreadByChat[chat.id] = response.length;
      }
      
      return unreadByChat;
    } catch (e) {
      AppLogger.e('Error obteniendo mensajes no leídos por chat', e);
      return {};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshChats(String userId) async {
    await loadUserChats(userId);
  }
}