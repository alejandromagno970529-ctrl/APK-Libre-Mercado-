// lib/services/notification_service.dart - VERSIÓN SIN TWILIO
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  // ✅ NOTIFICACIÓN SIMPLIFICADA - SOLO GUARDAR EN BASE DE DATOS
  Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
  }) async {
    try {
      AppLogger.d('💬 Guardando notificación para: $toUserId');
      
      // 1. Guardar notificación en la base de datos
      await _supabase.from('notifications').insert({
        'user_id': toUserId,
        'title': 'Nuevo mensaje de $fromUserName',
        'message': '$fromUserName: "$messageText" (Producto: "$productTitle")',
        'type': 'chat_message',
        'chat_id': chatId,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'metadata': {
          'from_user': fromUserName,
          'product_title': productTitle,
          'message_preview': messageText.length > 50 ? 
              '${messageText.substring(0, 50)}...' : messageText,
        }
      });

      AppLogger.d('✅ Notificación guardada para $toUserId');

    } catch (e) {
      AppLogger.e('❌ Error guardando notificación', e);
      // No rethrow para no bloquear el chat
    }
  }

  // ✅ NOTIFICACIÓN DE NUEVO CHAT
  Future<void> sendNewChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String chatId,
  }) async {
    try {
      final message = '$fromUserName quiere contactarte por tu producto "$productTitle"';
      
      await sendChatNotification(
        toUserId: toUserId,
        fromUserName: fromUserName,
        productTitle: productTitle,
        messageText: message,
        chatId: chatId,
      );

      AppLogger.d('✅ Notificación de nuevo chat guardada');

    } catch (e) {
      AppLogger.e('❌ Error enviando notificación de nuevo chat', e);
    }
  }

  // ✅ OBTENER NOTIFICACIONES NO LEÍDAS
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
    .from('notifications')
    .select()  // ✅ CORRECCIÓN: Eliminar el parámetro 'count'
    .eq('user_id', userId)
    .eq('read', false);

      return response.length;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones no leídas', e);
      return 0;
    }
  }

  // ✅ MARCAR NOTIFICACIONES COMO LEÍDAS
  Future<void> markNotificationsAsRead(String userId, {String? chatId}) async {
    try {
      var query = _supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);

      if (chatId != null) {
        query = query.eq('chat_id', chatId);
      }

      await query;
      
      AppLogger.d('✅ Notificaciones marcadas como leídas');
    } catch (e) {
      AppLogger.e('Error marcando notificaciones como leídas', e);
    }
  }
}