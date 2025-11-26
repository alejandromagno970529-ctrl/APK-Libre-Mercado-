import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/models/chat_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  ChatService(this._supabase);

  // ✅ NUEVO: Crear chat en la base de datos
  Future<Chat> createChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      AppLogger.d('🔄 Creando chat para producto: $productId');
      
      // Verificar si ya existe un chat para este producto y usuarios
      final existingChats = await _supabase
          .from('chats')
          .select()
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId);

      if (existingChats.isNotEmpty) {
        AppLogger.d('✅ Chat existente encontrado: ${existingChats.first['id']}');
        return Chat.fromMap(existingChats.first);
      }

      // Crear nuevo chat
      final newChat = {
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('chats')
          .insert(newChat)
          .select()
          .single();

      AppLogger.d('✅ Nuevo chat creado: ${response['id']}');
      return Chat.fromMap(response);
    } catch (e) {
      AppLogger.e('❌ Error creando chat', e);
      rethrow;
    }
  }

  // ✅ NUEVO: Obtener chats del usuario
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      AppLogger.d('🔄 Cargando chats para usuario: $userId');
      
      final response = await _supabase
          .from('chats')
          .select('''
            *,
            products:product_id (
              title,
              image_url,
              precio,
              moneda,
              disponible
            ),
            profiles:seller_id (
              username,
              avatar_url
            ),
            profiles:buyer_id (
              username, 
              avatar_url
            )
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('updated_at', ascending: false);

      final chats = (response as List).map((data) {
        final chat = Chat.fromMap(data);
        
        // Determinar el otro usuario y su información
        final isSeller = userId == chat.sellerId;
        final otherUserProfile = isSeller ? data['profiles_buyer'] : data['profiles_seller'];
        
        return chat.copyWith(
          otherUserName: otherUserProfile?['username'] as String?,
          otherUserAvatar: otherUserProfile?['avatar_url'] as String?,
        );
      }).toList();

      AppLogger.d('✅ ${chats.length} chats cargados');
      return chats;
    } catch (e) {
      AppLogger.e('❌ Error cargando chats', e);
      rethrow;
    }
  }

  Stream<List<Message>> getMessagesStream(String chatId) {
    if (_messageStreams.containsKey(chatId)) {
      return _messageStreams[chatId]!.stream;
    }

    final controller = StreamController<List<Message>>();
    _messageStreams[chatId] = controller;

    _setupRealtimeMessages(chatId, controller);
    
    return controller.stream;
  }

  void _setupRealtimeMessages(String chatId, StreamController<List<Message>> controller) async {
    try {
      // Cargar mensajes existentes primero
      try {
        final messages = await _loadMessages(chatId);
        controller.add(messages);
      } catch (e) {
        AppLogger.e('Error cargando mensajes iniciales', e);
      }

      _activeChannels[chatId]?.unsubscribe();

      final channel = _supabase.channel('messages:$chatId');
      
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: chatId
        ),
        callback: (payload) async {
          AppLogger.d('🔄 Evento realtime mensaje: ${payload.eventType}');
          
          try {
            final messages = await _loadMessages(chatId);
            controller.add(messages);
            
            _handleRealtimeEvent(payload, chatId);
          } catch (e) {
            AppLogger.e('Error procesando evento realtime', e);
          }
        }
      );

      channel.subscribe((status, [_]) {
        AppLogger.d('📡 Estado suscripción chat $chatId: $status');
        
        if (status == RealtimeSubscribeStatus.subscribed) {
          AppLogger.d('✅ Suscripción activa para chat: $chatId');
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          AppLogger.w('⏰ Timeout suscripción chat: $chatId - Reintentando...');
          _reconnectChannel(chatId);
        }
      });

      _activeChannels[chatId] = channel;

    } catch (e) {
      AppLogger.e('Error configurando realtime para chat $chatId', e);
      controller.addError(e);
    }
  }

  Future<List<Message>> _loadMessages(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Message.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      AppLogger.e('Error cargando mensajes para chat $chatId', e);
      rethrow;
    }
  }

  // Public wrapper to load messages
  Future<List<Message>> loadMessages(String chatId) async {
    return _loadMessages(chatId);
  }

  void _handleRealtimeEvent(PostgresChangePayload payload, String chatId) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        AppLogger.d('📨 Nuevo mensaje insertado en chat: $chatId');
        break;
      case PostgresChangeEvent.update:
        AppLogger.d('✏️ Mensaje actualizado en chat: $chatId');
        break;
      case PostgresChangeEvent.delete:
        AppLogger.d('🗑️ Mensaje eliminado en chat: $chatId');
        break;
      default:
        AppLogger.d('ℹ️ Evento realtime no manejado: ${payload.eventType} en chat: $chatId');
        break;
    }
  }

  void _reconnectChannel(String chatId) {
    AppLogger.d('🔄 Reconectando canal para chat: $chatId');
    
    final controller = _messageStreams[chatId];
    if (controller != null && !controller.isClosed) {
      Future.delayed(const Duration(seconds: 2), () {
        _setupRealtimeMessages(chatId, controller);
      });
    }
  }

  // ✅ Envía un mensaje de texto
  Future<Message> sendMessage({
    required String chatId,
    required String text,
    required String fromId,
  }) async {
    if (text.trim().isEmpty) {
      throw Exception('El mensaje no puede estar vacío');
    }

    final newMessage = {
      'chat_id': chatId,
      'text': text.trim(),
      'from_id': fromId,
      'created_at': DateTime.now().toIso8601String(),
      'read': false,
      'is_system': false,
    };

    try {
      final response = await _supabase
          .from('messages')
          .insert(newMessage)
          .select()
          .single();

      // Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje enviado y chat actualizado: $chatId');
      
      return Message.fromMap(response);
    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje', e);
      rethrow;
    }
  }

  // ✅ Envía un mensaje de archivo
  Future<Message> sendFileMessage({
    required String chatId,
    required String fromId,
    required String fileUrl,
    required String fileName,
    required String fileSize,
    required String mimeType,
  }) async {
    final newMessage = {
      'chat_id': chatId,
      'text': 'Archivo: $fileName',
      'from_id': fromId,
      'created_at': DateTime.now().toIso8601String(),
      'read': false,
      'is_system': false,
      'type': MessageType.file.name, // 👈 Usa .name (mejor práctica desde Dart 2.17+)
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
    };

    try {
      final response = await _supabase
          .from('messages')
          .insert(newMessage)
          .select()
          .single();

      // Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje de archivo enviado y chat actualizado: $chatId');
      
      return Message.fromMap(response);
    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje de archivo', e);
      rethrow;
    }
  }

  // ✅ Envía un mensaje de audio
  Future<Message> sendAudioMessage({
    required String chatId,
    required String fromId,
    required String audioUrl,
    required Duration duration,
  }) async {
    final newMessage = {
      'chat_id': chatId,
      'text': 'Audio: ${_formatDuration(duration)}',
      'from_id': fromId,
      'created_at': DateTime.now().toIso8601String(),
      'read': false,
      'is_system': false,
      'type': MessageType.audio.name, // 👈 Usa .name
      'file_url': audioUrl,
      'file_name': 'audio_message.m4a',
      'audio_duration': duration.inSeconds.toString(),
    };

    try {
      final response = await _supabase
          .from('messages')
          .insert(newMessage)
          .select()
          .single();

      // Actualizar timestamp del chat
      await _supabase
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);

      AppLogger.d('✅ Mensaje de audio enviado y chat actualizado: $chatId');
      
      return Message.fromMap(response);
    } catch (e) {
      AppLogger.e('❌ Error enviando mensaje de audio', e);
      rethrow;
    }
  }

  // ✅ Formatea una duración como MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _supabase
          .from('messages')
          .update({'read': true})
          .eq('chat_id', chatId)
          .neq('from_id', currentUserId)
          .eq('read', false);

      AppLogger.d('✅ Mensajes marcados como leídos en chat: $chatId');
    } catch (e) {
      AppLogger.e('Error marcando mensajes como leídos', e);
    }
  }

  void disposeChatStream(String chatId) {
    AppLogger.d('🧹 Limpiando recursos del chat: $chatId');
    
    _activeChannels[chatId]?.unsubscribe();
    _activeChannels.remove(chatId);
    
    _messageStreams[chatId]?.close();
    _messageStreams.remove(chatId);
  }

  void disposeAll() {
    AppLogger.d('🧹 Limpiando todos los recursos de ChatService');
    
    _activeChannels.forEach((chatId, channel) {
      channel.unsubscribe();
    });
    _activeChannels.clear();
    
    _messageStreams.forEach((chatId, controller) {
      controller.close();
    });
    _messageStreams.clear();
  }
}