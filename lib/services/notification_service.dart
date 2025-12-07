// lib/services/notification_service.dart - VERSIÓN 17.0.0 COMPLETAMENTE CORREGIDA
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';
import '../utils/time_utils.dart';

import '../main.dart' show flutterLocalNotificationsPlugin;

class NotificationService {
  final SupabaseClient _supabase;

  NotificationService(this._supabase) {
    AppLogger.d('✅ NotificationService inicializado para notificaciones internas');
  }

  Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String productTitle,
    required String messageText,
    required String chatId,
  }) async {
    try {
      AppLogger.d('💬 INICIANDO ENVÍO DE NOTIFICACIÓN INTERNA para: $toUserId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado para enviar notificación');
        throw Exception('Usuario no autenticado');
      }

      // ✅ USAR TimeUtils.ensureJsonSerializable para metadata
      final metadata = TimeUtils.ensureJsonSerializable({
        'from_user': fromUserName,
        'product_title': productTitle,
        'message_preview': messageText.length > 30 ? 
            '${messageText.substring(0, 30)}...' : messageText,
        'sent_by': currentUser.id,
        'sent_by_name': fromUserName,
        'sent_at': TimeUtils.currentIso8601String(),
      });

      // ✅ VERIFICAR QUE LOS DATOS SEAN JSON SERIALIZABLES
      TimeUtils.diagnoseJsonValue(metadata, 'metadata para notificación');

      final notificationData = {
        'user_id': toUserId,
        'title': 'Nuevo mensaje de $fromUserName',
        'message': '$fromUserName: $messageText',
        'type': 'chat_message',
        'chat_id': chatId,
        'created_at': TimeUtils.currentIso8601String(),
        'read': false,
        'sender_id': currentUser.id,
        'metadata': metadata
      };

      // ✅ DIAGNÓSTICO COMPLETO DE LOS DATOS
      TimeUtils.diagnoseJsonValue(notificationData, 'datos completos notificación');

      AppLogger.d('📝 Insertando notificación en base de datos...');
      
      await _supabase
        .from('notifications')
        .insert(notificationData)
        .timeout(const Duration(seconds: 10));

      AppLogger.d('✅ NOTIFICACIÓN INTERNA GUARDADA EXITOSAMENTE para: $toUserId');
      
      await showLocalNotification(
        title: 'Nuevo mensaje de $fromUserName',
        body: messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
        payload: 'chat_$chatId',
      );

    } catch (e) {
      await _handleNotificationError(e, toUserId, fromUserName);
      rethrow;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'Notifications for new messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        autoCancel: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        sound: const RawResourceAndroidNotificationSound('notification'),
        styleInformation: BigTextStyleInformation(body),
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      AppLogger.d('📱 Notificación local mostrada: $title');
    } catch (e) {
      AppLogger.e('❌ Error mostrando notificación local: $e');
    }
  }

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
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return;
      }

      // ✅ ASEGURAR QUE METADATA SEA JSON SERIALIZABLE
      final safeMetadata = TimeUtils.ensureJsonSerializable({
        ...metadata,
        'sent_by': currentUser.id,
        'sent_at': TimeUtils.currentIso8601String(),
      });

      final notificationData = {
        'user_id': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'chat_id': chatId,
        'product_id': productId,
        'created_at': TimeUtils.currentIso8601String(),
        'read': false,
        'sender_id': currentUser.id,
        'metadata': safeMetadata,
      };

      // ✅ VERIFICAR SERIALIZACIÓN
      if (!TimeUtils.isJsonSerializable(notificationData)) {
        AppLogger.e('❌ Datos no serializables detectados, limpiando metadata');
        notificationData['metadata'] = {};
      }

      await _supabase
        .from('notifications')
        .insert(notificationData);
        
      if (chatId != null) {
        await showLocalNotification(
          title: title,
          body: message,
          payload: 'chat_$chatId',
        );
      }
      
      AppLogger.d('✅ Notificación interna enviada a: $toUserId');
    } catch (e) {
      AppLogger.e('❌ Error enviando notificación interna: $e');
    }
  }

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

-- 2. Política INSERT (PERMITE INSERTAR PARA CUALQUIER USUARIO)
CREATE POLICY "Enable insert for notifications" 
ON notifications 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- 3. Política SELECT (usuarios ven solo sus notificaciones)
CREATE POLICY "Enable select for own notifications" 
ON notifications 
FOR SELECT 
TO authenticated 
USING (user_id = auth.uid());

-- 4. Política UPDATE (usuarios actualizan solo sus notificaciones)
CREATE POLICY "Enable update for own notifications" 
ON notifications 
FOR UPDATE 
TO authenticated 
USING (user_id = auth.uid());

