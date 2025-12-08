// lib/services/chat_service.dart - VERSIÓN 18.0.0 MEJORADA
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';
import '../utils/time_utils.dart';

class ChatService {
  final SupabaseClient _supabase;
  late final NotificationService _notificationService;

  ChatService(this._supabase) {
    _notificationService = NotificationService(_supabase);
  }

  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  // ✅ MÉTODO NUEVO: Sanitizar JSON antes de procesar
  Map<String, dynamic> _sanitizeJsonForMessage(Map<String, dynamic> json) {
    final Map<String, dynamic> sanitized = Map.from(json);
    
    AppLogger.d('🔧 SANITIZANDO JSON - Claves: ${sanitized.keys.toList()}');
    
    // Convertir DateTime a String si es necesario
    for (final key in sanitized.keys) {
      final value = sanitized[key];
      if (value is DateTime) {
        sanitized[key] = value.toIso8601String();
        AppLogger.d('🔄 Convertido $key de DateTime a String: ${sanitized[key]}');
      } else if (value is Map) {
        sanitized[key] = _sanitizeJsonForMessage(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is DateTime) return e.toIso8601String();
          if (e is Map) return _sanitizeJsonForMessage(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      }
    }
    
    return sanitized;
  }

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
          // ✅ SANITIZAR DATOS ANTES DE PROCESAR
          final sanitizedChatData = _sanitizeJsonForMessage(Map<String, dynamic>.from(chatData));
          final chat = _processChatData(sanitizedChatData, userId);
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
        createdAt: DateTime.parse(chatData['created_at'] as String),
        updatedAt: DateTime.parse(chatData['updated_at'] as String),
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

  // ✅ MÉTODO CORREGIDO: sendFileMessage con metadata simplificado
  Future<Message> sendFileMessage({
    required String chatId,
    required String fromId,
    required String fileUrl,
    required String fileName,
    required String fileSize,
    required String mimeType,
    bool isImage = false,
    required String fromName,
    required String toUserId,
    required String productTitle,
  }) async {
    try {
      AppLogger.d('📤 Enviando mensaje de archivo a chat: $chatId');

      final messageType = isImage ? MessageType.image : MessageType.file;
      
      // ✅ USAR TimeUtils.ensureJsonSerializable para metadata
      final metadata = TimeUtils.ensureJsonSerializable({
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      final messageData = TimeUtils.cleanMapForSupabase({
        'chat_id': chatId,
        'from_id': fromId,
        'text': isImage ? '🖼️ Imagen' : '📎 Archivo: $fileName',
        'type': messageType.name, 
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'delivered': false,
      });

      AppLogger.d('💾 Insertando mensaje de archivo en base de datos...');
      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      // ✅ Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje de archivo insertado en base de datos - ID: ${response['id']}');
      
      // ✅ ENVIAR NOTIFICACIÓN
      try {
        await _notificationService.sendChatNotification(
          toUserId: toUserId,
          fromUserName: fromName,
          productTitle: productTitle,
          messageText: isImage ? '🖼️ Imagen' : '📎 Archivo: $fileName',
          chatId: chatId,
        );
        AppLogger.d('✅ Notificación interna enviada a: $toUserId');
      } catch (notifError) {
        AppLogger.e('⚠️ Error enviando notificación (no crítico): $notifError');
      }

      return Message.fromMap(response);

    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje de archivo: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO CORREGIDO: sendMessage
  Future<Message> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
    required String fromName,
    required String toUserId,
    required String productTitle,
  }) async {
    try {
      AppLogger.d('📤 Enviando mensaje de texto a chat: $chatId');

      final messageData = {
        'chat_id': chatId,
        'from_id': fromId,
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'delivered': false,
      };

      AppLogger.d('💾 Insertando mensaje de texto en base de datos...');
      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      // ✅ Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      // ✅ ENVIAR NOTIFICACIÓN
      try {
        await _notificationService.sendChatNotification(
          toUserId: toUserId,
          fromUserName: fromName,
          productTitle: productTitle,
          messageText: text,
          chatId: chatId,
        );
        AppLogger.d('✅ Notificación interna enviada a: $toUserId');
      } catch (notifError) {
        AppLogger.e('⚠️ Error enviando notificación (no crítico): $notifError');
      }

      AppLogger.d('✅ Mensaje de texto insertado en base de datos - ID: ${response['id']}');
      return Message.fromMap(response);
    } catch (e) {
      AppLogger.e('Error enviando mensaje: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Stream con diagnóstico completo Y SANITIZACIÓN
  Stream<List<Message>> getMessagesStream(String chatId) {
    // ✅ Reutilizar stream existente si está activo
    if (_messageStreams.containsKey(chatId) && 
        !_messageStreams[chatId]!.isClosed) {
      AppLogger.d('🔁 Reutilizando stream existente para: $chatId');
      return _messageStreams[chatId]!.stream;
    }

    final controller = StreamController<List<Message>>();
    _messageStreams[chatId] = controller;

    AppLogger.d('🔊 Creando nuevo stream para chat: $chatId');

    final subscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .listen((event) {
      try {
        AppLogger.d('📨 Stream recibió ${event.length} eventos para chat: $chatId');

        // ✅ DIAGNÓSTICO DETALLADO DE LOS DATOS RECIBIDOS
        if (event.isNotEmpty) {
          final sample = event.first;
          AppLogger.d('🔍 DIAGNÓSTICO STREAM - Primer mensaje recibido:');
          AppLogger.d('   - Tipo created_at: ${sample['created_at'].runtimeType}');
          AppLogger.d('   - Valor created_at: ${sample['created_at']}');
          AppLogger.d('   - Tipo metadata: ${sample['metadata']?.runtimeType}');
          
          // Verificar si hay DateTime en los datos
          if (sample['created_at'] is DateTime) {
            AppLogger.w('⚠️ RECIBIDO DateTime EN LUGAR DE String en created_at');
          }
        }

        final messages = event.map((json) {
          try {
            // ✅ SANITIZAR LOS DATOS ANTES DE PROCESAR
            final sanitizedJson = _sanitizeJsonForMessage(json);
            AppLogger.d('✅ JSON sanitizado para mensaje: ${sanitizedJson['id']}');
            
            // ✅ DIAGNÓSTICO ADICIONAL
            TimeUtils.diagnoseJsonValue(sanitizedJson, 'mensaje sanitizado');
            
            return Message.fromMap(sanitizedJson);
          } catch (e) {
            AppLogger.e('❌ Error mapeando mensaje: $e - JSON: $json');
            AppLogger.e('🔍 ERROR DETAIL: $e');
            return Message(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              chatId: chatId,
              text: 'Error cargando mensaje',
              createdAt: DateTime.now(),
              isSystem: true,
            );
          }
        }).where((message) => 
            // ignore: unnecessary_null_comparison
            message.id != null && 
            // ignore: unnecessary_non_null_assertion
            !message.id!.startsWith('error_')
        ).toList();
        
        // ✅ Ordenar por fecha descendente (más recientes primero)
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (messages.isNotEmpty && !controller.isClosed) {
          AppLogger.d('📤 Enviando ${messages.length} mensajes al stream de: $chatId');
          controller.add(messages);
        } else if (controller.isClosed) {
          AppLogger.d('🔇 Controlador cerrado, ignorando actualización para: $chatId');
        }
      } catch (e) {
        AppLogger.e('❌ Error procesando stream de mensajes: $e');
        AppLogger.e('🔍 ERROR DETAIL: $e');
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }, onError: (error) {
      AppLogger.e('❌ Error en stream de mensajes: $error');
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    controller.onCancel = () {
      AppLogger.d('🔇 Cancelando stream para: $chatId');
      subscription.cancel();
      _messageStreams.remove(chatId);
    };

    return controller.stream;
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
      AppLogger.d('📥 Cargando mensajes para chat: $chatId');
      
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      final messages = response.map((json) {
        // ✅ SANITIZAR ANTES DE PROCESAR
        final sanitizedJson = _sanitizeJsonForMessage(json);
        return Message.fromMap(sanitizedJson);
      }).toList();
      
      AppLogger.d('✅ ${messages.length} mensajes cargados para chat: $chatId');
      
      return messages;
    } catch (e) {
      AppLogger.e('Error cargando mensajes: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Marcar mensajes como entregados
  Future<void> markMessagesAsDelivered(String chatId, String userId) async {
    try {
      AppLogger.d('📨 Marcando mensajes como entregados para chat: $chatId');
      
      await _supabase
          .from('messages')
          .update({
            'delivered': true,
            'delivered_at': DateTime.now().toIso8601String()
          })
          .eq('chat_id', chatId)
          .neq('from_id', userId)
          .eq('delivered', false);

      AppLogger.d('✅ Mensajes marcados como entregados para chat: $chatId');
    } catch (e) {
      AppLogger.e('Error marcando mensajes como entregados: $e', e);
    }
  }

  // ✅ MÉTODO CORREGIDO: Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      AppLogger.d('👀 Marcando mensajes como leídos para chat: $chatId');
      
      final result = await _supabase
          .from('messages')
          .update({
            'read': true,
            'read_at': DateTime.now().toIso8601String()
          })
          .eq('chat_id', chatId)
          .neq('from_id', userId)
          .eq('read', false)
          .select();

      AppLogger.d('✅ ${result.length} mensajes marcados como leídos para chat: $chatId');
      
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos: $e', e);
    }
  }

  // ✅ MÉTODO OPCIONAL: Solo para confirmación explícita
  Future<void> sendReadConfirmation(String chatId, String userId) async {
    try {
      // Verificar si ya hay un mensaje de "Mensajes leídos" reciente
      final recentReadReceipts = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .eq('text', '📨 Mensajes leídos')
          .gte('created_at', DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String())
          .limit(1);

      if (recentReadReceipts.isEmpty) {
        final readReceiptMessage = {
          'chat_id': chatId,
          'from_id': userId,
          'text': '📨 Mensajes leídos',
          'type': 'system',
          'is_system': true,
          'metadata': TimeUtils.ensureJsonSerializable({
            'read_receipt': true,
            'read_at': DateTime.now().toIso8601String(),
            'reader_id': userId
          }),
          'created_at': DateTime.now().toIso8601String(),
          'read': true,
          'delivered': true,
        };

        await _supabase
            .from('messages')
            .insert(readReceiptMessage);
            
        AppLogger.d('✅ Acuse de recibo enviado para chat: $chatId');
      } else {
        AppLogger.d('✅ Ya existe un acuse de recibo reciente, no se envía otro');
      }
    } catch (e) {
      AppLogger.e('Error enviando acuse de recibo: $e');
    }
  }

  // ✅ MÉTODO MEJORADO: Obtener estados de mensajes
  Future<Map<String, dynamic>> getMessageStatus(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, delivered, delivered_at, read, read_at')
          .eq('id', messageId)
          .single();

      return {
        'id': response['id'],
        'delivered': response['delivered'] ?? false,
        'delivered_at': response['delivered_at'] != null 
            ? DateTime.parse(response['delivered_at']) 
            : null,
        'read': response['read'] ?? false,
        'read_at': response['read_at'] != null 
            ? DateTime.parse(response['read_at']) 
            : null,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estado del mensaje: $e');
      return {'error': e.toString()};
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
          .select('id, read, delivered, from_id')
          .eq('chat_id', chatId);

      final currentUserId = _supabase.auth.currentUser?.id;
      
      int totalMessages = messagesResponse.length;
      int unreadMessages = 0;
      int undeliveredMessages = 0;

      if (currentUserId != null) {
        unreadMessages = messagesResponse.where((message) {
          final isFromOtherUser = message['from_id'] != currentUserId;
          final isUnread = message['read'] == false;
          return isFromOtherUser && isUnread;
        }).length;

        undeliveredMessages = messagesResponse.where((message) {
          final isFromCurrentUser = message['from_id'] == currentUserId;
          final isUndelivered = message['delivered'] == false;
          return isFromCurrentUser && isUndelivered;
        }).length;
      }

      return {
        'totalMessages': totalMessages,
        'unreadMessages': unreadMessages,
        'undeliveredMessages': undeliveredMessages,
        'lastActivity': DateTime.now(),
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estadísticas del chat: $e');
      return {
        'totalMessages': 0,
        'unreadMessages': 0,
        'undeliveredMessages': 0,
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

  // ✅ CORRECCIÓN COMPLETA del método cleanupOldMessages
  Future<int> cleanupOldMessages({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      AppLogger.d('🧹 Limpiando mensajes antiguos anteriores a: $cutoffDate');
      
      // Obtener todos los mensajes antiguos primero
      final oldMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .lt('created_at', cutoffDate.toIso8601String());

      AppLogger.d('📝 Encontrados ${oldMessages.length} mensajes antiguos');

      int filesCleaned = 0;
      
      // Limpiar archivos del storage solo para mensajes con metadata válida
      for (final message in oldMessages) {
        try {
          final rawMetadata = message['metadata'];
          if (rawMetadata != null) {
            Map<String, dynamic> metadata;
            
            if (rawMetadata is String) {
              try { 
                metadata = json.decode(rawMetadata); 
              } catch(_) { 
                continue;
              }
            } else if (rawMetadata is Map) {
              metadata = Map<String, dynamic>.from(rawMetadata);
            } else {
              continue;
            }

            final fileUrl = metadata['file_url'];
            if (fileUrl != null && fileUrl is String && fileUrl.isNotEmpty) {
              await deleteFileFromStorage(fileUrl);
              filesCleaned++;
            }
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
      AppLogger.d('✅ Mensajes antiguos eliminados: $deletedCount, Archivos limpiados: $filesCleaned');
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

  // ✅ NUEVO MÉTODO: Verificar estado del servicio
  Future<Map<String, dynamic>> checkServiceStatus() async {
    try {
      AppLogger.d('🔍 Verificando estado del ChatService...');
      
      final testResult = await _supabase
          .from('chats')
          .select('count(*)')
          .limit(1);
      
      final activeStreams = _messageStreams.length;
      
      return {
        'success': true,
        'supabase_connected': testResult.isNotEmpty,
        'active_streams': activeStreams,
        'message': 'ChatService funcionando correctamente'
      };
    } catch (e) {
      AppLogger.e('❌ Error verificando estado del servicio: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Problemas con ChatService'
      };
    }
  }

  void disposeChatStream(String chatId) {
    try {
      if (_messageStreams.containsKey(chatId)) {
        _messageStreams[chatId]?.close();
        _messageStreams.remove(chatId);
        AppLogger.d('✅ Stream eliminado para chat: $chatId');
      }
    } catch (e) {
      AppLogger.e('❌ Error eliminando stream: $e', e);
    }
  }

  // ✅ MÉTODO MEJORADO: deleteChat con limpieza robusta
  Future<void> deleteChat(String chatId) async {
    try {
      AppLogger.d('🗑️ Eliminando chat: $chatId');
      
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      AppLogger.d('📝 Limpiando ${messages.length} archivos del chat...');

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
      
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

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

  // ✅ MÉTODO MEJORADO: clearChatMessages
  Future<void> clearChatMessages(String chatId) async {
    try {
      AppLogger.d('🧹 Limpiando mensajes del chat: $chatId');
      
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .eq('chat_id', chatId);

      AppLogger.d('📝 Limpiando ${messages.length} archivos...');

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
      
      await _supabase
          .from('messages')
          .delete()
          .eq('chat_id', chatId);

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

  // ✅ MÉTODO MEJORADO: deleteMessage
  Future<void> deleteMessage(String messageId, {bool deleteForEveryone = false}) async {
    try {
      AppLogger.d('🗑️ Eliminando mensaje: $messageId (forEveryone: $deleteForEveryone)');
      
      final messageResponse = await _supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();
      
      final message = Message.fromMap(messageResponse);
      
      if ((message.isFileMessage || message.isImageMessage) && message.fileUrl != null) {
        try {
          await deleteFileFromStorage(message.fileUrl!);
          AppLogger.d('✅ Archivo eliminado del storage: ${message.fileUrl}');
        } catch (e) {
          AppLogger.e('⚠️ Error eliminando archivo, continuando...: $e');
        }
      }
      
      if (deleteForEveryone) {
        await _supabase
            .from('messages')
            .delete()
            .eq('id', messageId);
      } else {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          await _supabase
              .from('messages')
              .update({
                'text': 'Este mensaje fue eliminado',
                'metadata': TimeUtils.ensureJsonSerializable({
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

  // ✅ MÉTODO REESCRITO: deleteFileFromStorage
  Future<void> deleteFileFromStorage(String fileUrl) async {
    try {
      AppLogger.d('🗑️ Intentando borrar archivo físico: $fileUrl');
      
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      int bucketIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'public' && i + 1 < pathSegments.length) {
          bucketIndex = i + 1;
          break;
        }
      }
      
      if (bucketIndex != -1) {
        final bucketName = pathSegments[bucketIndex];
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
      AppLogger.e('❌ Error al borrar del storage: $e');
    }
  }

  // ✅ MÉTODO MEJORADO: Obtener conteo de mensajes no leídos por chat
  Future<int> getUnreadCountForChat(String chatId, String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, read, from_id')
          .eq('chat_id', chatId)
          .neq('from_id', userId)
          .eq('read', false);

      final count = response.length;
      AppLogger.d('📊 Mensajes no leídos para chat $chatId: $count');
      return count;
    } catch (e) {
      AppLogger.e('Error obteniendo conteo de no leídos: $e');
      return 0;
    }
  }

  // ✅ MÉTODO MEJORADO: Obtener conteos de no leídos para todos los chats
  Future<Map<String, int>> getUnreadCounts(String userId) async {
    try {
      final userChats = await getUserChats(userId);
      final Map<String, int> unreadCounts = {};

      for (final chat in userChats) {
        try {
          final count = await getUnreadCountForChat(chat.id, userId);
          unreadCounts[chat.id] = count;
        } catch (e) {
          AppLogger.e('Error obteniendo conteo para chat ${chat.id}: $e');
          unreadCounts[chat.id] = 0;
        }
      }

      AppLogger.d('📊 Conteos de no leídos obtenidos: ${unreadCounts.length} chats');
      return unreadCounts;
    } catch (e) {
      AppLogger.e('Error obteniendo conteos de no leídos: $e');
      return {};
    }
  }

  // ✅ MÉTODO: Obtener el estado de entrega de un mensaje específico
  Future<Map<String, dynamic>> getMessageDeliveryStatus(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, delivered, delivered_at, read, read_at')
          .eq('id', messageId)
          .single();

      return {
        'id': response['id'],
        'delivered': response['delivered'] ?? false,
        'delivered_at': response['delivered_at'] != null
            ? DateTime.parse(response['delivered_at'])
            : null,
        'read': response['read'] ?? false,
        'read_at': response['read_at'] != null
            ? DateTime.parse(response['read_at'])
            : null,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estado de entrega: $e');
      return {
        'id': messageId,
        'delivered': false,
        'delivered_at': null,
        'read': false,
        'read_at': null,
      };
    }
  }

  // ✅ MÉTODO: Enviar acuse de recibo de entrega
  Future<void> sendDeliveryReceipt(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'delivered': true,
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      AppLogger.d('✅ Acuse de entrega enviado para mensaje: $messageId');
    } catch (e) {
      AppLogger.e('Error enviando acuse de entrega: $e');
    }
  }

  // ✅ MÉTODO: Verificar conexión de usuario (para presencia)
  Future<bool> checkUserConnection(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('created_at')
          .eq('from_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final lastMessageTime = DateTime.parse(response['created_at']);
        final difference = DateTime.now().difference(lastMessageTime);
        
        return difference.inMinutes < 5;
      }
      
      return false;
    } catch (e) {
      AppLogger.e('Error verificando conexión de usuario: $e');
      return false;
    }
  }

  // ✅ MÉTODO: Obtener actividad reciente del chat
  Future<Map<String, dynamic>> getChatActivity(String chatId) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select('created_at, from_id')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(10);

      if (messages.isNotEmpty) {
        final lastMessage = messages.first;
        final lastMessageTime = DateTime.parse(lastMessage['created_at']);
        final fromId = lastMessage['from_id'] as String;
        
        return {
          'last_message_time': lastMessageTime,
          'last_message_from': fromId,
          'is_active': DateTime.now().difference(lastMessageTime).inMinutes < 30,
        };
      }
      
      return {
        'last_message_time': null,
        'last_message_from': null,
        'is_active': false,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo actividad del chat: $e');
      return {
        'last_message_time': null,
        'last_message_from': null,
        'is_active': false,
      };
    }
  }

  // ✅ NUEVO MÉTODO: Diagnóstico de problemas de DateTime - VERSIÓN MEJORADA
  Future<void> diagnoseDateTimeIssues() async {
    try {
      AppLogger.d('🔍 INICIANDO DIAGNÓSTICO COMPLETO DE DATE/TIME EN CHAT SERVICE...');
      
      // 1. Verificar estructura de la tabla messages
      final messagesSample = await _supabase
          .from('messages')
          .select('id, created_at, updated_at, read_at, delivered_at')
          .limit(3);
      
      AppLogger.d('📋 Mensajes muestra (primeros 3):');
      for (var msg in messagesSample) {
        AppLogger.d('   - ID: ${msg['id']}');
        AppLogger.d('     created_at: ${msg['created_at']} (tipo: ${msg['created_at'].runtimeType})');
        
        if (msg['read_at'] != null) {
          AppLogger.d('     read_at: ${msg['read_at']} (tipo: ${msg['read_at'].runtimeType})');
        } else {
          AppLogger.d('     read_at: null');
        }
        
        if (msg['delivered_at'] != null) {
          AppLogger.d('     delivered_at: ${msg['delivered_at']} (tipo: ${msg['delivered_at'].runtimeType})');
        } else {
          AppLogger.d('     delivered_at: null');
        }
      }
      
      // 2. Verificar metadata problemática
      final problematicMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .not('metadata', 'is', null)
          .limit(2);
      
      AppLogger.d('📋 Mensajes con metadata (primeros 2):');
      for (var msg in problematicMessages) {
        AppLogger.d('   - ID: ${msg['id']}');
        
        if (msg['metadata'] != null) {
          AppLogger.d('     metadata type: ${msg['metadata'].runtimeType}');
          
          if (msg['metadata'] is String) {
            final metadataString = msg['metadata'] as String;
            if (metadataString.isNotEmpty) {
              final endIndex = metadataString.length < 100 ? metadataString.length : 100;
              AppLogger.d('     metadata (string): ${metadataString.substring(0, endIndex)}...');
            } else {
              AppLogger.d('     metadata (string): (vacío)');
            }
          } else if (msg['metadata'] is Map) {
            AppLogger.d('     metadata (map): ${msg['metadata']}');
            TimeUtils.diagnoseJsonValue(msg['metadata'], 'metadata del mensaje ${msg['id']}');
          } else {
            AppLogger.d('     metadata (otro tipo): ${msg['metadata'].runtimeType}');
          }
        } else {
          AppLogger.d('     metadata: null');
        }
      }
      
      // 3. Verificar datos de chat
      AppLogger.d('📋 Verificando datos de chat...');
      final chatsSample = await _supabase
          .from('chats')
          .select('id, created_at, updated_at')
          .limit(2);
      
      for (var chat in chatsSample) {
        AppLogger.d('   - Chat ID: ${chat['id']}');
        AppLogger.d('     created_at: ${chat['created_at']} (tipo: ${chat['created_at'].runtimeType})');
        AppLogger.d('     updated_at: ${chat['updated_at']} (tipo: ${chat['updated_at'].runtimeType})');
      }
      
      AppLogger.d('✅ DIAGNÓSTICO COMPLETADO');
      
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Diagnóstico completo del servicio
  Future<Map<String, dynamic>> fullDiagnostic() async {
    try {
      AppLogger.d('🔍 INICIANDO DIAGNÓSTICO COMPLETO DEL CHAT SERVICE...');
      
      final results = {
        'timestamp': DateTime.now().toIso8601String(),
        'supabase_connection': false,
        'table_access': {},
        'active_streams': _messageStreams.length,
        'date_time_issues': [],
        'recommendations': [],
      };
      
      // 1. Verificar conexión a Supabase
      try {
        await _supabase.from('messages').select('count(*)').limit(1);
        results['supabase_connection'] = true;
        AppLogger.d('✅ Conexión Supabase: OK');
      } catch (e) {
        results['supabase_connection'] = false;
        // ignore: unused_local_variable
        var add = results['recommendations'].add('Verificar conexión a Supabase: $e');
        AppLogger.e('❌ Conexión Supabase: ERROR - $e');
      }
      
      // 2. Verificar acceso a tablas
      final tables = ['messages', 'chats', 'notifications'];
      for (final table in tables) {
        try {
          await _supabase.from(table).select('id').limit(1);
          var result = results['table_access'];
          var result2 = result;
          var result22 = result2;
          result22?[table] = true;
          AppLogger.d('✅ Acceso tabla $table: OK');
        } catch (e) {
          results['table_access'][table] = false;
          results['recommendations'].add('Tabla $table no accesible: $e');
          AppLogger.e('❌ Acceso tabla $table: ERROR - $e');
        }
      }
      
      // 3. Ejecutar diagnóstico DateTime
      await diagnoseDateTimeIssues();
      
      // 4. Verificar streams activos
      AppLogger.d('📊 Streams activos: ${results['active_streams']}');
      var newVariable = results['active_streams']! > 5;
      var newVariable2 = newVariable;
      var newVariable22 = newVariable2;
      var newVariable222 = newVariable22;
      var newVariable2222 = newVariable222;
      if (newVariable2222 != null) {
        results['recommendations'].add('Muchos streams activos (${
          results['active_streams']}). Considerar optimización.');
      }
      
      AppLogger.d('✅ DIAGNÓSTICO COMPLETO');
      results['success'] = true;
      results['message'] = 'Diagnóstico completado exitosamente';
      
      return results;
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico completo: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error durante el diagnóstico',
      };
    }
  }
}

extension on Object {
  // ignore: body_might_complete_normally_nullable
  Object? operator >(int other) {}
}

extension on Object? {
  // ignore: body_might_complete_normally_nullable
  Object? add(String s) {}
  
  void operator []=(String index, bool newValue) {}

}