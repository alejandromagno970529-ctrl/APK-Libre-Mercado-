// lib/providers/chat_provider.dart - VERSIÓN COMPLETA CORREGIDA
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:libre_mercado_final_app/models/chat_model.dart';
import 'package:libre_mercado_final_app/models/message_model.dart';
import 'package:libre_mercado_final_app/services/chat_service.dart';
import 'package:libre_mercado_final_app/services/notification_service.dart';
import 'package:libre_mercado_final_app/services/file_upload_service.dart';
import 'package:libre_mercado_final_app/services/image_upload_service.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class ChatProvider with ChangeNotifier {
  final Map<String, Chat> _chats = {};
  final Map<String, List<Message>> _messages = {};
  final Map<String, StreamSubscription<List<Message>>> _messageSubscriptions = {};
  bool _isLoading = false;
  String? _error;
  late final ChatService _chatService;
  late final NotificationService _notificationService;
  late final FileUploadService _fileUploadService;
  late final ImageUploadService _imageUploadService;

  ChatProvider({
    required ChatService chatService,
    required NotificationService notificationService,
    required FileUploadService fileUploadService,
    required ImageUploadService imageUploadService,
  })  : _chatService = chatService,
        _notificationService = notificationService,
        _fileUploadService = fileUploadService,
        _imageUploadService = imageUploadService;

  Map<String, Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Chat> get chatsList => _chats.values.toList();
  List<Message> getMessages(String chatId) => _messages[chatId] ?? [];

  // ✅ NUEVO: Inicializar RLS al crear el provider
  Future<void> initializeRLS() async {
    try {
      AppLogger.d('🔧 Inicializando configuración RLS...');
      await _notificationService.setupNotificationRLS();
      AppLogger.d('✅ Configuración RLS inicializada');
    } catch (e) {
      AppLogger.e('⚠️ Error inicializando RLS (no crítico): $e');
    }
  }

  Future<void> loadUserChats(String userId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      AppLogger.d('🔄 Cargando chats para usuario: $userId');
      
      final userChats = await _chatService.getUserChats(userId);
      
      _chats.clear();
      
      for (final subscription in _messageSubscriptions.values) {
        await subscription.cancel();
      }
      _messageSubscriptions.clear();
      
      for (final chat in userChats) {
        _chats[chat.id] = chat;
        _subscribeToChatMessages(chat.id);
      }
      
      AppLogger.d('✅ ${userChats.length} chats cargados exitosamente');
      notifyListeners();
      
    } catch (e) {
      _setError('Error cargando chats: $e');
      AppLogger.e('❌ Error cargando chats: $e', e);
    } finally {
      _setLoading(false);
    }
  }

  // ✅ MÉTODO MEJORADO: sendFileMessage con mejor manejo de RLS
  Future<void> sendFileMessage({
    required String chatId,
    required String fromId,
    required String fromName,
    required String productTitle,
    required String toUserId,
    required File file,
    required String fileName,
  }) async {
    try {
      AppLogger.d('📤 INICIANDO ENVÍO DE ARCHIVO: $fileName a chat: $chatId');

      // ✅ DETECTAR TIPO DE ARCHIVO
      final isImage = _fileUploadService.isImageFile(fileName);
      AppLogger.d('🔍 Tipo detectado: ${isImage ? 'IMAGEN' : 'ARCHIVO'}');

      String fileUrl;
      if (isImage) {
        AppLogger.d('🖼️ Usando ImageUploadService para imagen...');
        fileUrl = await _imageUploadService.uploadChatImage(file, fromId);
        AppLogger.d('✅ URL de imagen obtenida: $fileUrl');
      } else {
        AppLogger.d('📎 Usando FileUploadService para archivo...');
        fileUrl = await _fileUploadService.uploadFile(file, fromId);
        AppLogger.d('✅ URL de archivo obtenida: $fileUrl');
      }

      // ✅ VERIFICACIÓN DE URL
      if (fileUrl.isEmpty) {
        throw Exception('La URL del archivo está vacía después de la subida');
      }

      final fileSize = _fileUploadService.formatFileSize(await file.length());
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      AppLogger.d('📊 Metadatos - Tamaño: $fileSize, Extensión: $extension, MIME: $mimeType');

      // ✅ ENVIAR MENSAJE A BASE DE DATOS
      AppLogger.d('💾 Insertando mensaje en base de datos...');
      final message = await _chatService.sendFileMessage(
        chatId: chatId,
        fromId: fromId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        isImage: isImage,
      );

      AppLogger.d('✅ Mensaje insertado - ID: ${message.id}, Tipo: ${message.type}');

      // ✅ ACTUALIZAR ESTADO LOCAL
      if (_messages[chatId] == null) {
        _messages[chatId] = [];
      }

      // ✅ ELIMINAR DUPLICADOS Y AGREGAR NUEVO MENSAJE
      _messages[chatId]!.removeWhere((m) => m.id == message.id);
      _messages[chatId]!.insert(0, message);
      
      AppLogger.d('📝 Estado local actualizado - Total mensajes: ${_messages[chatId]!.length}');

      // ✅ ACTUALIZAR INFORMACIÓN DEL CHAT
      if (_chats.containsKey(chatId)) {
        final fileType = isImage ? 'Imagen' : 'Archivo';
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: '$fileType: $fileName',
          updatedAt: DateTime.now(),
        );
        AppLogger.d('💬 Chat actualizado - Último mensaje: ${_chats[chatId]!.lastMessage}');
      }

      // ✅ MEJORA: Manejo más robusto de notificaciones con reintentos
      await _sendNotificationWithRetry(
        toUserId: toUserId,
        fromUserName: fromName,
        productTitle: productTitle,
        messageText: '${isImage ? '🖼️ Imagen' : '📎 Archivo'}: $fileName',
        chatId: chatId,
      );

      // ✅ NOTIFICAR A LOS LISTENERS
      notifyListeners();
      AppLogger.d('🎉 ARCHIVO ENVIADO EXITOSAMENTE: $fileName');

    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO enviando archivo: $e', e);
      _setError('Error enviando archivo: $e');
      rethrow;
    }
  }

  // ✅ NUEVO MÉTODO: Envío de notificación con reintentos
  Future<void> _sendNotificationWithRetry({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
    int maxRetries = 2,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.d('🔔 Intentando notificación (intento $attempt/$maxRetries)...');
        
        await _notificationService.sendChatNotification(
          toUserId: toUserId,
          fromUserName: fromUserName,
          productTitle: productTitle,
          messageText: messageText,
          chatId: chatId,
        );
        
        AppLogger.d('✅ Notificación enviada exitosamente en intento $attempt');
        return; // Éxito, salir del bucle
      } catch (e) {
        AppLogger.e('⚠️ Error en notificación (intento $attempt): $e');
        
        // Si es error de RLS, intentar configurar
        if (e.toString().contains('row-level security policy')) {
          AppLogger.w('🔄 Error RLS detectado, intentando configurar...');
          try {
            await _notificationService.setupNotificationRLS();
            AppLogger.d('✅ Configuración RLS actualizada');
          } catch (rlsError) {
            AppLogger.e('❌ Error configurando RLS: $rlsError');
          }
        }
        
        // Si es el último intento, lanzar error
        if (attempt == maxRetries) {
          AppLogger.e('❌ Fallaron todos los intentos de notificación');
          // ignore: use_rethrow_when_possible
          throw e;
        }
        
        // Esperar antes del siguiente intento
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'bmp': return 'image/bmp';
      case 'webp': return 'image/webp';
      case 'mp3': return 'audio/mpeg';
      case 'm4a': return 'audio/mp4';
      case 'wav': return 'audio/wav';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      default: return 'application/octet-stream';
    }
  }

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

      AppLogger.d('📝 Creando nuevo chat en Supabase...');
      final newChat = await _chatService.createChat(
        productId: productId,
        buyerId: buyerId,
        sellerId: sellerId,
      );

      _chats[newChat.id] = newChat;
      _messages[newChat.id] = [];
      
      // ✅ MEJORA: Notificación con manejo de errores mejorado
      try {
        await _sendNotificationWithRetry(
          toUserId: sellerId,
          fromUserName: buyerName,
          productTitle: productTitle,
          messageText: '$buyerName quiere contactarte sobre "$productTitle"',
          chatId: newChat.id,
        );
        AppLogger.d('✅ Notificación enviada al vendedor');
      } catch (e) {
        AppLogger.e('⚠️ Error enviando notificación de nuevo chat, pero continuando...: $e', e);
      }

      notifyListeners();
      _setLoading(false);

      AppLogger.d('🎉 Chat creado exitosamente: ${newChat.id}');
      return newChat.id;

    } catch (e) {
      _setLoading(false);
      _setError('Error al crear chat: $e');
      AppLogger.e('❌ Error en getOrCreateChat: $e', e);
      rethrow;
    }
  }

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
      AppLogger.e('❌ Error cargando mensajes para chat $chatId: $e', e);
    }
  }

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

      final message = await _chatService.sendMessage(
        chatId: chatId,
        text: text,
        fromId: fromId,
      );

      if (_messages[chatId] == null) {
        _messages[chatId] = [];
      }
      
      if (!_messages[chatId]!.any((m) => m.id == message.id)) {
        _messages[chatId]!.insert(0, message);
      }
      
      if (_chats.containsKey(chatId)) {
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: text,
          updatedAt: DateTime.now(),
        );
      }
      
      // ✅ MEJORA: Usar el nuevo método con reintentos
      try {
        await _sendNotificationWithRetry(
          toUserId: toUserId,
          fromUserName: fromName,
          productTitle: productTitle,
          messageText: text,
          chatId: chatId,
        );
        AppLogger.d('✅ Notificación enviada');
      } catch (e) {
        AppLogger.e('⚠️ Error enviando notificación de mensaje: $e', e);
      }

      notifyListeners();
      
      AppLogger.d('✅ Mensaje enviado exitosamente: $text');

    } catch (e) {
      _setError('Error enviando mensaje: $e');
      AppLogger.e('❌ Error enviando mensaje: $e', e);
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, userId);
      
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
      AppLogger.e('❌ Error marcando mensajes como leídos: $e', e);
    }
  }

  void _subscribeToChatMessages(String chatId) {
    try {
      _messageSubscriptions[chatId]?.cancel();
      
      final subscription = _chatService.getMessagesStream(chatId).listen(
        (messages) {
          _messages[chatId] = messages;
          notifyListeners();
          AppLogger.d('🔄 Mensajes actualizados en tiempo real: ${messages.length}');
        },
        onError: (error) {
          _setError('Error en tiempo real: $error');
          AppLogger.e('❌ Error en stream de mensajes: $error', error);
        },
      );
      
      _messageSubscriptions[chatId] = subscription;
      
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a mensajes: $e', e);
    }
  }

  void disposeChat(String chatId) {
    try {
      _messageSubscriptions[chatId]?.cancel();
      _messageSubscriptions.remove(chatId);
      _chatService.disposeChatStream(chatId);
    } catch (e) {
      AppLogger.e('❌ Error cerrando suscripción: $e', e);
    }
  }

  void disposeAll() {
    try {
      for (final subscription in _messageSubscriptions.values) {
        subscription.cancel();
      }
      _messageSubscriptions.clear();
      
      for (final chatId in _chats.keys) {
        _chatService.disposeChatStream(chatId);
      }
      _chats.clear();
      _messages.clear();
    } catch (e) {
      AppLogger.e('❌ Error limpiando recursos: $e', e);
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar chat completamente con limpieza
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Provider: Eliminando chat $chatId');
      
      // Obtener mensajes para limpiar archivos
      final messages = _messages[chatId] ?? [];
      for (final message in messages) {
        if ((message.isFileMessage || message.isImageMessage) && message.fileUrl != null) {
          try {
            await _chatService.deleteFileFromStorage(message.fileUrl!);
          } catch (e) {
            AppLogger.e('⚠️ Error limpiando archivo del mensaje ${message.id}: $e');
          }
        }
      }
      
      // Eliminar de Supabase
      await _chatService.deleteChat(chatId);
      
      // Eliminar localmente
      _chats.remove(chatId);
      _messages.remove(chatId);
      disposeChat(chatId);
      
      notifyListeners();
      AppLogger.d('✅ Chat eliminado completamente');
    } catch (e) {
      AppLogger.e('❌ Error eliminando chat: $e', e);
      _setError('Error eliminando chat: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Limpiar mensajes del chat con limpieza de archivos
  Future<void> clearChatMessages(String chatId) async {
    try {
      AppLogger.d('🧹 Provider: Limpiando mensajes del chat $chatId');
      
      // Limpiar archivos primero
      final messages = _messages[chatId] ?? [];
      for (final message in messages) {
        if ((message.isFileMessage || message.isImageMessage) && message.fileUrl != null) {
          try {
            await _chatService.deleteFileFromStorage(message.fileUrl!);
          } catch (e) {
            AppLogger.e('⚠️ Error limpiando archivo del mensaje ${message.id}: $e');
          }
        }
      }
      
      // Limpiar en Supabase
      await _chatService.clearChatMessages(chatId);
      
      // Limpiar localmente
      _messages[chatId]?.clear();
      
      // Actualizar información del chat
      if (_chats.containsKey(chatId)) {
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: null,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
      AppLogger.d('✅ Mensajes del chat limpiados');
    } catch (e) {
      AppLogger.e('❌ Error limpiando mensajes: $e', e);
      _setError('Error limpiando mensajes: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar mensaje individual con limpieza
  Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Provider: Eliminando mensaje $messageId del chat $chatId');
      
      // Obtener información del mensaje antes de eliminarlo
      // ignore: unused_local_variable
      final message = _messages[chatId]?.firstWhere((m) => m.id == messageId);
      
      // Eliminar usando el servicio mejorado
      await _chatService.deleteMessage(
        messageId, 
        deleteForEveryone: deleteForEveryone
      );
      
      // Actualizar estado local
      if (_messages.containsKey(chatId)) {
        _messages[chatId]!.removeWhere((m) => m.id == messageId);
      }
      
      // Actualizar último mensaje del chat si es necesario
      if (_chats.containsKey(chatId) && _messages[chatId]?.isNotEmpty == true) {
        final lastMessage = _messages[chatId]!.last;
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: lastMessage.text,
          updatedAt: DateTime.now(),
        );
      } else if (_chats.containsKey(chatId)) {
        _chats[chatId] = _chats[chatId]!.copyWith(
          lastMessage: null,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
      AppLogger.d('✅ Mensaje eliminado del provider');
    } catch (e) {
      AppLogger.e('❌ Error eliminando mensaje en provider: $e', e);
      _setError('Error eliminando mensaje: $e');
      rethrow;
    }
  }

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

  Future<void> diagnoseImageUpload() async {
    try {
      AppLogger.d('🔍 INICIANDO DIAGNÓSTICO COMPLETO DE UPLOAD...');

      AppLogger.d('📋 DIAGNÓSTICO IMAGE_UPLOAD_SERVICE:');
      await _imageUploadService.diagnoseBuckets();

      AppLogger.d('📋 DIAGNÓSTICO FILE_UPLOAD_SERVICE:');
      await _fileUploadService.diagnoseFileBuckets();

      AppLogger.d('✅ DIAGNÓSTICO COMPLETADO');

    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico de upload: $e');
    }
  }

  void debugState() {
    AppLogger.d('''
🔍 CHAT PROVIDER STATE:
   - Chats: ${_chats.length}
   - Loading: $_isLoading
   - Error: $_error
   - Messages: ${_messages.length} chats con mensajes
   - Subscriptions: ${_messageSubscriptions.length}
''');
  }
}