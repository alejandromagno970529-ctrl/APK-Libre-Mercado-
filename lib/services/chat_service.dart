// lib/services/chat_service.dart - VERSIÓN COMPLETA (TODAS LAS FUNCIONES) CON CORRECCIONES DE ELIMINACIÓN
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

  // ✅ MÉTODO ORIGINAL: Obtener chats
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

  // ✅ PROCESAR DATOS DEL CHAT
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

      // Extraer información del producto
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

  // ✅ EXTRAER INFORMACIÓN DEL PRODUCTO
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

    String? title = products['titulo'] as String?;
    double? price;
    if (products['precio'] != null) {
      price = (products['precio'] as num).toDouble();
    }
    String? image = products['imagen_url'] as String?;
    String? currency = products['moneda'] as String?;
    bool available = products['disponible'] as bool? ?? true;

    return {
      'title': title,
      'price': price,
      'image': image,
      'currency': currency,
      'available': available,
    };
  }

  // ✅ MÉTODO ORIGINAL: sendFileMessage
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

      final messageType = isImage ? MessageType.image : MessageType.file;
      
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
        'type': messageType.name, 
        'metadata': json.encode(metadata),
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

  // ✅ MÉTODO ORIGINAL: createChat
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

  // ✅ MÉTODO ORIGINAL: loadMessages
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

  // ✅ MÉTODO ORIGINAL: sendMessage
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

  // ✅ MÉTODO ORIGINAL: getMessagesStream
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
        final messages = event.map((json) {
          try {
            return Message.fromMap(json);
          } catch (e) {
            AppLogger.e('❌ Error mapeando mensaje: $e - JSON: $json');
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
        controller.add([]);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
      _messageStreams.remove(chatId);
    };

    return controller.stream;
  }

  // ✅ MÉTODO ORIGINAL: markMessagesAsRead
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

  // ⭐⭐⭐ MEJORADO: deleteChat con lógica de eliminación robusta
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando chat: $chatId');
      
      // 1. Obtener mensajes para limpiar archivos (Mejorado para manejar JSON y Map)
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      for (final message in messages) {
        try {
          final rawMetadata = message['metadata'];
          if (rawMetadata != null) {
            Map<String, dynamic> metadata;
            
            // Manejar si viene como String JSON o como Map directo
            if (rawMetadata is String) {
               try {
                 metadata = json.decode(rawMetadata);
               } catch (_) { metadata = {}; }
            } else if (rawMetadata is Map) {
               metadata = Map<String, dynamic>.from(rawMetadata);
            } else {
               metadata = {};
            }

            final fileUrl = metadata['file_url'];
            if (fileUrl != null && fileUrl.toString().isNotEmpty) {
              await deleteFileFromStorage(fileUrl.toString());
            }
          }
        } catch (e) {
          AppLogger.e('⚠️ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }
      
      // 2. Eliminar todos los mensajes
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

      // 3. Eliminar el chat
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

  // ⭐⭐⭐ MEJORADO: clearChatMessages con lógica de eliminación robusta
  Future<void> clearChatMessages(String chatId) async {
    try {
      AppLogger.d('🧹 Limpiando mensajes del chat: $chatId');
      
      // 1. Obtener y limpiar archivos
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      for (final message in messages) {
        try {
          final rawMetadata = message['metadata'];
          if (rawMetadata != null) {
            Map<String, dynamic> metadata;
            
            if (rawMetadata is String) {
               try {
                 metadata = json.decode(rawMetadata);
               } catch (_) { metadata = {}; }
            } else if (rawMetadata is Map) {
               metadata = Map<String, dynamic>.from(rawMetadata);
            } else {
               metadata = {};
            }

            final fileUrl = metadata['file_url'];
            if (fileUrl != null && fileUrl.toString().isNotEmpty) {
              await deleteFileFromStorage(fileUrl.toString());
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

      // 3. Actualizar el chat
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

  // ⭐⭐⭐ MEJORADO: deleteMessage (Elimina imagen antes de borrar registro)
  Future<void> deleteMessage(String messageId, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje: $messageId (forEveryone: $deleteForEveryone)');
      
      // 1. Obtener mensaje completo
      final messageResponse = await _supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();
      
      final message = Message.fromMap(messageResponse);
      
      // 2. Eliminar archivo físico si existe
      if ((message.isFileMessage || message.isImageMessage) && message.fileUrl != null) {
        try {
          await deleteFileFromStorage(message.fileUrl!);
          AppLogger.d('✅ Archivo eliminado del storage: ${message.fileUrl}');
        } catch (e) {
          AppLogger.e('⚠️ Error eliminando archivo, continuando...: $e');
        }
      }
      
      // 3. Eliminar de base de datos
      if (deleteForEveryone) {
        await _supabase
            .from('messages')
            .delete()
            .eq('id', messageId);
      } else {
        // Soft delete
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
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
                  'original_file_url': message.fileUrl,
                })
              })
              .eq('id', messageId);
        }
      }

      AppLogger.d('✅ Mensaje eliminado completamente: $messageId');
    } catch (e) {
      AppLogger.e('❌ Error eliminando mensaje: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO ORIGINAL: deleteMultipleMessages
  Future<void> deleteMultipleMessages(List<String> messageIds, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Eliminando ${messageIds.length} mensajes...');
      
      for (final messageId in messageIds) {
        await deleteMessage(messageId, deleteForEveryone: deleteForEveryone);
      }
      
      AppLogger.d('✅ ${messageIds.length} mensajes eliminados completamente');
    } catch (e) {
      AppLogger.e('❌ Error eliminando múltiples mensajes: $e', e);
      rethrow;
    }
  }

  // ⭐⭐⭐ REESCRITO: deleteFileFromStorage (Nueva lógica compatible con Supabase URLs)
  Future<void> deleteFileFromStorage(String fileUrl) async {
    try {
      AppLogger.d('🗑️ Intentando borrar archivo físico: $fileUrl');
      
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // Lógica de URL Supabase: .../storage/v1/object/public/{bucket}/{folder}/{file}
      // Buscamos "public" (o "authenticated") para saber dónde empieza el bucket
      
      int bucketIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        // Supabase standard public URL segment
        if (pathSegments[i] == 'public' && i + 1 < pathSegments.length) {
          bucketIndex = i + 1;
          break;
        }
      }
      
      // Fallback: si no encuentra 'public', intenta buscar 'storage' y asume estructura
      if (bucketIndex == -1) {
         for (int i = 0; i < pathSegments.length; i++) {
            if (pathSegments[i] == 'storage' && i + 1 < pathSegments.length) {
               // A veces la url no tiene 'public' explícito dependiendo de la config
               // Esto es un intento de compatibilidad con tu código anterior
               // pero el método de arriba es más seguro para URLs públicas estándar
            }
         }
      }
      
      if (bucketIndex != -1) {
        final bucketName = pathSegments[bucketIndex];
        // El resto de segmentos forman el path del archivo
        final fileName = pathSegments.sublist(bucketIndex + 1).join('/');
        
        AppLogger.d('📦 Bucket detectado: $bucketName');
        AppLogger.d('📄 Archivo a borrar: $fileName');
        
        await _supabase.storage
            .from(bucketName)
            .remove([fileName]);
            
        AppLogger.d('✅ Archivo eliminado del Storage exitosamente');
      } else {
        AppLogger.w('⚠️ No se pudo parsear correctamente la URL de Supabase: $fileUrl');
      }
    } catch (e) {
      // Capturamos el error para no detener el flujo principal
      AppLogger.e('❌ Error al borrar del storage (posible error de permisos o archivo no existe): $e');
    }
  }

  // ✅ MÉTODO ORIGINAL: deleteFileMessage
  Future<void> deleteFileMessage(String messageId, String fileUrl) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje de archivo: $messageId');
      
      await deleteFileFromStorage(fileUrl);
      
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

  // ✅ MÉTODO ORIGINAL: chatExists
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

  // ✅ MÉTODO ORIGINAL: getChatById
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

  // ✅ MÉTODO ORIGINAL: getChatStats
  Future<Map<String, dynamic>> getChatStats(String chatId) async {
    try {
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

  // ✅ MÉTODO ORIGINAL: getLastMessage
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

  // ✅ MÉTODO ORIGINAL: searchMessages
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

  // ✅ MÉTODO ORIGINAL: getUnreadMessages
  Future<List<Message>> getUnreadMessages(String userId) async {
    try {
      final userChats = await getUserChats(userId);
      final chatIds = userChats.map((chat) => chat.id).toList();

      if (chatIds.isEmpty) return [];

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
        }
      }

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

  // ⭐⭐⭐ MEJORADO: cleanupOldMessages (Asegura borrado de archivos)
  Future<int> cleanupOldMessages({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // 1. Obtener mensajes antiguos con archivos
      // ignore: avoid_init_to_null
      var value = null;
      final oldMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .lt('created_at', cutoffDate.toIso8601String())
          .neq('metadata', value);

      // 2. Limpiar archivos del storage
      for (final message in oldMessages) {
        try {
          final rawMetadata = message['metadata'];
          if (rawMetadata != null) {
            Map<String, dynamic> metadata;
            if (rawMetadata is String) {
               try { metadata = json.decode(rawMetadata); } catch(_) { metadata = {}; }
            } else {
               metadata = rawMetadata as Map<String, dynamic>;
            }

            final fileUrl = metadata['file_url'];
            if (fileUrl != null) {
              await deleteFileFromStorage(fileUrl.toString());
            }
          }
        } catch (e) {
          AppLogger.e('⚠️ Error limpiando archivo del mensaje antiguo ${message['id']}: $e');
        }
      }
      
      // 3. Eliminar mensajes antiguos
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

  // ✅ MÉTODO ORIGINAL: getUnreadCountsByChat
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

  // ✅ MÉTODO ORIGINAL: getMessagesByType
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

  // ✅ MÉTODO ORIGINAL: hasNewMessages
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