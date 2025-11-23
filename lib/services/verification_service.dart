// lib/services/verification_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart'; // Asegúrate de tener tu logger

class VerificationService {
  final SupabaseClient _supabase;

  VerificationService(this._supabase);

  /// Sube la imagen del documento de identidad al bucket privado.
  /// Retorna la ruta del archivo subido.
  Future<String> uploadVerificationDocument(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 Subiendo documento de verificación para: $userId');

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName'; // Ruta: user_id/document_TIMESTAMP.ext

      await _supabase.storage
          .from('verification_documents')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      AppLogger.d('✅ Documento subido exitosamente a: $filePath');
      return filePath;
    } catch (e) {
      AppLogger.e('❌ Error subiendo documento de verificación', e);
      throw Exception('Error al subir el documento: $e');
    }
  }

  /// Obtiene una URL firmada temporal para ver el documento.
  /// (Útil si quieres mostrarle al usuario la foto que subió)
  Future<String> getDocumentUrl(String filePath) async {
    try {
      // Genera una URL válida por 1 hora
      final url = await _supabase.storage
          .from('verification_documents')
          .createSignedUrl(filePath, 3600);
      return url;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo URL del documento', e);
      return '';
    }
  }
}