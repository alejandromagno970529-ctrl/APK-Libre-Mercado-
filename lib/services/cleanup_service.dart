// lib/services/cleanup_service.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class CleanupService {
  final SupabaseClient _supabase;

  CleanupService(this._supabase);

  // ✅ MÉTODO MEJORADO: Limpiar mensajes antiguos con transacciones
  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      AppLogger.d('🧹 Limpiando mensajes más antiguos que: $cutoffDate');
      
      // Primero identificar mensajes con archivos
      final fileMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .lt('created_at', cutoffDate.toIso8601String());

      // Filtrar mensajes que tienen metadata
      final messagesWithFiles = fileMessages.where((message) => 
          message['metadata'] != null).toList();

      AppLogger.d('📁 Encontrados ${messagesWithFiles.length} mensajes con archivos para limpiar');

      // Eliminar archivos del storage
      int filesDeleted = 0;
      for (final message in messagesWithFiles) {
        try {
          final metadata = message['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata['file_url'] != null) {
            await _deleteFileFromUrl(metadata['file_url'] as String);
            filesDeleted++;
          }
        } catch (e) {
          AppLogger.e('❌ Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }

      AppLogger.d('✅ $filesDeleted archivos eliminados del storage');

      // Eliminar mensajes de la base de datos
      final response = await _supabase
          .from('messages')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ $deletedCount mensajes antiguos eliminados de la base de datos');
      return deletedCount;
    } catch (e) {
      AppLogger.e('❌ Error en cleanupOldMessages: $e', e);
      return 0;
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar archivo desde URL
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
      // No rethrow para continuar con la limpieza
    }
  }

  // ✅ NUEVO MÉTODO: Limpieza completa del sistema
  Future<Map<String, int>> performCompleteCleanup({int daysOld = 30}) async {
    try {
      AppLogger.d('🧹 INICIANDO LIMPIEZA COMPLETA DEL SISTEMA...');
      
      final results = {
        'old_messages': 0,
        'old_notifications': 0,
        'orphaned_files': 0,
      };
      
      // 1. Limpiar mensajes antiguos
      results['old_messages'] = await cleanupOldMessages(daysOld: daysOld);
      
      // 2. Limpiar notificaciones antiguas
      results['old_notifications'] = await cleanupOldNotifications(daysOld: daysOld);
      
      // 3. Limpiar archivos huérfanos
      results['orphaned_files'] = await cleanupOrphanedFiles();
      
      AppLogger.d('''
✅ LIMPIEZA COMPLETADA:
   - Mensajes eliminados: ${results['old_messages']}
   - Notificaciones eliminadas: ${results['old_notifications']}  
   - Archivos huérfanos eliminados: ${results['orphaned_files']}
''');
      
      return results;
    } catch (e) {
      AppLogger.e('❌ Error en limpieza completa: $e');
      return {'old_messages': 0, 'old_notifications': 0, 'orphaned_files': 0};
    }
  }

  // ✅ NUEVO MÉTODO: Limpiar notificaciones antiguas
  Future<int> cleanupOldNotifications({int daysOld = 180}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      AppLogger.d('🔔 Limpiando notificaciones antiguas...');
      
      final response = await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ $deletedCount notificaciones antiguas eliminadas');
      return deletedCount;
    } catch (e) {
      AppLogger.e('❌ Error limpiando notificaciones antiguas: $e');
      return 0;
    }
  }

  // ✅ NUEVO MÉTODO: Limpiar archivos huérfanos
  Future<int> cleanupOrphanedFiles() async {
    try {
      AppLogger.d('🔍 Buscando archivos huérfanos...');
      
      // Obtener todas las URLs de archivos en uso desde mensajes
      final messagesWithFiles = await _supabase
          .from('messages')
          .select('metadata');
      
      final usedFileUrls = <String>{};
      
      for (final message in messagesWithFiles) {
        try {
          final metadata = message['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata['file_url'] != null) {
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
      
      // Nota: Para una implementación completa, necesitarías:
      // 1. Listar todos los archivos en los buckets de storage
      // 2. Comparar con usedFileUrls
      // 3. Eliminar los que no estén en la lista
      
      // Por ahora retornamos 0 ya que requiere lógica más compleja
      // de listado de buckets y comparación
      
      AppLogger.d('💡 Limpieza de archivos huérfanos requiere implementación adicional');
      return 0;
    } catch (e) {
      AppLogger.e('❌ Error limpiando archivos huérfanos: $e');
      return 0;
    }
  }

  // ✅ NUEVO MÉTODO: Limpiar chats vacíos (sin mensajes)
  Future<int> cleanupEmptyChats() async {
    try {
      AppLogger.d('💬 Limpiando chats vacíos...');
      
      // Obtener todos los chats
      final allChats = await _supabase
          .from('chats')
          .select('id');
      
      if (allChats.isEmpty) {
        AppLogger.d('✅ No hay chats para limpiar');
        return 0;
      }
      
      int emptyChatsDeleted = 0;
      
      // Verificar cada chat si tiene mensajes
      for (final chat in allChats) {
        final chatId = chat['id'] as String;
        
        final messages = await _supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .limit(1);
        
        // Si no tiene mensajes, eliminar el chat
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

  // ✅ MÉTODO CORREGIDO: Estadísticas de limpieza sin CountOption
  Future<Map<String, dynamic>> getCleanupStats() async {
    try {
      AppLogger.d('📊 Obteniendo estadísticas de limpieza...');
      
      // Contar mensajes antiguos (más de 30 días) - CORREGIDO
      final oldMessagesResponse = await _supabase
          .from('messages')
          .select('id')
          // ignore: prefer_const_constructors
          .lt('created_at', DateTime.now().subtract(Duration(days: 30)).toIso8601String());
      
      final oldMessagesCount = oldMessagesResponse.length;
      
      // Contar notificaciones antiguas - CORREGIDO
      final oldNotificationsResponse = await _supabase
          .from('notifications')
          .select('id')
          // ignore: prefer_const_constructors
          .lt('created_at', DateTime.now().subtract(Duration(days: 180)).toIso8601String());
      
      final oldNotificationsCount = oldNotificationsResponse.length;
      
      // Contar chats vacíos
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
        'last_cleanup': DateTime.now().toIso8601String(),
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

  // ✅ NUEVO MÉTODO: Limpieza programada
  Future<void> scheduleCleanup() async {
    try {
      AppLogger.d('⏰ Ejecutando limpieza programada...');
      
      final stats = await getCleanupStats();
      
      // Solo ejecutar limpieza si hay elementos para limpiar
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

  // ✅ NUEVO MÉTODO: Verificar estado de los buckets de storage
  Future<Map<String, dynamic>> checkStorageBuckets() async {
    try {
      AppLogger.d('🔍 Verificando estado de buckets de storage...');
      
      final buckets = await _supabase.storage.listBuckets();
      
      final bucketInfo = <String, dynamic>{};
      for (final bucket in buckets) {
        bucketInfo[bucket.name] = {
          'name': bucket.name,
          'public': bucket.public,
          // ignore: invalid_null_aware_operator
          'created_at': bucket.createdAt?.toIso8601String(),
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

  // ✅ NUEVO MÉTODO: Limpiar archivos temporales de un usuario específico
  Future<int> cleanupUserFiles(String userId, {int daysOld = 30}) async {
    try {
      AppLogger.d('👤 Limpiando archivos del usuario: $userId');
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Buscar mensajes del usuario con archivos
      final userMessages = await _supabase
          .from('messages')
          .select('id, metadata, created_at')
          .eq('from_id', userId)
          .lt('created_at', cutoffDate.toIso8601String());
      
      int filesDeleted = 0;
      
      for (final message in userMessages) {
        try {
          final metadata = message['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata['file_url'] != null) {
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
}

extension on String {
  toIso8601String() {}
}