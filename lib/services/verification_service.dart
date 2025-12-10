// lib/services/verification_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class VerificationService {
  final SupabaseClient _supabase;

  VerificationService(this._supabase);

  Future<String> uploadVerificationDocument(File documentImage, String userId) async {
    try {
      AppLogger.d('📤 Subiendo documento de verificación para usuario: $userId');
      
      // Leer el archivo como bytes
      final fileBytes = await documentImage.readAsBytes();
      
      // Generar nombre único para el archivo
      final fileName = 'verification_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'verification-documents/$fileName';
      
      // Subir a Supabase Storage
      final uploadResponse = await _supabase.storage
          .from('documents')
          .uploadBinary(filePath, fileBytes);
      
      if (uploadResponse.isEmpty) {
        throw Exception('Error subiendo documento');
      }
      
      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(filePath);
      
      AppLogger.d('✅ Documento subido exitosamente: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      AppLogger.e('Error subiendo documento de verificación', e);
      rethrow;
    }
  }

  Future<void> updateVerificationStatus({
    required String userId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      AppLogger.d('🔄 Actualizando estado de verificación: $userId -> $status');
      
      final updateData = <String, dynamic>{
        'verification_status': status,
        'verification_reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (adminNotes != null) {
        updateData['verification_admin_notes'] = adminNotes;
      }
      
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      AppLogger.d('✅ Estado de verificación actualizado: $status');
      
    } catch (e) {
      AppLogger.e('Error actualizando verificación', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getVerificationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('verification_status, verification_submitted_at, verification_reviewed_at')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      AppLogger.e('Error obteniendo estado de verificación', e);
      return null;
    }
  }
}