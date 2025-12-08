// lib/services/cleanup_service.dart - VERSIÓN COMPLETA CORREGIDA
// ignore: unused_import
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../utils/time_utils.dart';

class CleanupService {
  final SupabaseClient _supabase;

  CleanupService(this._supabase);

  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      AppLogger.d('🧹 Limpiando mensajes más antiguos que: $cutoffDate');
      
      final fileMessages = await _supabase
          .from('messages')
          .select('id, metadata, created_at')
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate));

      final messagesWithFiles = fileMessages.where((message) {
        try {
          final metadata = TimeUtils.parseMetadata(message['metadata']);
          
          return metadata.isNotEmpty && 
                 metadata['file_url'] != null &&
                 (metadata['file_url'] as String).isNotEmpty;
        } catch (e) {
          AppLogger.e('❌ Error procesando metadata del mensaje: $e');
          return false;
        }
      }).toList();

      AppLogger.d('📁 Encontrados ${messagesWithFiles.length} mensajes con archivos para limpiar');

      int filesDeleted = 0;
      for (final message in messagesWithFiles) {
        try {
          final metadata = TimeUtils.parseMetadata(message['metadata']);
          
          if (metadata['file_url'] != null) {
            await _deleteFileFromUrl(metadata['file_url'] as String);
            filesDeleted++;
          }
        } catch (e) {
          AppLogger.e('❌ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }

      AppLogger.d('✅ $filesDeleted archivos eliminados del storage');

      final response = await _supabase
          .from('messages')
          .delete()
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate))
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ $deletedCount mensajes antiguos eliminados de la base de datos');
      return deletedCount;
    } catch (e) {
      AppLogger.e('❌ Error en cleanupOldMessages: $e', e);
      return 0;
    }
  }

  Future<void> _deleteFileFromUrl(String fileUrl) async {
    try {
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
        AppLogger.d('🗑️ Archivo eliminado: $fileName del bucket $bucketName');
      } else {
        AppLogger.w('⚠️ No se pudo extraer información del archivo de la URL: $fileUrl');
      }
    } catch (e) {
      AppLogger.e('❌ Error eliminando archivo desde URL: $e');
    }
  }

  Future<Map<String, int>> performCompleteCleanup({int daysOld = 30}) async {
    try {
      AppLogger.d('🧹 INICIANDO LIMPIEZA COMPLETA DEL SISTEMA...');
      
      final results = {
        'old_messages': 0,
        'old_notifications': 0,
        'orphaned_files': 0,
        'corrupted_metadata': 0,
      };
      
      results['corrupted_metadata'] = await fixCorruptedMetadata();
      results['old_messages'] = await cleanupOldMessages(daysOld: daysOld);
      results['old_notifications'] = await cleanupOldNotifications(daysOld: daysOld);
      results['orphaned_files'] = await cleanupOrphanedFiles();
      
      AppLogger.d('''
✅ LIMPIEZA COMPLETADA:
   - Metadata corregida: ${results['corrupted_metadata']}
   - Mensajes eliminados: ${results['old_messages']}
   - Notificaciones eliminadas: ${results['old_notifications']}  
   - Archivos huérfanos eliminados: ${results['orphaned_files']}
''');
      
      return results;
    } catch (e) {
      AppLogger.e('❌ Error en limpieza completa: $e');
      return {
        'old_messages': 0, 
        'old_notifications': 0, 
        'orphaned_files': 0,
        'corrupted_metadata': 0
      };
    }
  }

  Future<int> cleanupOldNotifications({int daysOld = 180}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      AppLogger.d('🔔 Limpiando notificaciones antiguas...');
      
      final response = await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate))
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ $deletedCount notificaciones antiguas eliminadas');
      return deletedCount;
    } catch (e) {
      AppLogger.e('❌ Error limpiando notificaciones antiguas: $e');
      return 0;
    }
  }

  Future<int> cleanupOrphanedFiles() async {
    try {
      AppLogger.d('🔍 Buscando archivos huérfanos...');
      
      final messagesWithFiles = await _supabase
          .from('messages')
          .select('metadata');
      
      final usedFileUrls = <String>{};
      
      for (final message in messagesWithFiles) {
        try {
          final metadata = TimeUtils.parseMetadata(message['metadata']);
          
          if (metadata['file_url'] != null) {
            final fileUrl = metadata['file_url'] as String;
            if (fileUrl.isNotEmpty) {
              usedFileUrls.add(fileUrl);
            }
          }
        } catch (e) {
          AppLogger.e('❌ Error procesando metadata: $e');
        }
      }
      
      AppLogger.d('📊 Archivos en uso encontrados: ${usedFileUrls.length}');
      
      AppLogger.d('💡 Limpieza de archivos huérfanos requiere implementación adicional');
      return 0;
    } catch (e) {
      AppLogger.e('❌ Error limpiando archivos huérfanos: $e');
      return 0;
    }
  }

  Future<int> cleanupEmptyChats() async {
    try {
      AppLogger.d('💬 Limpiando chats vacíos...');
      
      final allChats = await _supabase
          .from('chats')
          .select('id');
      
      if (allChats.isEmpty) {
        AppLogger.d('✅ No hay chats para limpiar');
        return 0;
      }
      
      int emptyChatsDeleted = 0;
      
      for (final chat in allChats) {
        final chatId = chat['id'] as String;
        
        final messages = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .limit(1);
        
        if (messages.isEmpty) {
          try {
            await _supabase
                .from('chats')
                .delete()
                .eq('id', chatId);
            
            emptyChatsDeleted++;
            AppLogger.d('🗑️ Chat vacío eliminado: $chatId');
          } catch (e) {
            AppLogger.e('❌ Error eliminando chat vacío $chatId: $e');
          }
        }
      }
      
      AppLogger.d('✅ $emptyChatsDeleted chats vacíos eliminados');
      return emptyChatsDeleted;
    } catch (e) {
      AppLogger.e('❌ Error limpiando chats vacíos: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getCleanupStats() async {
    try {
      AppLogger.d('📊 Obteniendo estadísticas de limpieza...');
      
      // ignore: prefer_const_constructors
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      final oldMessagesResponse = await _supabase
          .from('messages')
          .select('id')
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate));
      
      final oldMessagesCount = oldMessagesResponse.length;
      
      final oldNotificationsResponse = await _supabase
          .from('notifications')
          .select('id')
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate));
      
      final oldNotificationsCount = oldNotificationsResponse.length;
      
      final allChats = await _supabase
          .from('chats')
          .select('id');
      
      int emptyChatsCount = 0;
      for (final chat in allChats) {
        final messages = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chat['id'] as String)
            .limit(1);
        
        if (messages.isEmpty) {
          emptyChatsCount++;
        }
      }
      
      final stats = {
        'old_messages': oldMessagesCount,
        'old_notifications': oldNotificationsCount,
        'empty_chats': emptyChatsCount,
        'last_cleanup': TimeUtils.currentIso8601String(),
      };
      
      AppLogger.d('''
📊 ESTADÍSTICAS DE LIMPIEZA:
   - Mensajes antiguos: ${stats['old_messages']}
   - Notificaciones antiguas: ${stats['old_notifications']}
   - Chats vacíos: ${stats['empty_chats']}
''');
      
      return stats;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo estadísticas de limpieza: $e');
      return {
        'old_messages': 0,
        'old_notifications': 0,
        'empty_chats': 0,
        'error': e.toString(),
      };
    }
  }

  Future<int> fixCorruptedMetadata() async {
    try {
      AppLogger.d('🔧 Buscando metadata corrupta en mensajes...');
      
      final messages = await _supabase
          .from('messages')
          .select('id, metadata')
          .not('metadata', 'is', null)
          .limit(500);
      
      int fixed = 0;
      
      for (final message in messages) {
        final metadata = message['metadata'];
        final id = message['id'] as String;
        
        if (TimeUtils.containsDateTime(metadata)) {
          final sanitized = TimeUtils.sanitizeMetadata(
            Map<String, dynamic>.from(metadata)
          );
          
          await _supabase
              .from('messages')
              .update({'metadata': sanitized})
              .eq('id', id);
              
          fixed++;
          AppLogger.d('✅ Metadata corregida para mensaje: $id');
        }
      }
      
      AppLogger.d('🎯 $fixed registros de metadata corregidos en mensajes');
      
      AppLogger.d('🔧 Buscando metadata corrupta en notificaciones...');
      final notifications = await _supabase
          .from('notifications')
          .select('id, metadata')
          .not('metadata', 'is', null)
          .limit(500);
      
      int fixedNotifications = 0;
      
      for (final notification in notifications) {
        final metadata = notification['metadata'];
        final id = notification['id'] as String;
        
        if (TimeUtils.containsDateTime(metadata)) {
          final sanitized = TimeUtils.sanitizeMetadata(
            Map<String, dynamic>.from(metadata)
          );
          
          await _supabase
              .from('notifications')
              .update({'metadata': sanitized})
              .eq('id', id);
              
          fixedNotifications++;
          AppLogger.d('✅ Metadata corregida para notificación: $id');
        }
      }
      
      AppLogger.d('🎯 $fixedNotifications registros de metadata corregidos en notificaciones');
      
      return fixed + fixedNotifications;
    } catch (e) {
      AppLogger.e('❌ Error corrigiendo metadata: $e');
      return 0;
    }
  }

  Future<void> scheduleCleanup() async {
    try {
      AppLogger.d('⏰ Ejecutando limpieza programada...');
      
      final stats = await getCleanupStats();
      
      if (stats['old_messages'] as int > 100 || 
          stats['old_notifications'] as int > 50 ||
          stats['empty_chats'] as int > 10) {
        
        AppLogger.d('🚀 Condiciones cumplidas, ejecutando limpieza...');
        await performCompleteCleanup();
        
      } else {
        AppLogger.d('✅ No se requiere limpieza - sistema optimizado');
      }
    } catch (e) {
      AppLogger.e('❌ Error en limpieza programada: $e');
    }
  }

  Future<Map<String, dynamic>> checkStorageBuckets() async {
    try {
      AppLogger.d('🔍 Verificando estado de buckets de storage...');
      
      final buckets = await _supabase.storage.listBuckets();
      
      final bucketInfo = <String, dynamic>{};
      for (final bucket in buckets) {
        bucketInfo[bucket.name] = {
          'name': bucket.name,
          'public': bucket.public,
          // ignore: unnecessary_null_comparison
          'created_at': bucket.createdAt != null 
              ? (bucket.createdAt as DateTime).toIso8601String()
              // ignore: dead_code
              : null,
        };
      }
      
      AppLogger.d('📦 Buckets encontrados: ${buckets.length}');
      for (final bucket in buckets) {
        AppLogger.d('   - ${bucket.name} (público: ${bucket.public})');
      }
      
      return {
        'total_buckets': buckets.length,
        'buckets': bucketInfo,
      };
    } catch (e) {
      AppLogger.e('❌ Error verificando buckets: $e');
      return {
        'total_buckets': 0,
        'error': e.toString(),
      };
    }
  }

  Future<int> cleanupUserFiles(String userId, {int daysOld = 30}) async {
    try {
      AppLogger.d('👤 Limpiando archivos del usuario: $userId');
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final userMessages = await _supabase
          .from('messages')
          .select('id, metadata, created_at')
          .eq('from_id', userId)
          .lt('created_at', TimeUtils.toIso8601String(cutoffDate));
      
      int filesDeleted = 0;
      
      for (final message in userMessages) {
        try {
          final metadata = TimeUtils.parseMetadata(message['metadata']);
          
          if (metadata['file_url'] != null) {
            await _deleteFileFromUrl(metadata['file_url'] as String);
            filesDeleted++;
          }
        } catch (e) {
          AppLogger.e('❌ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }
      
      AppLogger.d('✅ $filesDeleted archivos del usuario $userId eliminados');
      return filesDeleted;
    } catch (e) {
      AppLogger.e('❌ Error limpiando archivos del usuario: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> diagnoseMetadataIssues() async {
    try {
      AppLogger.d('🩺 DIAGNÓSTICO DE METADATA...');
      
      final sampleMessage = await _supabase
          .from('messages')
          .select('id, metadata')
          .not('metadata', 'is', null)
          .limit(1)
          .maybeSingle();
      
      Map<String, dynamic> results = {
        'has_sample': sampleMessage != null,
        'sample_id': sampleMessage?['id'],
        // ignore: invalid_null_aware_operator
        'metadata_type': sampleMessage?['metadata']?.runtimeType?.toString(),
        'contains_datetime': false,
        'fix_applied': false,
      };
      
      if (sampleMessage != null && sampleMessage['metadata'] != null) {
        final metadata = sampleMessage['metadata'];
        final id = sampleMessage['id'] as String;
        
        results['contains_datetime'] = TimeUtils.containsDateTime(metadata);
        
        if (results['contains_datetime']) {
          AppLogger.w('⚠️ Metadata con DateTime detectada en mensaje $id');
          
          final sanitized = TimeUtils.sanitizeMetadata(
            Map<String, dynamic>.from(metadata)
          );
          
          await _supabase
              .from('messages')
              .update({'metadata': sanitized})
              .eq('id', id);
              
          results['fix_applied'] = true;
        }
      }
      
      AppLogger.d('📊 Resultados diagnóstico: $results');
      return results;
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico de metadata: $e');
      return {
        'error': e.toString(),
        'has_sample': false,
      };
    }
  }
}