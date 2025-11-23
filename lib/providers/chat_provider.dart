import 'package:flutter/foundation.dart';
import 'package:libre_mercado_final__app/models/chat_model.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';
import 'package:supabase/src/supabase_client.dart';

class ChatProvider with ChangeNotifier {
  final Map<String, Chat> _chats = {};
  final Map<String, List<Message>> _messages = {};
  bool _isLoading = false;
  String? _error;

  ChatProvider(SupabaseClient client);

  Map<String, Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Message> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  // ✅ MÉTODO AGREGADO: getOrCreateChat
  Future<String> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      _setLoading(true);
      
      // Buscar chat existente para este producto y usuarios
      final existingChats = _chats.values.where((chat) =>
          chat.productId == productId &&
          ((chat.buyerId == buyerId && chat.sellerId == sellerId) ||
           (chat.buyerId == sellerId && chat.sellerId == buyerId))).toList();

      if (existingChats.isNotEmpty) {
        _setLoading(false);
        return existingChats.first.id;
      }

      // Crear nuevo chat
      final newChatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final newChat = Chat(
        id: newChatId,
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastMessage: '',
        unreadCount: 0,
      );

      _chats[newChatId] = newChat;
      _messages[newChatId] = [];
      
      notifyListeners();
      _setLoading(false);

      return newChatId;
    } catch (e) {
      _setLoading(false);
      _setError('Error al crear chat: $e');
      AppLogger.e('Error en getOrCreateChat: $e');
      rethrow;
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    try {
      _setLoading(true);
      
      // Simular carga de mensajes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Aquí iría la lógica real para cargar mensajes de Supabase
      _messages[chatId] = [];
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Error cargando mensajes: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    try {
      final message = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        fromId: fromId,
        text: text,
        createdAt: DateTime.now(),
        read: false,
      );

      if (_messages[chatId] == null) {
        _messages[chatId] = [];
      }
      
      _messages[chatId]!.insert(0, message);
      
      // Actualizar último mensaje en el chat
      if (_chats.containsKey(chatId)) {
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: text,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Error enviando mensaje: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messages = _messages[chatId];
      if (messages != null) {
        for (final message in messages) {
          if (message.fromId != userId && !message.read) {
            // Marcar como leído
            final index = messages.indexOf(message);
            messages[index] = message.copyWith(read: true);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> getChats() async {}
}