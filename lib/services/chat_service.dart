// lib/services/chat_service.dart - VERSIÓN COMPLETA CORREGIDA CON LIMPIEZA AUTOMÁTICA
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/logger.dart';

class ChatService {
  final SupabaseClient _supabase;

  ChatService(this._supabase);

  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  // ✅ MÉTODO CORREGIDO: Obtener chats usando imagen_url en lugar de image_url
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      AppLogger.d('🔄 Cargando chats para usuario: $userId');
      
      final response = await _supabase
          .from('chats')
          .select('''
            *,
            products:product_id(titulo, precio, imagen_url, disponible, moneda),
            buyer:buyer_id(username, avatar_url, email),
            seller:seller_id(username, avatar_url, email)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('updated_at', ascending: false);

      AppLogger.d('✅ Consulta de chats exitosa, procesando ${response.length} chats');

      final List<Chat> chats = [];
      for (var chatData in response) {
        try {
          final chat = _processChatData(chatData, userId);
          if (chat != null) {
            chats.add(chat);
          }
        } catch (e) {
          AppLogger.e('❌ Error procesando chat individual: $e', e);
        }
      }

      AppLogger.d('🎉 ${chats.length} chats procesados exitosamente');
      return chats;

    } catch (e) {
      AppLogger.e('❌ ERROR obteniendo chats: $e', e);
      rethrow;
    }
  }

  // ✅ PROCESAR DATOS DEL CHAT - CORREGIDO: usar imagen_url
  Chat? _processChatData(Map<String, dynamic> chatData, String userId) {
    try {
      final buyer = chatData['buyer'] as Map<String, dynamic>?;
      final seller = chatData['seller'] as Map<String, dynamic>?;
      final products = chatData['products'] as Map<String, dynamic>?;

      // Determinar información del otro usuario
      String? otherUserName;
      String? otherUserAvatar;

      if (userId == chatData['buyer_id']) {
        otherUserName = _extractUserName(seller);
        otherUserAvatar = seller?['avatar_url'] as String?;
      } else {
        otherUserName = _extractUserName(buyer);
        otherUserAvatar = buyer?['avatar_url'] as String?;
      }

      // Extraer información del producto - CORREGIDO: usar imagen_url
      final productInfo = _extractProductInfo(products);

      return Chat(
        id: chatData['id'] as String,
        productId: chatData['product_id'] as String,
        buyerId: chatData['buyer_id'] as String,
        sellerId: chatData['seller_id'] as String,
        createdAt: DateTime.parse(chatData['created_at']),
        updatedAt: DateTime.parse(chatData['updated_at']),
        productTitle: productInfo['title'],
        productImage: productInfo['image'],
        productPrice: productInfo['price'],
        productCurrency: productInfo['currency'],
        productAvailable: productInfo['available'],
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
        unreadCount: 0,
      );
    } catch (e) {
      AppLogger.e('❌ Error en _processChatData: $e');
      return null;
    }
  }

  // ✅ EXTRAER NOMBRE DE USUARIO
  String _extractUserName(Map<String, dynamic>? userData) {
    if (userData == null) return 'Usuario';
    
    return userData['username'] as String? ?? 
           userData['email'] as String? ?? 
           'Usuario';
  }

  // ✅ EXTRAER INFORMACIÓN DEL PRODUCTO - CORREGIDO: usar imagen_url
  Map<String, dynamic> _extractProductInfo(Map<String, dynamic>? products) {
    if (products == null) {
      return {
        'title': null,
        'price': null,
        'image': null,
        'currency': null,
        'available': true,
      };
    }

    // Título
    String? title = products['titulo'] as String?;

    // Precio
    double? price;
    if (products['precio'] != null) {
      price = (products['precio'] as num).toDouble();
    }

    // ✅ CORREGIDO: usar imagen_url en lugar de image_url
    String? image = products['imagen_url'] as String?;

    // Moneda
    String? currency = products['moneda'] as String?;

    // Disponible
    bool available = products['disponible'] as bool? ?? true;

    return {
      'title': title,
      'price': price,
      'image': image,
      'currency': currency,
      'available': available,
    };
  }

  // ✅ MÉTODO COMPLETAMENTE CORREGIDO: Compatible con MessageModel y metadata
  Future<Message> sendFileMessage({
    required String chatId,
    required String fromId,
    required String fileUrl,
    required String fileName,
    required String fileSize,
    required String mimeType,
    bool isImage = false,
  }) async {
    try {
      AppLogger.d('📤 Enviando mensaje de archivo a chat: $chatId');

      // ✅ CORREGIDO: Usar MessageType en lugar de columnas booleanas
      final messageType = isImage ? MessageType.image : MessageType.file;
      
      // ✅ CORREGIDO: Usar metadata para información del archivo
      final metadata = {
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
      };

      final messageData = {
        'chat_id': chatId,
        'from_id': fromId,
        'text': isImage ? '🖼️ Imagen' : '📎 Archivo: $fileName',
        'type': messageType.name, // ✅ Usar el enum MessageType
        'metadata': json.encode(metadata), // ✅ CORREGIDO: Convertir a JSON string
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje de archivo insertado en base de datos');
      return Message.fromMap(response);

    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje de archivo: $e', e);
      rethrow;
    }
  }

  Future<Chat> createChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final chatData = {
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('chats')
          .insert(chatData)
          .select()
          .single();

      return Chat.fromMap(response);
    } catch (e) {
      AppLogger.e('Error creando chat: $e', e);
      rethrow;
    }
  }

  Future<List<Message>> loadMessages(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      return response.map((json) => Message.fromMap(json)).toList();
    } catch (e) {
      AppLogger.e('Error cargando mensajes: $e', e);
      rethrow;
    }
  }

  Future<Message> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    try {
      final messageData = {
        'chat_id': chatId,
        'from_id': fromId,
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      return Message.fromMap(response);
    } catch (e) {
      AppLogger.e('Error enviando mensaje: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO CORREGIDO: Stream con manejo de errores mejorado
  Stream<List<Message>> getMessagesStream(String chatId) {
    if (_messageStreams.containsKey(chatId)) {
      return _messageStreams[chatId]!.stream;
    }

    final controller = StreamController<List<Message>>();
    _messageStreams[chatId] = controller;

    final subscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .listen((event) {
      try {
        // ✅ CORREGIDO: Manejar correctamente el tipo de event
        final messages = event.map((json) {
          try {
            return Message.fromMap(json);
          } catch (e) {
            AppLogger.e('❌ Error mapeando mensaje: $e - JSON: $json');
            // Retornar un mensaje de error en lugar de fallar
            return Message(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              chatId: chatId,
              text: 'Error cargando mensaje',
              createdAt: DateTime.now(),
              isSystem: true,
            );
          }
        // ignore: unnecessary_null_comparison, unnecessary_non_null_assertion
        }).where((message) => message.id != null && !message.id!.startsWith('error_')).toList();
        
        controller.add(messages);
      } catch (e) {
        AppLogger.e('Error procesando stream de mensajes: $e - Event: $event');
        // Enviar lista vacía en caso de error para no bloquear la UI
        controller.add([]);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
      _messageStreams.remove(chatId);
    };

    return controller.stream;
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read': true})
          .eq('chat_id', chatId)
          .neq('from_id', userId)
          .eq('read', false);
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos: $e', e);
    }
  }

  void disposeChatStream(String chatId) {
    _messageStreams[chatId]?.close();
    _messageStreams.remove(chatId);
  }

  // ✅ MÉTODO MEJORADO: Eliminar chat completamente con limpieza
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando chat: $chatId');
      
      // 1. Primero obtener y limpiar archivos de todos los mensajes
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      for (final message in messages) {
        try {
          final metadata = message['metadata'];
          if (metadata != null && metadata is Map) {
            final fileUrl = metadata['file_url'];
            if (fileUrl != null) {
              await deleteFileFromStorage(fileUrl);
            }
          }
        } catch (e) {
          AppLogger.e('⚠️ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }
      
      // 2. Eliminar todos los mensajes del chat
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

      // 3. Luego eliminar el chat
      await _supabase
          .from('chats')
          .delete()
          .eq('id', chatId);

      AppLogger.d('✅ Chat eliminado completamente: $chatId');
    } catch (e) {
      AppLogger.e('❌ Error eliminando chat: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Limpiar mensajes del chat con limpieza de archivos
  Future<void> clearChatMessages(String chatId) async {
    try {
      AppLogger.d('🧹 Limpiando mensajes del chat: $chatId');
      
      // 1. Primero obtener y limpiar archivos
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      for (final message in messages) {
        try {
          final metadata = message['metadata'];
          if (metadata != null && metadata is Map) {
            final fileUrl = metadata['file_url'];
            if (fileUrl != null) {
              await deleteFileFromStorage(fileUrl);
            }
          }
        } catch (e) {
          AppLogger.e('⚠️ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }
      
      // 2. Eliminar mensajes
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

      // 3. Actualizar el chat para indicar que está vacío
      await _supabase
          .from('chats')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      AppLogger.d('✅ Mensajes del chat eliminados: $chatId');
    } catch (e) {
      AppLogger.e('❌ Error limpiando mensajes del chat: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar mensaje individual con limpieza automática
  Future<void> deleteMessage(String messageId, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje: $messageId (forEveryone: $deleteForEveryone)');
      
      // Primero obtener el mensaje para verificar si tiene archivos
      final messageResponse = await _supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();
      
      final message = Message.fromMap(messageResponse);
      
      // Si es mensaje de archivo/imagen, eliminar del storage primero
      if ((message.isFileMessage || message.isImageMessage) && message.fileUrl != null) {
        await deleteFileFromStorage(message.fileUrl!);
      }
      
      if (deleteForEveryone) {
        // Eliminar para todos los usuarios
        await _supabase
            .from('messages')
            .delete()
            .eq('id', messageId);
      } else {
        // Eliminar solo para el usuario actual (soft delete)
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) throw Exception('Usuario no autenticado');
        
        await _supabase
            .from('messages')
            .update({
              'text': 'Este mensaje fue eliminado',
              'metadata': json.encode({
                'deleted': true,
                'deleted_by': currentUser.id,
                'deleted_at': DateTime.now().toIso8601String(),
                'original_text': message.text,
                'original_type': message.type.name,
              })
            })
            .eq('id', messageId);
      }

      AppLogger.d('✅ Mensaje eliminado: $messageId');
    } catch (e) {
      AppLogger.e('❌ Error eliminando mensaje: $e', e);
      rethrow;
    }
  }

  // ✅ NUEVO MÉTODO: Eliminar archivo del storage (reutilizable)
  Future<void> deleteFileFromStorage(String fileUrl) async {
    try {
      AppLogger.d('🗑️ Eliminando archivo del storage: $fileUrl');
      
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      String? bucketName;
      String? fileName;
      
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'storage' && i + 1 < pathSegments.length) {
          bucketName = pathSegments[i + 1];
          if (i + 2 < pathSegments.length) {
            fileName = pathSegments.sublist(i + 2).join('/');
          }
          break;
        }
      }
      
      if (bucketName != null && fileName != null) {
        await _supabase.storage
            .from(bucketName)
            .remove([fileName]);
        AppLogger.d('✅ Archivo eliminado del storage: $fileName en bucket $bucketName');
      } else {
        AppLogger.w('⚠️ No se pudo extraer información del archivo de la URL: $fileUrl');
      }
    } catch (e) {
      AppLogger.e('❌ Error eliminando archivo del storage: $e');
      // No rethrow para no bloquear la eliminación del mensaje
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar mensaje de archivo (mantener por compatibilidad)
  Future<void> deleteFileMessage(String messageId, String fileUrl) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje de archivo: $messageId');
      
      // Eliminar archivo del storage
      await deleteFileFromStorage(fileUrl);
      
      // Eliminar el mensaje de la base de datos
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      AppLogger.d('✅ Mensaje de archivo eliminado completamente: $messageId');
    } catch (e) {
      AppLogger.e('❌ Error eliminando mensaje de archivo: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO ADICIONAL: Verificar si un chat existe
  Future<bool> chatExists(String productId, String buyerId, String sellerId) async {
    try {
      final response = await _supabase
          .from('chats')
          .select('id')
          .eq('product_id', productId)
          .or('buyer_id.eq.$buyerId,seller_id.eq.$buyerId')
          .or('buyer_id.eq.$sellerId,seller_id.eq.$sellerId')
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.e('Error verificando existencia de chat: $e');
      return false;
    }
  }

  // ✅ MÉTODO ADICIONAL: Obtener chat por ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      final response = await _supabase
          .from('chats')
          .select('''
            *,
            products:product_id(titulo, precio, imagen_url, disponible, moneda),
            buyer:buyer_id(username, avatar_url, email),
            seller:seller_id(username, avatar_url, email)
          ''')
          .eq('id', chatId)
          .single();

      return _processChatData(response, _supabase.auth.currentUser?.id ?? '');
    } catch (e) {
      AppLogger.e('Error obteniendo chat por ID: $e');
      return null;
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener estadísticas del chat (sin parámetro count)
  Future<Map<String, dynamic>> getChatStats(String chatId) async {
    try {
      // Obtener todos los mensajes y contar manualmente
      final messagesResponse = await _supabase
          .from('messages')
          .select('id, read, from_id')
          .eq('chat_id', chatId);

      final currentUserId = _supabase.auth.currentUser?.id;
      
      int totalMessages = messagesResponse.length;
      int unreadMessages = 0;

      if (currentUserId != null) {
        unreadMessages = messagesResponse.where((message) {
          final isFromOtherUser = message['from_id'] != currentUserId;
          final isUnread = message['read'] == false;
          return isFromOtherUser && isUnread;
        }).length;
      }

      return {
        'totalMessages': totalMessages,
        'unreadMessages': unreadMessages,
        'lastActivity': DateTime.now(),
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estadísticas del chat: $e');
      return {
        'totalMessages': 0,
        'unreadMessages': 0,
        'lastActivity': DateTime.now(),
      };
    }
  }

  // ✅ MÉTODO ADICIONAL: Obtener último mensaje del chat
  Future<Message?> getLastMessage(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? Message.fromMap(response) : null;
    } catch (e) {
      AppLogger.e('Error obteniendo último mensaje: $e');
      return null;
    }
  }

  // ✅ MÉTODO ADICIONAL: Buscar mensajes en un chat
  Future<List<Message>> searchMessages(String chatId, String query) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .textSearch('text', query)
          .order('created_at', ascending: false);

      return response.map((json) => Message.fromMap(json)).toList();
    } catch (e) {
      AppLogger.e('Error buscando mensajes: $e');
      return [];
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener mensajes no leídos para un usuario
  Future<List<Message>> getUnreadMessages(String userId) async {
    try {
      // Primero obtener los chats del usuario
      final userChats = await getUserChats(userId);
      final chatIds = userChats.map((chat) => chat.id).toList();

      if (chatIds.isEmpty) return [];

      // Consultar mensajes no leídos para cada chat individualmente
      List<Map<String, dynamic>> allUnreadMessages = [];
      
      for (final chatId in chatIds) {
        try {
          final response = await _supabase
              .from('messages')
              .select()
              .eq('chat_id', chatId)
              .neq('from_id', userId)
              .eq('read', false)
              .order('created_at', ascending: false);

          allUnreadMessages.addAll(List<Map<String, dynamic>>.from(response));
        } catch (e) {
          AppLogger.e('Error obteniendo mensajes no leídos para chat $chatId: $e');
          // Continuar con el siguiente chat
        }
      }

      // Convertir a objetos Message y ordenar por fecha
      final messages = allUnreadMessages
          .map((json) => Message.fromMap(json))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.d('✅ Mensajes no leídos obtenidos: ${messages.length}');
      return messages;

    } catch (e) {
      AppLogger.e('Error obteniendo mensajes no leídos: $e');
      return [];
    }
  }

  // ✅ MÉTODO ADICIONAL: Limpiar mensajes antiguos (para mantenimiento)
  Future<int> cleanupOldMessages({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Primero obtener mensajes antiguos con archivos
      // ignore: avoid_init_to_null
      var value = null;
      final oldMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .lt('created_at', cutoffDate.toIso8601String())
          .neq('metadata', value);

      // Limpiar archivos del storage
      for (final message in oldMessages) {
        try {
          final metadata = message['metadata'];
          if (metadata is Map && metadata['file_url'] != null) {
            await deleteFileFromStorage(metadata['file_url']);
          }
        } catch (e) {
          AppLogger.e('⚠️ Error limpiando archivo del mensaje antiguo ${message['id']}: $e');
        }
      }
      
      // Eliminar mensajes antiguos
      final response = await _supabase
          .from('messages')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ Mensajes antiguos eliminados: $deletedCount');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Error limpiando mensajes antiguos: $e');
      return 0;
    }
  }

  // ✅ MÉTODO ADICIONAL: Obtener conteo de mensajes no leídos por chat
  Future<Map<String, int>> getUnreadCountsByChat(String userId) async {
    try {
      final userChats = await getUserChats(userId);
      final Map<String, int> unreadCounts = {};

      for (final chat in userChats) {
        try {
          final messagesResponse = await _supabase
              .from('messages')
              .select('id, read, from_id')
              .eq('chat_id', chat.id)
              .neq('from_id', userId)
              .eq('read', false);

          unreadCounts[chat.id] = messagesResponse.length;
        } catch (e) {
          AppLogger.e('Error obteniendo conteo para chat ${chat.id}: $e');
          unreadCounts[chat.id] = 0;
        }
      }

      return unreadCounts;
    } catch (e) {
      AppLogger.e('Error obteniendo conteos de mensajes no leídos: $e');
      return {};
    }
  }

  // ✅ MÉTODO ADICIONAL: Obtener mensajes por tipo
  Future<List<Message>> getMessagesByType(String chatId, MessageType type) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .eq('type', type.name)
          .order('created_at', ascending: false);

      return response.map((json) => Message.fromMap(json)).toList();
    } catch (e) {
      AppLogger.e('Error obteniendo mensajes por tipo: $e');
      return [];
    }
  }

  // ✅ MÉTODO ADICIONAL: Verificar si hay mensajes nuevos
  Future<bool> hasNewMessages(String chatId, String userId, DateTime lastSeen) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, created_at, from_id')
          .eq('chat_id', chatId)
          .neq('from_id', userId)
          .gt('created_at', lastSeen.toIso8601String())
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error verificando mensajes nuevos: $e');
      return false;
    }
  }
}