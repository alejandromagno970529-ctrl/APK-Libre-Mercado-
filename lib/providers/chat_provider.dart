import 'package:flutter/foundation.dart';
import 'package:libre_mercado_final__app/models/chat_model.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/services/chat_service.dart';
import 'package:libre_mercado_final__app/services/notification_service.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatProvider with ChangeNotifier {
  final Map<String, Chat> _chats = {};
  final Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _error;
  late final ChatService _chatService;
  late final NotificationService _notificationService;

  // ✅ CORREGIDO: Constructor mejorado
  ChatProvider({
    required ChatService chatService,
    required NotificationService notificationService,
  })  : _chatService = chatService,
        _notificationService = notificationService;

  Map<String, Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Chat> get chatsList => _chats.values.toList();
  List<Message> getMessages(String chatId) => _messages[chatId] ?? [];

  // ✅ NUEVO: Inicialización del servicio
  void initializeServices(ChatService chatService, NotificationService notificationService) {
    _chatService = chatService;
    _notificationService = notificationService;
  }

  // ✅ CORREGIDO: getOrCreateChat con manejo mejorado
  Future<String> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
    required String buyerName,
    required String productTitle,
  }) async {
    try {
      _setLoading(true);
      
      AppLogger.d('🔄 Buscando o creando chat para producto: $productId');
      AppLogger.d('👤 Comprador: $buyerId, Vendedor: $sellerId');

      // 1. Buscar chat existente
      final existingChats = await _chatService.getUserChats(buyerId);
      final existingChat = existingChats.firstWhere(
        (chat) => chat.productId == productId && 
                  ((chat.buyerId == buyerId && chat.sellerId == sellerId) ||
                   (chat.buyerId == sellerId && chat.sellerId == buyerId)),
        orElse: () => Chat(
          id: '',
          productId: '',
          buyerId: '',
          sellerId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          unreadCount: 0,
        ),
      );

      if (existingChat.id.isNotEmpty) {
        AppLogger.d('✅ Chat existente encontrado: ${existingChat.id}');
        _setLoading(false);
        return existingChat.id;
      }

      // 2. Crear nuevo chat
      AppLogger.d('📝 Creando nuevo chat en Supabase...');
      final newChat = await _chatService.createChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
      );

      // 3. Actualizar estado local
      _chats[newChat.id] = newChat;
      _messages[newChat.id] = [];
      
      // 4. Enviar notificación al vendedor
      try {
        await _notificationService.sendNewChatNotification(
          toUserId: sellerId,
          fromUserName: buyerName,
          productTitle: productTitle,
          chatId: newChat.id,
        );
        AppLogger.d('✅ Notificación enviada al vendedor');
      } catch (e) {
        AppLogger.e('⚠️ Error enviando notificación, pero continuando...', e);
      }

      notifyListeners();
      _setLoading(false);

      AppLogger.d('🎉 Chat creado exitosamente: ${newChat.id}');
      return newChat.id;

    } catch (e) {
      _setLoading(false);
      _setError('Error al crear chat: $e');
      AppLogger.e('❌ Error en getOrCreateChat: $e');
      rethrow;
    }
  }

  // ✅ CORREGIDO: Cargar chats del usuario
  Future<void> loadUserChats(String userId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      AppLogger.d('🔄 Cargando chats para usuario: $userId');
      
      final userChats = await _chatService.getUserChats(userId);
      
      // Actualizar estado local
      _chats.clear();
      for (final chat in userChats) {
        _chats[chat.id] = chat;
        
        // Suscribirse a mensajes en tiempo real
        _subscribeToChatMessages(chat.id);
      }
      
      AppLogger.d('✅ ${userChats.length} chats cargados');
      notifyListeners();
      
    } catch (e) {
      _setLoading(false);
      _setError('Error cargando chats: $e');
      AppLogger.e('❌ Error cargando chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ CORREGIDO: Cargar mensajes
  Future<void> loadChatMessages(String chatId) async {
    try {
      _setLoading(true);
      
      final messages = await _chatService.loadMessages(chatId);
      _messages[chatId] = messages;
      
      _setLoading(false);
      notifyListeners();
      
      AppLogger.d('✅ ${messages.length} mensajes cargados para chat: $chatId');
    } catch (e) {
      _setLoading(false);
      _setError('Error cargando mensajes: $e');
      AppLogger.e('❌ Error cargando mensajes para chat $chatId: $e');
    }
  }

  // ✅ CORREGIDO: Enviar mensaje
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
    required String fromName,
    required String productTitle,
    required String toUserId,
  }) async {
    try {
      if (text.trim().isEmpty) {
        throw Exception('El mensaje no puede estar vacío');
      }

      AppLogger.d('📤 Enviando mensaje: "$text" a chat: $chatId');

      // 1. Enviar mensaje a través del servicio
      final message = await _chatService.sendMessage(
        chatId: chatId,
        text: text,
        fromId: fromId,
      );

      // 2. Actualizar estado local
      if (_messages[chatId] == null) {
        _messages[chatId] = [];
      }
      
      _messages[chatId]!.insert(0, message);
      
      // 3. Actualizar último mensaje en el chat
      if (_chats.containsKey(chatId)) {
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: text,
          updatedAt: DateTime.now(),
        );
      }
      
      // 4. Enviar notificación al destinatario
      try {
        await _notificationService.sendChatNotification(
          toUserId: toUserId,
          fromUserName: fromName,
          productTitle: productTitle,
          messageText: text,
          chatId: chatId,
        );
      } catch (e) {
        AppLogger.e('⚠️ Error enviando notificación de mensaje', e);
      }

      notifyListeners();
      
      AppLogger.d('✅ Mensaje enviado exitosamente: $text');

    } catch (e) {
      _setError('Error enviando mensaje: $e');
      AppLogger.e('❌ Error enviando mensaje: $e');
      rethrow;
    }
  }

  // ✅ CORREGIDO: Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, userId);
      
      // Actualizar estado local
      final messages = _messages[chatId];
      if (messages != null) {
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].fromId != userId && !messages[i].read) {
            _messages[chatId]![i] = messages[i].copyWith(read: true);
          }
        }
        notifyListeners();
      }
      
      AppLogger.d('✅ Mensajes marcados como leídos en chat: $chatId');
    } catch (e) {
      AppLogger.e('❌ Error marcando mensajes como leídos: $e');
    }
  }

  // ✅ CORREGIDO: Suscribirse a mensajes en tiempo real (método privado)
  void _subscribeToChatMessages(String chatId) {
    try {
      _chatService.getMessagesStream(chatId).listen((messages) {
        _messages[chatId] = messages;
        notifyListeners();
        AppLogger.d('🔄 Mensajes actualizados en tiempo real: ${messages.length}');
      }, onError: (error) {
        _setError('Error en tiempo real: $error');
        AppLogger.e('❌ Error en stream de mensajes: $error');
      });
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a mensajes: $e');
    }
  }

  // ✅ NUEVO: Cerrar suscripciones
  void disposeChat(String chatId) {
    try {
      _chatService.disposeChatStream(chatId);
    } catch (e) {
      AppLogger.e('❌ Error cerrando suscripción: $e');
    }
  }

  // ✅ NUEVO: Limpiar todos los recursos
  void disposeAll() {
    try {
      for (final chatId in _chats.keys) {
        disposeChat(chatId);
      }
      _chats.clear();
      _messages.clear();
    } catch (e) {
      AppLogger.e('❌ Error limpiando recursos: $e');
    }
  }

  // ✅ CORREGIDO: Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      AppLogger.e('❌ ChatProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ NUEVO: Método para debugging
  void debugState() {
    AppLogger.d('''
🔍 CHAT PROVIDER STATE:
   - Chats: ${_chats.length}
   - Loading: $_isLoading
   - Error: $_error
   - Messages: ${_messages.length} chats con mensajes
''');
  }
}