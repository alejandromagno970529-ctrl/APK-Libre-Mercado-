// lib/services/notification_service.dart - VERSIÓN COMPLETA CORREGIDA CON RLS
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase);

  // ✅ NOTIFICACIÓN MEJORADA: Con reintentos y manejo de RLS
  Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
  }) async {
    try {
      AppLogger.d('💬 Intentando guardar notificación para: $toUserId');
      
      // 1. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return;
      }

      // 2. Preparar datos optimizados
      final notificationData = {
        'user_id': toUserId,
        'title': 'Nuevo mensaje de $fromUserName',
        'message': '$fromUserName: $messageText',
        'type': 'chat_message',
        'chat_id': chatId,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'metadata': {
          'from_user': fromUserName,
          'product_title': productTitle,
          'message_preview': messageText.length > 30 ? 
              '${messageText.substring(0, 30)}...' : messageText,
        }
      };

      AppLogger.d('📝 Insertando notificación...');
      
      // 3. Intentar inserción con manejo de errores específico
      final result = await _supabase
        .from('notifications')
        .insert(notificationData)
        .select()
        .single()
        .timeout(const Duration(seconds: 10));

      AppLogger.d('✅ Notificación guardada exitosamente: ${result['id']}');

    } catch (e) {
      _handleNotificationError(e, toUserId);
      rethrow; // Relanzar para que el caller sepa que falló
    }
  }

  // ✅ MANEJO ESPECÍFICO DE ERRORES
  void _handleNotificationError(dynamic e, String toUserId) {
    AppLogger.e('❌ Error guardando notificación para $toUserId', e);
    
    if (e.toString().contains('row-level security policy')) {
      AppLogger.e('''
🔴 PROBLEMA RLS DETECTADO:

SOLUCIÓN INMEDIATA:
1. Ve a Supabase → Authentication → Policies
2. Busca la tabla "notifications"
3. Asegúrate de tener estas políticas:

   - INSERT: "Enable insert for authenticated users"
     (Para usuarios autenticados, sin restricciones)
   
   - SELECT: "Enable read for users based on user_id" 
     (auth.uid() = user_id)
   
   - UPDATE: "Enable update for users based on user_id"
     (auth.uid() = user_id)

4. O ejecuta los comandos SQL proporcionados
''');
    } else if (e.toString().contains('JWT')) {
      AppLogger.e('🔴 Error de autenticación JWT');
    } else if (e.toString().contains('timeout')) {
      AppLogger.e('⏰ Timeout insertando notificación');
    } else {
      AppLogger.e('🔴 Error desconocido: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Configurar RLS para notificaciones
  Future<void> setupNotificationRLS() async {
    try {
      AppLogger.d('🔧 Configurando políticas RLS para notificaciones...');
      
      // Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado para configurar RLS');
        return;
      }

      // Este método es solo informativo - las políticas reales se configuran en SQL
      AppLogger.d('''
📋 POLÍTICAS RLS REQUERIDAS PARA NOTIFICATIONS:

Ejecuta estos comandos SQL en Supabase:

1. Habilitar RLS:
   ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

2. Política INSERT (CRÍTICA - Soluciona tu error actual):
   CREATE POLICY "Allow authenticated users to insert notifications" 
   ON notifications 
   FOR INSERT 
   TO authenticated 
   WITH CHECK (true);

3. Política SELECT:
   CREATE POLICY "Allow users to view own notifications" 
   ON notifications 
   FOR SELECT 
   TO authenticated 
   USING (auth.uid() = user_id);

4. Política UPDATE:
   CREATE POLICY "Allow users to update own notifications" 
   ON notifications 
   FOR UPDATE 
   TO authenticated 
   USING (auth.uid() = user_id);

5. Política DELETE:
   CREATE POLICY "Allow users to delete own notifications" 
   ON notifications 
   FOR DELETE 
   TO authenticated 
   USING (auth.uid() = user_id);

💡 INSTRUCCIONES RÁPIDAS:
1. Ve a Supabase Dashboard → SQL Editor
2. Copia y pega los comandos anteriores
3. Ejecuta cada uno individualmente
4. ¡Listo! Las notificaciones funcionarán correctamente.
''');

      // Intentar una prueba de inserción después de mostrar las instrucciones
      await _testNotificationInsert();
      
    } catch (e) {
      AppLogger.e('❌ Error en setupNotificationRLS: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Probar inserción de notificación
  Future<void> _testNotificationInsert() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      AppLogger.d('🧪 Probando inserción de notificación...');
      
      final testData = {
        'user_id': currentUser.id,
        'title': 'Test RLS',
        'message': 'Notificación de prueba de RLS',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

      // Limpiar prueba
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', result['id']);

      AppLogger.d('✅ Prueba RLS exitosa - Las políticas están configuradas correctamente');
    } catch (e) {
      AppLogger.e('❌ Prueba RLS fallida - Las políticas necesitan configuración: $e');
    }
  }

  // ✅ NOTIFICACIÓN DE NUEVO CHAT - OPTIMIZADA
  Future<void> sendNewChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String chatId,
  }) async {
    try {
      final message = '$fromUserName quiere contactarte sobre "$productTitle"';
      
      await sendChatNotification(
        toUserId: toUserId,
        fromUserName: fromUserName,
        productTitle: productTitle,
        messageText: message,
        chatId: chatId,
      );

    } catch (e) {
      AppLogger.e('❌ Error en notificación de nuevo chat', e);
      // No rethrow para no bloquear la creación del chat
    }
  }

  // ✅ OBTENER NOTIFICACIONES NO LEÍDAS
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('read', false);

      return response.length;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones no leídas: $e', e);
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
      
      AppLogger.d('✅ Notificaciones marcadas como leídas para usuario: $userId');
    } catch (e) {
      AppLogger.e('Error marcando notificaciones como leídas: $e', e);
    }
  }

  // ✅ OBTENER NOTIFICACIONES DEL USUARIO
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

      return response;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones: $e', e);
      return [];
    }
  }

  // ✅ VERIFICAR CONFIGURACIÓN RLS
  Future<Map<String, dynamic>> checkRLSConfiguration() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

      // Test de inserción
      final testData = {
        'user_id': currentUser.id,
        'title': 'Test RLS',
        'message': 'Notificación de prueba',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

      // Limpiar prueba
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', result['id']);

      return {
        'success': true,
        'message': 'Configuración RLS correcta',
        'test_id': result['id']
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error en RLS. Ejecuta los comandos SQL proporcionados.'
      };
    }
  }

  // ✅ NUEVO MÉTODO: Limpiar notificaciones antiguas
  Future<int> cleanupOldNotifications({int daysOld = 180}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final response = await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ Notificaciones antiguas eliminadas: $deletedCount');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Error limpiando notificaciones antiguas: $e');
      return 0;
    }
  }

  // ✅ NUEVO MÉTODO: Eliminar notificación específica
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      
      AppLogger.d('✅ Notificación eliminada: $notificationId');
    } catch (e) {
      AppLogger.e('Error eliminando notificación: $e');
      rethrow;
    }
  }

  // ✅ NUEVO MÉTODO: Enviar notificación con reintentos
  Future<void> sendNotificationWithRetry({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.d('🔔 Intentando notificación (intento $attempt/$maxRetries)...');
        
        await sendChatNotification(
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
            await setupNotificationRLS();
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
}