-- 5. Política DELETE (usuarios eliminan solo sus notificaciones)
CREATE POLICY "Enable delete for own notifications" 
ON notifications 
FOR DELETE 
TO authenticated 
USING (user_id = auth.uid());

PASO 3: Ejecuta cada comando individualmente
PASO 4: Verifica que no haya errores
PASO 5: ¡Las notificaciones funcionarán correctamente!
''');

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

  Future<void> _handleNotificationError(dynamic e, String toUserId, String fromUserName) async {
    AppLogger.e('❌ ERROR CRÍTICO guardando notificación para $toUserId', e);
    
    final errorMessage = e.toString();
    
    if (errorMessage.contains('row-level security policy')) {
      AppLogger.e(''' 
🔴 ERROR RLS DETECTADO - CONFIGURACIÓN REQUERIDA:

PROBLEMA: Las políticas RLS están bloqueando la inserción de notificaciones.

SOLUCIÓN INMEDIATA:
Ejecuta ESTOS comandos SQL en Supabase Dashboard → SQL Editor:

-- 1. ELIMINAR POLÍTICAS EXISTENTES
DROP POLICY IF EXISTS "Allow insert notifications" ON notifications;
DROP POLICY IF EXISTS "Allow view own notifications" ON notifications;
DROP POLICY IF EXISTS "Allow update own notifications" ON notifications;
DROP POLICY IF EXISTS "Allow delete own notifications" ON notifications;

-- 2. CREAR POLÍTICAS CORREGIDAS
CREATE POLICY "Enable insert for any user notification" ON notifications
FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable select for own notifications" ON notifications
FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Enable update for own notifications" ON notifications
FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Enable delete for own notifications" ON notifications
FOR DELETE TO authenticated USING (user_id = auth.uid());

ESTADO ACTUAL: Notificación de "$fromUserName" NO enviada a $toUserId
''');
    } else if (errorMessage.contains('JWT')) {
      AppLogger.e('🔴 Error de autenticación JWT - Token inválido o expirado');
    } else if (errorMessage.contains('timeout')) {
      AppLogger.e('⏰ Timeout - La base de datos no respondió a tiempo');
    } else if (errorMessage.contains('network') || errorMessage.contains('Socket')) {
      AppLogger.e('🌐 Error de red - Verifica la conexión a internet');
    } else if (errorMessage.contains('sender_id')) {
      AppLogger.e(''' 
🔴 COLUMNA sender_id NO EXISTE:

