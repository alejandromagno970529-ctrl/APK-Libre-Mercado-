// lib/providers/verification_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class VerificationProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  String? _error;

  VerificationProvider(this._supabase);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> submitVerification({
    required String userId,
    required String documentUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📄 Enviando solicitud de verificación para usuario: $userId');
      
      await _supabase
          .from('profiles')
          .update({
            'verification_status': 'pending',
            'verification_document_url': documentUrl,
            'verification_submitted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.d('✅ Solicitud de verificación enviada exitosamente');
      
    } catch (e) {
      _error = 'Error al enviar solicitud de verificación: $e';
      AppLogger.e('Error enviando verificación', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVerificationStatus({
    required String userId,
    required String status, // 'verified' or 'rejected'
    required String adminNotes,
  }) async {
    try {
      AppLogger.d('🔄 Actualizando estado de verificación: $userId -> $status');
      
      await _supabase
          .from('profiles')
          .update({
            'verification_status': status,
            'verification_reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Aquí podrías enviar una notificación al usuario
      AppLogger.d('✅ Estado de verificación actualizado: $status');
      
    } catch (e) {
      _error = 'Error actualizando verificación: $e';
      AppLogger.e('Error actualizando verificación', e);
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}