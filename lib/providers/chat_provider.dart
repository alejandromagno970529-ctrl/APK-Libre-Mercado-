// lib/providers/chat_provider.dart - VERSIÓN COMPLETAMENTE CORREGIDA
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
  final Map<String, Set<String>> _pendingMessages = {};
  final Map<String, bool> _streamsActive = {};
  
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

  bool isMessagePending(String chatId, String messageId) {
    return _pendingMessages[chatId]?.contains(messageId) ?? false;
  }

  bool isStreamActive(String chatId) {
    return _streamsActive[chatId] ?? false;
  }

  Future<void> initializeRLS() async {
    try {
      AppLogger.d('🔧 Inicializando configuración RLS para notificaciones...');
      final basicRLSCheck = await _notificationService.checkBasicRLS();
      
      if (!basicRLSCheck) {
        AppLogger.w('⚠️ RLS no configurado - Ejecutando configuración completa...');
        final rlsResult = await _notificationService.setupNotificationRLS();
        
        if (rlsResult['success'] == true) {
          AppLogger.d('✅ Configuración RLS completada exitosamente');
        } else {
          AppLogger.e('❌ Configuración RLS falló: ${rlsResult['error']}');
        }
      } else {
        AppLogger.d('✅ Configuración RLS verificada - Todo funciona correctamente');
      }
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
      _streamsActive.clear();
      _pendingMessages.clear();
      
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

  Future<void> sendFileMessage({
    required String chatId,
    required String fromId,
    required String fromName,
    required String productTitle,
    required String toUserId,
    required File file,
    required String fileName,
  }) async {
    final tempMessageId = Message.generateTempId(fromId);
    
    if (isMessagePending(chatId, tempMessageId)) {
      AppLogger.d('⏳ Mensaje de archivo ya en proceso: $tempMessageId');
      return;
    }

    _markMessageAsPending(chatId, tempMessageId);

    try {
      AppLogger.d('📤 INICIANDO ENVÍO DE ARCHIVO: $fileName a chat: $chatId (TempID: $tempMessageId)');

      final isImage = _fileUploadService.isImageFile(fileName);
      AppLogger.d('🔍 Tipo detectado: ${isImage ? 'IMAGEN' : 'ARCHIVO'}');

      final tempMessage = _createTempFileMessage(
        chatId: chatId,
        fromId: fromId,
        fileName: fileName,
        isImage: isImage,
        tempId: tempMessageId,
      );

      _addTempMessageToState(chatId, tempMessage);

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

      if (fileUrl.isEmpty) {
        throw Exception('La URL del archivo está vacía después de la subida');
      }

      final fileSize = _fileUploadService.formatFileSize(await file.length());
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      AppLogger.d('📊 Metadatos - Tamaño: $fileSize, Extensión: $extension, MIME: $mimeType');

      _pauseStreamForOwnMessages(chatId);

      AppLogger.d('💾 Insertando mensaje real en base de datos...');
      final realMessage = await _chatService.sendFileMessage(
        chatId: chatId,
        fromId: fromId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        isImage: isImage,
        fromName: fromName,          // ✅ NUEVO
        toUserId: toUserId,          // ✅ NUEVO
        productTitle: productTitle,  // ✅ NUEVO
      );

      AppLogger.d('✅ Mensaje real insertado - ID: ${realMessage.id}, Tipo: ${realMessage.type}');

      _replaceTempWithRealMessage(chatId, tempMessageId, realMessage);

      _updateChatLastMessage(chatId, isImage ? '🖼️ Imagen' : '📎 $fileName');

      AppLogger.d('🎉 ARCHIVO ENVIADO EXITOSAMENTE: $fileName');

    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO enviando archivo: $e', e);
      _removeTempMessage(chatId, tempMessageId);
      _setError('Error enviando archivo: $e');
      rethrow;
    } finally {
      _resumeStreamForOwnMessages(chatId);
      _unmarkMessageAsPending(chatId, tempMessageId);
    }
  }

  Message _createTempFileMessage({
    required String chatId,
    required String fromId,
    required String fileName,
    required bool isImage,
    required String tempId,
  }) {
    return Message(
      id: tempId,
      chatId: chatId,
      text: isImage ? '🖼️ Subiendo imagen...' : '📎 Subiendo archivo...',
      fromId: fromId,
      createdAt: DateTime.now(),
      read: false,
      isSystem: false,
      type: isImage ? MessageType.image : MessageType.file,
      metadata: {
        'file_name': fileName,
        'is_uploading': true,
        'is_temp': true,
      },
      tempId: tempId,
    );
  }

  void _addTempMessageToState(String chatId, Message tempMessage) {
    if (_messages[chatId] == null) {
      _messages[chatId] = [];
    }
    
    if (!_messages[chatId]!.any((m) => m.id == tempMessage.id)) {
      _messages[chatId]!.insert(0, tempMessage);
      notifyListeners();
      AppLogger.d('✅ Mensaje temporal agregado: ${tempMessage.id}');
    }
  }

  void _replaceTempWithRealMessage(String chatId, String tempId, Message realMessage) {
    if (_messages[chatId] != null) {
      final index = _messages[chatId]!.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[chatId]!.removeAt(index);
        AppLogger.d('✅ Mensaje temporal removido: $tempId');
      }
      
      _messages[chatId]!.removeWhere((m) => m.id == realMessage.id);
      _messages[chatId]!.insert(0, realMessage);
      AppLogger.d('✅ Mensaje real agregado: ${realMessage.id}');
      
      notifyListeners();
    }
  }

  void _removeTempMessage(String chatId, String tempId) {
    if (_messages[chatId] != null) {
      _messages[chatId]!.removeWhere((m) => m.id == tempId);
      notifyListeners();
      AppLogger.d('✅ Mensaje temporal removido por error: $tempId');
    }
  }

  void _pauseStreamForOwnMessages(String chatId) {
    final pendingCount = _pendingMessages[chatId]?.length ?? 0;
    if (pendingCount == 1) {
      _streamsActive[chatId] = false;
      AppLogger.d('🔇 Stream pausado temporalmente para: $chatId');
    }
  }

  void _resumeStreamForOwnMessages(String chatId) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_streamsActive.containsKey(chatId)) {
        _streamsActive[chatId] = true;
        AppLogger.d('🔊 Stream reactivado para: $chatId');
        
        if (_messages.containsKey(chatId)) {
          notifyListeners();
        }
      }
    });
  }

  void _markMessageAsPending(String chatId, String messageId) {
    if (!_pendingMessages.containsKey(chatId)) {
      _pendingMessages[chatId] = {};
    }
    _pendingMessages[chatId]!.add(messageId);
  }

  void _unmarkMessageAsPending(String chatId, String messageId) {
    _pendingMessages[chatId]?.remove(messageId);
  }

  // ✅ ✅ MÉTODO CORREGIDO: sendMessage con todos los parámetros necesarios
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
    required String fromName,
    required String productTitle,
    required String toUserId,
  }) async {
    final tempMessageId = Message.generateTempId(fromId);
    
    if (isMessagePending(chatId, tempMessageId)) {
      AppLogger.d('⏳ Mensaje de texto ya en proceso: $tempMessageId');
      return;
    }

    _markMessageAsPending(chatId, tempMessageId);

    try {
      if (text.trim().isEmpty) {
        throw Exception('El mensaje no puede estar vacío');
      }

      AppLogger.d('📤 Enviando mensaje: "$text" a chat: $chatId (TempID: $tempMessageId)');

      final tempMessage = Message(
        id: tempMessageId,
        chatId: chatId,
        text: text,
        fromId: fromId,
        createdAt: DateTime.now(),
        read: false,
        isSystem: false,
        type: MessageType.text,
        tempId: tempMessageId,
      );

      _addTempMessageToState(chatId, tempMessage);

      _pauseStreamForOwnMessages(chatId);

      // ✅ ✅ LLAMAR AL CHAT SERVICE CON TODOS LOS PARÁMETROS NECESARIOS
      final realMessage = await _chatService.sendMessage(
        chatId: chatId,
        text: text,
        fromId: fromId,
        fromName: fromName,          // ✅ PASAR fromName
        toUserId: toUserId,          // ✅ PASAR toUserId
        productTitle: productTitle,  // ✅ PASAR productTitle
      );

      _replaceTempWithRealMessage(chatId, tempMessageId, realMessage);

      _updateChatLastMessage(chatId, text);

      AppLogger.d('✅ Mensaje enviado exitosamente: $text');

    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje: $e', e);
      _removeTempMessage(chatId, tempMessageId);
      _setError('Error enviando mensaje: $e');
      rethrow;
    } finally {
      _resumeStreamForOwnMessages(chatId);
      _unmarkMessageAsPending(chatId, tempMessageId);
    }
  }

  void _subscribeToChatMessages(String chatId) {
    try {
      _messageSubscriptions[chatId]?.cancel();
      
      _streamsActive[chatId] = true;
      _pendingMessages[chatId] = {};

      final subscription = _chatService.getMessagesStream(chatId).listen(
        (messages) {
          if (!isStreamActive(chatId)) {
            AppLogger.d('🔇 Stream ignorado (pausado) para: $chatId');
            return;
          }

          try {
            final pendingIds = _pendingMessages[chatId] ?? {};
            final filteredMessages = messages.where((message) {
              return !pendingIds.contains(message.tempId);
            }).toList();

            _messages[chatId] = filteredMessages;
            notifyListeners();
            
            AppLogger.d('🔄 Mensajes actualizados desde stream: ${filteredMessages.length}');
            
          } catch (e) {
            AppLogger.e('❌ Error procesando stream: $e', e);
          }
        },
        onError: (error) {
          _setError('Error en tiempo real: $error');
          AppLogger.e('❌ Error en stream de mensajes: $error', error);
        },
      );
      
      _messageSubscriptions[chatId] = subscription;
      AppLogger.d('✅ Suscripción activa para chat: $chatId');
      
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a mensajes: $e', e);
    }
  }

  Future<void> loadChatMessages(String chatId) async {
    try {
      _setLoading(true);
      
      final messages = await _chatService.loadMessages(chatId);
      
      final pendingIds = _pendingMessages[chatId] ?? {};
      final filteredMessages = messages.where((message) {
        return !pendingIds.contains(message.id) && 
               !pendingIds.contains(message.tempId);
      }).toList();
      
      _messages[chatId] = filteredMessages;
      
      _setLoading(false);
      notifyListeners();
      
      AppLogger.d('✅ ${filteredMessages.length} mensajes cargados (filtrados de ${messages.length}) para chat: $chatId');
    } catch (e) {
      _setLoading(false);
      _setError('Error cargando mensajes: $e');
      AppLogger.e('❌ Error cargando mensajes para chat $chatId: $e', e);
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      AppLogger.d('👀 Marcando mensajes como leídos para chat: $chatId');
      
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
      
      try {
        await _notificationService.sendNewChatNotification(
          toUserId: sellerId,
          fromUserName: buyerName,
          productTitle: productTitle,
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

  void _updateChatLastMessage(String chatId, String lastMessage) {
    if (_chats.containsKey(chatId)) {
      _chats[chatId] = _chats[chatId]!.copyWith(
        lastMessage: lastMessage.length > 30 
            ? '${lastMessage.substring(0, 30)}...' 
            : lastMessage,
        updatedAt: DateTime.now(),
      );
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

  void disposeChat(String chatId) {
    try {
      _messageSubscriptions[chatId]?.cancel();
      _messageSubscriptions.remove(chatId);
      _streamsActive.remove(chatId);
      _pendingMessages.remove(chatId);
      _chatService.disposeChatStream(chatId);
      AppLogger.d('✅ Recursos liberados para chat: $chatId');
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
      _streamsActive.clear();
      _pendingMessages.clear();
      
      for (final chatId in _chats.keys) {
        _chatService.disposeChatStream(chatId);
      }
      _chats.clear();
      _messages.clear();
      
      AppLogger.d('✅ Todos los recursos de ChatProvider liberados');
    } catch (e) {
      AppLogger.e('❌ Error limpiando recursos: $e', e);
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Provider: Eliminando chat $chatId');
      
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
      
      await _chatService.deleteChat(chatId);
      
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

  Future<void> clearChatMessages(String chatId) async {
    try {
      AppLogger.d('🧹 Provider: Limpiando mensajes del chat $chatId');
      
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
      
      await _chatService.clearChatMessages(chatId);
      
      _messages[chatId]?.clear();
      
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

  Future<void> deleteMessage(String chatId, String messageId, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Provider: Eliminando mensaje $messageId del chat $chatId');
      
      await _chatService.deleteMessage(messageId, deleteForEveryone: deleteForEveryone);
      
      if (_messages.containsKey(chatId)) {
        _messages[chatId]!.removeWhere((m) => m.id == messageId);
        _updateChatLastMessage(chatId, _messages[chatId]?.isNotEmpty == true ? _messages[chatId]!.last.text : '');
        notifyListeners();
      }
      
      AppLogger.d('✅ Mensaje eliminado y estado local actualizado');
    } catch (e) {
      AppLogger.e('❌ Error eliminando mensaje en provider: $e', e);
      _setError('Error eliminando mensaje: $e');
      rethrow;
    }
  }

  Future<void> forceSyncChat(String chatId) async {
    try {
      AppLogger.d('🔄 Forzando sincronización del chat: $chatId');
      
      await loadChatMessages(chatId);
      
      final updatedChat = await _chatService.getChatById(chatId);
      if (updatedChat != null) {
        _chats[chatId] = updatedChat;
      }
      
      notifyListeners();
      
      AppLogger.d('✅ Sincronización forzada completada para: $chatId');
    } catch (e) {
      AppLogger.e('❌ Error en sincronización forzada: $e', e);
    }
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

  Future<void> diagnoseNotificationIssues() async {
    try {
      AppLogger.d('🩺 INICIANDO DIAGNÓSTICO DE NOTIFICACIONES...');
      final result = await _notificationService.diagnoseNotificationIssues();
      
      if (result['success'] == true) {
        AppLogger.d('✅ DIAGNÓSTICO NOTIFICACIONES: TODO CORRECTO');
      } else {
        AppLogger.e('❌ DIAGNÓSTICO NOTIFICACIONES: PROBLEMAS DETECTADOS - ${result['error']}');
      }
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico de notificaciones: $e');
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
   - Active Streams: ${_streamsActive.length}
   - Pending Messages: ${_pendingMessages.length}
''');
  }
}