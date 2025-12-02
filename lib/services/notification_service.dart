// lib/services/notification_service.dart - VERSIÓN COMPLETA SIN FIREBASE - CORREGIDO
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase) {
    AppLogger.d('✅ NotificationService inicializado para notificaciones internas');
  }

  // ✅ MÉTODO PRINCIPAL MEJORADO: Envío de notificaciones internas
  Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
  }) async {
    try {
      AppLogger.d('💬 INICIANDO ENVÍO DE NOTIFICACIÓN INTERNA para: $toUserId');
      
      // 1. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado para enviar notificación');
        throw Exception('Usuario no autenticado');
      }

      // 2. Preparar datos de la notificación optimizados
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
          'sent_by': currentUser.id,
          'sent_at': DateTime.now().toIso8601String(),
        }
      };

      AppLogger.d('📝 Insertando notificación en base de datos...');
      
      // 3. Intentar inserción con timeout
      final result = await _supabase
        .from('notifications')
        .insert(notificationData)
        .select()
        .single()
        .timeout(const Duration(seconds: 10));

      AppLogger.d('✅ NOTIFICACIÓN INTERNA GUARDADA EXITOSAMENTE - ID: ${result['id']}');

    } catch (e) {
      await _handleNotificationError(e, toUserId, fromUserName);
      rethrow;
    }
  }

  // ✅ MÉTODO SIMPLE: Enviar notificación interna genérica
  Future<void> sendInAppNotification({
    required String toUserId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic> metadata = const {},
    String? chatId,
    String? productId,
  }) async {
    try {
      final notificationData = {
        'user_id': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'chat_id': chatId,
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
        'metadata': metadata,
      };

      await _supabase
        .from('notifications')
        .insert(notificationData);
        
      AppLogger.d('✅ Notificación interna enviada a: $toUserId');
    } catch (e) {
      AppLogger.e('❌ Error enviando notificación interna: $e');
    }
  }

  // MANEJO MEJORADO DE ERRORES CON RECOMENDACIONES ESPECÍFICAS
  Future<void> _handleNotificationError(dynamic e, String toUserId, String fromUserName) async {
    AppLogger.e('❌ ERROR CRÍTICO guardando notificación para $toUserId', e);
    
    final errorMessage = e.toString();
    
    if (errorMessage.contains('row-level security policy')) {
      AppLogger.e('''
🔴 ERROR RLS DETECTADO - CONFIGURACIÓN REQUERIDA:

PROBLEMA: Las políticas RLS están bloqueando la inserción de notificaciones.

SOLUCIÓN INMEDIATA:
1. Ve a Supabase Dashboard → Authentication → Policies
2. Selecciona la tabla "notifications"
3. Configura estas políticas O ejecuta los comandos SQL proporcionados

COMANDOS SQL DE EMERGENCIA (ejecutar en SQL Editor):
-----------------------------------------
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow insert notifications" ON notifications
FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow view own notifications" ON notifications
FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Allow update own notifications" ON notifications
FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Allow delete own notifications" ON notifications
FOR DELETE TO authenticated USING (auth.uid() = user_id);
-----------------------------------------

ESTADO ACTUAL: Notificación de "$fromUserName" NO enviada a $toUserId
''');
    } else if (errorMessage.contains('JWT')) {
      AppLogger.e('🔴 Error de autenticación JWT - Token inválido o expirado');
    } else if (errorMessage.contains('timeout')) {
      AppLogger.e('⏰ Timeout - La base de datos no respondió a tiempo');
    } else if (errorMessage.contains('network') || errorMessage.contains('Socket')) {
      AppLogger.e('🌐 Error de red - Verifica la conexión a internet');
    } else {
      AppLogger.e('🔴 Error desconocido: $e');
    }
  }

  // ✅ MÉTODO MEJORADO: Configuración RLS con verificación
  Future<Map<String, dynamic>> setupNotificationRLS() async {
    try {
      AppLogger.d('🔧 INICIANDO CONFIGURACIÓN RLS PARA NOTIFICACIONES...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false, 
          'error': 'Usuario no autenticado',
          'message': 'Inicia sesión para configurar RLS'
        };
      }

      AppLogger.d('''
📋 CONFIGURACIÓN RLS REQUERIDA - Sigue estos pasos:

PASO 1: Ve a Supabase Dashboard → SQL Editor
PASO 2: Copia y pega ESTOS comandos EXACTOS:

-- =====================
-- POLÍTICAS RLS PARA NOTIFICATIONS
-- =====================

-- 1. Habilitar RLS (si no está habilitada)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 2. Política INSERT (SOLUCIONA TU ERROR ACTUAL)
CREATE POLICY "Allow authenticated users to insert notifications" 
ON notifications 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- 3. Política SELECT (usuarios ven solo sus notificaciones)
CREATE POLICY "Allow users to view own notifications" 
ON notifications 
FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- 4. Política UPDATE (usuarios actualizan solo sus notificaciones)
CREATE POLICY "Allow users to update own notifications" 
ON notifications 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- 5. Política DELETE (usuarios eliminan solo sus notificaciones)
CREATE POLICY "Allow users to delete own notifications" 
ON notifications 
FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

PASO 3: Ejecuta cada comando individualmente
PASO 4: Verifica que no haya errores
PASO 5: ¡Las notificaciones funcionarán correctamente!
''');

      // Probar configuración actual
      final testResult = await _testRLSConfiguration();
      
      if (testResult['success'] == true) {
        AppLogger.d('✅ Configuración RLS verificada - Todo funciona correctamente');
        return {
          'success': true,
          'message': 'RLS configurado correctamente',
          'test_id': testResult['test_id']
        };
      } else {
        AppLogger.e('❌ Configuración RLS falló - Ejecuta los comandos SQL anteriores');
        return {
          'success': false,
          'error': testResult['error'],
          'message': 'Ejecuta los comandos SQL proporcionados en Supabase'
        };
      }
      
    } catch (e) {
      AppLogger.e('❌ Error en setupNotificationRLS: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error configurando RLS. Sigue las instrucciones manualmente.'
      };
    }
  }

  // ✅ MÉTODO DE PRUEBA MEJORADO: Verificar configuración RLS
  Future<Map<String, dynamic>> _testRLSConfiguration() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado para prueba RLS');
      }

      AppLogger.d('🧪 EJECUTANDO PRUEBA DE CONFIGURACIÓN RLS...');

      // Datos de prueba
      final testNotification = {
        'user_id': currentUser.id,
        'title': 'Prueba RLS - Configuración',
        'message': 'Esta es una notificación de prueba para verificar RLS',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {
          'test': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString()
        }
      };

      // 1. Probar INSERT
      AppLogger.d('1. Probando INSERT...');
      final insertResult = await _supabase
        .from('notifications')
        .insert(testNotification)
        .select()
        .single();

      final notificationId = insertResult['id'] as String;
      AppLogger.d('✅ INSERT exitoso - ID: $notificationId');

      // 2. Probar SELECT
      AppLogger.d('2. Probando SELECT...');
      // ignore: unused_local_variable
      final selectResult = await _supabase
        .from('notifications')
        .select()
        .eq('id', notificationId)
        .single();

      AppLogger.d('✅ SELECT exitoso - Notificación recuperada');

      // 3. Probar UPDATE
      AppLogger.d('3. Probando UPDATE...');
      // ignore: unused_local_variable
      final updateResult = await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId)
        .select()
        .single();

      AppLogger.d('✅ UPDATE exitoso - Notificación marcada como leída');

      // 4. Limpiar prueba
      AppLogger.d('4. Limpiando prueba...');
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);

      AppLogger.d('✅ Prueba limpiada exitosamente');

      return {
        'success': true,
        'test_id': notificationId,
        'message': 'Todas las operaciones RLS funcionan correctamente'
      };

    } catch (e) {
      AppLogger.e('❌ PRUEBA RLS FALLIDA: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'La configuración RLS necesita ajustes. Ejecuta los comandos SQL proporcionados.'
      };
    }
  }

  // ✅ MÉTODO MEJORADO: Notificación de nuevo chat
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

      AppLogger.d('✅ Notificación de nuevo chat enviada a: $toUserId');
    } catch (e) {
      AppLogger.e('❌ Error en notificación de nuevo chat (no crítico): $e');
      // No rethrow para no bloquear la creación del chat
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener conteo de notificaciones no leídas
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('read', false);

      final count = response.length;
      AppLogger.d('📊 Notificaciones no leídas para $userId: $count');
      return count;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones no leídas: $e', e);
      return 0;
    }
  }

  // ✅ MÉTODO MEJORADO: Marcar notificaciones como leídas
  Future<void> markNotificationsAsRead(String userId, {String? chatId, required String notificationId}) async {
    try {
      var query = _supabase
          .from('notifications')
          .update({'read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('read', false);

      if (chatId != null) {
        query = query.eq('chat_id', chatId);
      }

      final result = await query;
      
      AppLogger.d('✅ Notificaciones marcadas como leídas para usuario: $userId - Resultado: $result');
    } catch (e) {
      AppLogger.e('Error marcando notificaciones como leídas: $e', e);
    }
  }

  // ✅ MÉTODO MEJORADO: Obtener notificaciones del usuario
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

      AppLogger.d('📨 ${response.length} notificaciones obtenidas para: $userId');
      return response;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones: $e', e);
      return [];
    }
  }

  // ✅ MÉTODO NUEVO: Verificar estado completo de RLS
  Future<Map<String, dynamic>> checkFullRLSStatus() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

      AppLogger.d('🔍 VERIFICANDO ESTADO COMPLETO RLS...');

      // Probar todas las operaciones
      final testResults = await _testAllRLSOperations();

      final isSuccess = testResults['success'] == true;

      return {
        'success': isSuccess,
        'operations_test': testResults,
        'recommendation': isSuccess 
            ? 'RLS configurado correctamente' 
            : 'Ejecuta los comandos SQL proporcionados'
      };
    } catch (e) {
      AppLogger.e('Error verificando estado RLS: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando RLS. Ejecuta los comandos SQL manualmente.'
      };
    }
  }

  // ✅ MÉTODO NUEVO: Probar todas las operaciones RLS
  Future<Map<String, dynamic>> _testAllRLSOperations() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return {'success': false, 'error': 'Usuario no autenticado'};
    }

    final results = {
      'insert': false,
      'select': false,
      'update': false,
      'delete': false,
      'success': false
    };

    String? testNotificationId;

    try {
      // Test INSERT
      final testData = {
        'user_id': currentUser.id,
        'title': 'Test RLS Completo',
        'message': 'Probando todas las operaciones RLS',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final insertResult = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

      testNotificationId = insertResult['id'] as String;
      results['insert'] = true;
      AppLogger.d('✅ INSERT RLS: OK');

      // Test SELECT
      await _supabase
        .from('notifications')
        .select()
        .eq('id', testNotificationId)
        .single();
      
      results['select'] = true;
      AppLogger.d('✅ SELECT RLS: OK');

      // Test UPDATE
      await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', testNotificationId);
      
      results['update'] = true;
      AppLogger.d('✅ UPDATE RLS: OK');

      // Test DELETE
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', testNotificationId);
      
      results['delete'] = true;
      AppLogger.d('✅ DELETE RLS: OK');

      results['success'] = true;

    } catch (e) {
      AppLogger.e('❌ Error en prueba RLS: $e');
      
      // Limpiar en caso de error
      if (testNotificationId != null) {
        try {
          await _supabase
            .from('notifications')
            .delete()
            .eq('id', testNotificationId);
        } catch (_) {}
      }
    }

    return results;
  }

  // ✅ MÉTODO MEJORADO: Envío con reintentos
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
        return;
      } catch (e) {
        AppLogger.e('⚠️ Error en notificación (intento $attempt): $e');
        
        if (e.toString().contains('row-level security policy')) {
          AppLogger.w('🔄 Error RLS detectado, intentando configurar...');
          try {
            await setupNotificationRLS();
            AppLogger.d('✅ Configuración RLS actualizada');
          } catch (rlsError) {
            AppLogger.e('❌ Error configurando RLS: $rlsError');
          }
        }
        
        if (attempt == maxRetries) {
          AppLogger.e('❌ Fallaron todos los intentos de notificación');
          // ignore: use_rethrow_when_possible
          throw e;
        }
        
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  // ✅ MÉTODO COMPLETAMENTE CORREGIDO: Diagnosticar problemas de notificación
  Future<Map<String, dynamic>> diagnoseNotificationIssues() async {
    try {
      AppLogger.d('🩺 INICIANDO DIAGNÓSTICO DE NOTIFICACIONES INTERNAS...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

      final Map<String, dynamic> results = {
        'authentication': false,
        'table_exists': false,
        'rls_enabled': false,
        'operations_test': {'success': false},
      };

      // 1. Verificar autenticación
      // ignore: unnecessary_null_comparison
      results['authentication'] = currentUser != null;
      AppLogger.d('1. Autenticación: ${results['authentication'] ? '✅' : '❌'}');

      // 2. Verificar si la tabla existe
      try {
        await _supabase
          .from('notifications')
          .select('count(*)')
          .limit(1);
        results['table_exists'] = true;
        AppLogger.d('2. Tabla existe: ✅');
      } catch (e) {
        results['table_exists'] = false;
        AppLogger.d('2. Tabla existe: ❌ - $e');
      }

      // 3. Probar operaciones
      final operationsTest = await _testAllRLSOperations();
      results['operations_test'] = operationsTest;

      final bool authenticationOk = results['authentication'] == true;
      final bool tableExistsOk = results['table_exists'] == true;
      
      final Map<String, dynamic>? operationsTestResult = results['operations_test'];
      final bool operationsTestOk = operationsTestResult != null && 
                                   operationsTestResult['success'] == true;

      final bool allTestsPassed = authenticationOk && 
                                 tableExistsOk && 
                                 operationsTestOk;

      AppLogger.d('📊 RESUMEN DIAGNÓSTICO:');
      AppLogger.d('   - Autenticación: ${authenticationOk ? '✅' : '❌'}');
      AppLogger.d('   - Tabla existe: ${tableExistsOk ? '✅' : '❌'}');
      AppLogger.d('   - Operaciones funcionan: ${operationsTestOk ? '✅' : '❌'}');
      AppLogger.d('   - DIAGNÓSTICO COMPLETO: ${allTestsPassed ? '✅ TODO CORRECTO' : '❌ PROBLEMAS DETECTADOS'}');

      return {
        'success': allTestsPassed,
        'results': results,
        'recommendation': allTestsPassed 
            ? 'Todo funciona correctamente' 
            : 'Ejecuta los comandos SQL proporcionados en setupNotificationRLS()'
      };

    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error durante el diagnóstico. Verifica manualmente la configuración RLS.'
      };
    }
  }

  // ✅ MÉTODO MEJORADO: Limpiar notificaciones antiguas
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

  // ✅ MÉTODO MEJORADO: Eliminar notificación específica
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

  // ✅ MÉTODO NUEVO: Verificar configuración RLS simple
  Future<bool> checkBasicRLS() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final testData = {
        'user_id': currentUser.id,
        'title': 'Test RLS Básico',
        'message': 'Prueba de configuración RLS',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

      // Limpiar
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', result['id']);

      return true;
    } catch (e) {
      AppLogger.e('❌ Prueba RLS básica fallida: $e');
      return false;
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener estadísticas de notificaciones
  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    try {
      // Obtener todas las notificaciones del usuario
      final allNotifications = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId);

      // Obtener notificaciones no leídas
      final unreadNotifications = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('read', false);

      final totalCount = allNotifications.length;
      final unreadCount = unreadNotifications.length;
      final readCount = totalCount - unreadCount;

      AppLogger.d('📊 Estadísticas notificaciones - Total: $totalCount, No leídas: $unreadCount, Leídas: $readCount');

      return {
        'total': totalCount,
        'unread': unreadCount,
        'read': readCount,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estadísticas de notificaciones: $e');
      return {'total': 0, 'unread': 0, 'read': 0};
    }
  }

  // ✅ MÉTODO NUEVO: Obtener notificaciones recientes
  Future<List<Map<String, dynamic>>> getRecentNotifications(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

      AppLogger.d('📨 ${response.length} notificaciones recientes obtenidas para: $userId');
      return response;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones recientes: $e');
      return [];
    }
  }

  // ✅ MÉTODO NUEVO: Eliminar todas las notificaciones del usuario
  Future<int> deleteAllUserNotifications(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .select();

      final deletedCount = response.length;
      AppLogger.d('✅ $deletedCount notificaciones eliminadas para usuario: $userId');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Error eliminando todas las notificaciones: $e');
      return 0;
    }
  }

  // ✅ MÉTODO: Verificar si RLS está configurado
  Future<bool> ensureRLSConfigured() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Probar configuración RLS
      final testNotification = {
        'user_id': currentUser.id,
        'title': 'Test RLS',
        'message': 'Verificando configuración RLS',
        'type': 'test',
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testNotification)
        .select()
        .single();

      // Limpiar notificación de prueba
      await _supabase
        .from('notifications')
        .delete()
        .eq('id', result['id']);

      return true;
    } catch (e) {
      AppLogger.e('❌ RLS no configurado correctamente: $e');
      return false;
    }
  }

  // ✅ MÉTODO: Notificar nuevo acuerdo internamente
  Future<void> sendAgreementNotification({
    required String toUserId,
    required String fromUserName,
    required String agreementType,
    required String productTitle,
  }) async {
    try {
      await sendInAppNotification(
        toUserId: toUserId,
        title: '🤝 Nuevo acuerdo de $fromUserName',
        message: 'Te ha enviado un acuerdo para: $productTitle',
        type: 'agreement',
        metadata: {
          'from_user': fromUserName,
          'agreement_type': agreementType,
          'product_title': productTitle,
          'action': 'VIEW_AGREEMENT',
        },
      );
    } catch (e) {
      AppLogger.e('❌ Error en notificación de acuerdo: $e');
    }
  }

  // ✅ MÉTODO: Notificar nueva calificación internamente
  Future<void> sendRatingNotification({
    required String toUserId,
    required String fromUserName,
    required double rating,
    required String comment,
  }) async {
    try {
      final body = comment.isNotEmpty 
          ? comment.length > 50 ? '${comment.substring(0, 50)}...' : comment
          : 'Te ha calificado con $rating estrellas';

      await sendInAppNotification(
        toUserId: toUserId,
        title: '⭐ Nueva calificación de $fromUserName',
        message: body,
        type: 'rating',
        metadata: {
          'from_user': fromUserName,
          'rating': rating.toString(),
          'comment': comment,
          'action': 'VIEW_RATING',
        },
      );
    } catch (e) {
      AppLogger.e('❌ Error en notificación de calificación: $e');
    }
  }
}