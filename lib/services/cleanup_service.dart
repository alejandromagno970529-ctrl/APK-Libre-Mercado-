import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class CleanupService {
  final SupabaseClient _supabase;

  CleanupService(this._supabase);

  // Limpiar mensajes antiguos
  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      // Primero identificar mensajes con archivos
      // ignore: avoid_init_to_null
      var value = null;
      final fileMessages = await _supabase
          .from('messages')
          .select('id, metadata')
          .lt('created_at', cutoffDate.toIso8601String())
          .neq('metadata', value);

      // Eliminar archivos del storage
      for (final message in fileMessages) {
        try {
          final metadata = message['metadata'];
          if (metadata is Map && metadata['file_url'] != null) {
            await _deleteFileFromUrl(metadata['file_url']);
          }
        } catch (e) {
          AppLogger.e('Error limpiando archivo del mensaje ${message['id']}: $e');
        }
      }

      // Eliminar mensajes de la base de datos
      final response = await _supabase
          .from('messages')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select();

      final deletedCount = response.length;
      AppLogger.d('✅ Mensajes antiguos eliminados: $deletedCount');
      return deletedCount;
    } catch (e) {
      AppLogger.e('Error en cleanupOldMessages: $e');
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
      }
    } catch (e) {
      AppLogger.e('Error eliminando archivo desde URL: $e');
    }
  }
}