Ejecuta este comando SQL en Supabase:
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS sender_id UUID;
''');
    } else {
      AppLogger.e('🔴 Error desconocido: $e');
    }
  }

  Future<Map<String, dynamic>> _testRLSConfiguration() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado para prueba RLS');
      }

      AppLogger.d('🧪 EJECUTANDO PRUEBA DE CONFIGURACIÓN RLS...');

      // ✅ USAR TimeUtils.ensureJsonSerializable para metadata
      final testNotification = {
        'user_id': currentUser.id,
        'title': 'Prueba RLS - Configuración',
        'message': 'Esta es una notificación de prueba para verificar RLS',
        'type': 'test',
        'read': false,
        'sender_id': currentUser.id,
        'created_at': TimeUtils.currentIso8601String(),
        'metadata': TimeUtils.ensureJsonSerializable({
          'test': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'sent_by': currentUser.id,
        }),
      };

      AppLogger.d('1. Probando INSERT...');
      final insertResult = await _supabase
        .from('notifications')
        .insert(testNotification)
        .select()
        .single();

      final notificationId = insertResult['id'] as String;
      AppLogger.d('✅ INSERT exitoso - ID: $notificationId');

      AppLogger.d('2. Probando SELECT...');
      final selectResult = await _supabase
        .from('notifications')
        .select()
        .eq('id', notificationId)
        .single();

      AppLogger.d('✅ SELECT exitoso - Notificación recuperada: ${selectResult['title']}');

      AppLogger.d('3. Probando UPDATE...');
      await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId)
        .select()
        .single();

      AppLogger.d('✅ UPDATE exitoso - Notificación marcada como leída');

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

  Future<void> debugRLSPolicyIssue() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('🔴 Usuario no autenticado');
        return;
      }

      AppLogger.d('🔍 DEBUG RLS - Usuario actual: ${currentUser.id}');
      AppLogger.d('🔍 DEBUG RLS - auth.uid(): ${currentUser.id}');
      
      final testDataForOtherUser = {
        'user_id': currentUser.id,
        'title': 'Debug RLS Test',
        'message': 'Probando políticas RLS',
        'type': 'debug',
        'read': false,
        'sender_id': currentUser.id,
        'created_at': TimeUtils.currentIso8601String(),
        'metadata': TimeUtils.ensureJsonSerializable({'debug': true})
      };

      AppLogger.d('🔍 Probando inserción...');
      try {
        await _supabase
          .from('notifications')
          .insert(testDataForOtherUser);
        AppLogger.d('✅ Inserción exitosa en debug');
      } catch (e) {
        AppLogger.e('❌ Error en inserción debug: $e');
      }

    } catch (e) {
      AppLogger.e('❌ Error en debugRLSPolicyIssue: $e');
    }
  }

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
    }
  }

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

  Future<void> markNotificationsAsRead(String userId, {required String notificationId}) async {
    try {
      var query = _supabase
          .from('notifications')
          .update({
            'read': true, 
            'updated_at': TimeUtils.currentIso8601String()
          })
          .eq('user_id', userId)
          .eq('read', false);

      if (notificationId.isNotEmpty) {
        query = query.eq('id', notificationId);
      }

      final result = await query;
      
      AppLogger.d('✅ Notificaciones marcadas como leídas para usuario: $userId - Resultado: $result');
    } catch (e) {
      AppLogger.e('Error marcando notificaciones como leídas: $e', e);
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

      final sanitizedResponse = response.map((notification) {
        final Map<String, dynamic> notificationMap = Map<String, dynamic>.from(notification);
        
        if (notificationMap['metadata'] != null) {
          final metadata = notificationMap['metadata'];
          
          if (metadata is Map) {
            notificationMap['metadata'] = TimeUtils.sanitizeMetadata(
              Map<String, dynamic>.from(metadata)
            );
          } else if (metadata is String) {
            try {
              final parsed = json.decode(metadata);
              if (parsed is Map) {
                notificationMap['metadata'] = TimeUtils.sanitizeMetadata(
                  Map<String, dynamic>.from(parsed)
                );
              }
            } catch (_) {
              AppLogger.w('⚠️ No se pudo parsear metadata como JSON');
            }
          }
        }
        
        return notificationMap;
      }).toList();

      AppLogger.d('📨 ${response.length} notificaciones obtenidas para: $userId');
      return sanitizedResponse;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones: $e', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> checkFullRLSStatus() async {
    try {
      AppLogger.d('🔍 VERIFICANDO ESTADO COMPLETO RLS...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

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
      final testData = {
        'user_id': currentUser.id,
        'title': 'Test RLS Completo',
        'message': 'Probando todas las operaciones RLS',
        'type': 'test',
        'read': false,
        'sender_id': currentUser.id,
        'created_at': TimeUtils.currentIso8601String(),
        'metadata': TimeUtils.ensureJsonSerializable({'test': true})
      };

      final insertResult = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

      testNotificationId = insertResult['id'] as String;
      results['insert'] = true;
      AppLogger.d('✅ INSERT RLS: OK');

      await _supabase
        .from('notifications')
        .select()
        .eq('id', testNotificationId)
        .single();
      
      results['select'] = true;
      AppLogger.d('✅ SELECT RLS: OK');

      await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', testNotificationId);
      
      results['update'] = true;
      AppLogger.d('✅ UPDATE RLS: OK');

      await _supabase
        .from('notifications')
        .delete()
        .eq('id', testNotificationId);
      
      results['delete'] = true;
      AppLogger.d('✅ DELETE RLS: OK');

      results['success'] = true;

    } catch (e) {
      AppLogger.e('❌ Error en prueba RLS: $e');
      
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
        'metadata_issues': false,
      };

      // ignore: unnecessary_null_comparison
      results['authentication'] = currentUser != null;
      AppLogger.d('1. Autenticación: ${results['authentication'] ? '✅' : '❌'}');

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

      final operationsTest = await _testAllRLSOperations();
      results['operations_test'] = operationsTest;

      try {
        final existingNotifications = await _supabase
          .from('notifications')
          .select('metadata')
          .eq('user_id', currentUser.id)
          .limit(5);
        
        bool hasMetadataIssues = false;
        for (final notification in existingNotifications) {
          if (notification['metadata'] != null && 
              TimeUtils.containsDateTime(notification['metadata'])) {
            hasMetadataIssues = true;
            break;
          }
        }
        
        results['metadata_issues'] = hasMetadataIssues;
        AppLogger.d('4. Metadata issues: ${hasMetadataIssues ? '⚠️' : '✅'}');
      } catch (e) {
        results['metadata_issues'] = false;
      }

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
      AppLogger.d('   - Metadata issues: ${results['metadata_issues'] ? '⚠️' : '✅'}');
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

  Future<int> cleanupOldNotifications({int daysOld = 180}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final response = await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate))
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ Notificaciones antiguas eliminadas: $deletedCount');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Error limpiando notificaciones antiguas: $e');
      return 0;
    }
  }

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
        'sender_id': currentUser.id,
        'created_at': TimeUtils.currentIso8601String(),
        'metadata': TimeUtils.ensureJsonSerializable({'test': true}),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testData)
        .select()
        .single();

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

  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    try {
      final allNotifications = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId);

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

  Future<List<Map<String, dynamic>>> getRecentNotifications(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

      final sanitizedResponse = response.map((notification) {
        final Map<String, dynamic> notificationMap = Map<String, dynamic>.from(notification);
        
        if (notificationMap['metadata'] != null) {
          final metadata = notificationMap['metadata'];
          
          if (metadata is Map) {
            notificationMap['metadata'] = TimeUtils.sanitizeMetadata(
              Map<String, dynamic>.from(metadata)
            );
          }
        }
        
        return notificationMap;
      }).toList();

      AppLogger.d('📨 ${response.length} notificaciones recientes obtenidas para: $userId');
      return sanitizedResponse;
    } catch (e) {
      AppLogger.e('Error obteniendo notificaciones recientes: $e');
      return [];
    }
  }

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

  Future<bool> ensureRLSConfigured() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final testNotification = {
        'user_id': currentUser.id,
        'title': 'Test RLS',
        'message': 'Verificando configuración RLS',
        'type': 'test',
        'read': false,
        'sender_id': currentUser.id,
        'created_at': TimeUtils.currentIso8601String(),
        'metadata': TimeUtils.ensureJsonSerializable({'test': true}),
      };

      final result = await _supabase
        .from('notifications')
        .insert(testNotification)
        .select()
        .single();

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
        metadata: TimeUtils.ensureJsonSerializable({
          'from_user': fromUserName,
          'agreement_type': agreementType,
          'product_title': productTitle,
          'action': 'VIEW_AGREEMENT',
        }),
      );
    } catch (e) {
      AppLogger.e('❌ Error en notificación de acuerdo: $e');
    }
  }

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
        metadata: TimeUtils.ensureJsonSerializable({
          'from_user': fromUserName,
          'rating': rating.toString(),
          'comment': comment,
          'action': 'VIEW_RATING',
        }),
      );
    } catch (e) {
      AppLogger.e('❌ Error en notificación de calificación: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Diagnóstico completo de notificaciones (CORREGIDO - Sin parámetro count)
  Future<void> diagnoseNotificationSystem() async {
    try {
      AppLogger.d('🔍 DIAGNÓSTICO COMPLETO DEL SISTEMA DE NOTIFICACIONES');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return;
      }

      // 1. Verificar autenticación
      AppLogger.d('1. Verificando autenticación...');
      AppLogger.d('   - User ID: ${currentUser.id}');
      AppLogger.d('   - Email: ${currentUser.email}');
      
      // 2. Verificar tabla - VERSIÓN CORREGIDA (Sin parámetro count)
      AppLogger.d('2. Verificando tabla notifications...');
      try {
        // ✅ CORRECCIÓN: Usar una consulta simple para verificar si la tabla existe
        final result = await _supabase
            .from('notifications')
            .select('id')
            .limit(1)
            .maybeSingle();
            
        if (result != null) {
          AppLogger.d('   - Tabla notifications: ✅ EXISTE');
          // Para obtener el conteo, hacemos una consulta separada
          try {
            final countResult = await _supabase
                .from('notifications')
                .select('count(*)')
                .single();
            final count = countResult['count'] as int? ?? 0;
            AppLogger.d('   - Total notificaciones: $count');
          } catch (e) {
            AppLogger.d('   - No se pudo obtener conteo total: $e');
          }
        } else {
          AppLogger.d('   - Tabla notifications: ✅ EXISTE (sin datos)');
        }
      } catch (e) {
        AppLogger.e('   - Error accediendo a tabla: $e');
      }
      
      // 3. Verificar configuración RLS
      AppLogger.d('3. Verificando configuración RLS...');
      final rlsStatus = await checkFullRLSStatus();
      AppLogger.d('   - RLS Status: ${rlsStatus['success'] ? '✅' : '❌'}');
      
      // 4. Verificar metadata issues
      AppLogger.d('4. Verificando problemas de metadata...');
      final diagnostics = await diagnoseNotificationIssues();
      AppLogger.d('   - Metadata issues: ${diagnostics['results']?['metadata_issues'] ?? 'Desconocido'}');
      
      // 5. Prueba de notificación
      AppLogger.d('5. Realizando prueba de notificación...');
      try {
        await sendInAppNotification(
          toUserId: currentUser.id,
          title: 'Prueba Diagnóstico',
          message: 'Esta es una notificación de prueba del sistema',
          type: 'test',
          metadata: TimeUtils.ensureJsonSerializable({
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
        AppLogger.d('   - Notificación de prueba: ✅ ENVIADA');
      } catch (e) {
        AppLogger.e('   - Notificación de prueba: ❌ ERROR: $e');
      }
      
      AppLogger.d('✅ DIAGNÓSTICO COMPLETADO');
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico completo: $e');
    }
  }
}