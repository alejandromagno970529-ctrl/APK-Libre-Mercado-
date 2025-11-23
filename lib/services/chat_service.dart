import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  ChatService(this._supabase);

  Stream<List<Message>> getMessagesStream(String chatId) {
    if (_messageStreams.containsKey(chatId)) {
      return _messageStreams[chatId]!.stream;
    }

    final controller = StreamController<List<Message>>();
    _messageStreams[chatId] = controller;

    _setupRealtimeMessages(chatId, controller);
    
    return controller.stream;
  }

  void _setupRealtimeMessages(String chatId, StreamController<List<Message>> controller) {
    try {
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
          .order('created_at', ascending: true);

      return (response as List)
          .map((data) => Message.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      AppLogger.e('Error cargando mensajes para chat $chatId', e);
      rethrow;
    }
  }

  // Public wrapper to load messages (allows other files to call it)
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

  Future<Message> sendMessageOptimistic({
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

    final response = await _supabase
        .from('messages')
        .insert(newMessage)
        .select()
        .single();

    await _supabase
        .from('chats')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    AppLogger.d('✅ Mensaje enviado y chat actualizado: $chatId');
    
    return Message.fromMap(response);
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