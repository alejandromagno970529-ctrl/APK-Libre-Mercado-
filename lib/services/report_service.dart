// lib/services/report_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ReportService {
  final SupabaseClient _supabase;

  ReportService(this._supabase);

  // Reportar usuario
  Future<void> reportUser({
    required String reportedUserId,
    required String reportedByUserId,
    required String reason,
    String? description,
    String? chatId,
  }) async {
    try {
      AppLogger.d('🚨 Reportando usuario: $reportedUserId');
      
      final reportData = {
        'reported_user_id': reportedUserId,
        'reported_by_user_id': reportedByUserId,
        'reason': reason,
        'description': description,
        'chat_id': chatId,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      await _supabase
          .from('user_reports')
          .insert(reportData);

      AppLogger.d('✅ Usuario reportado exitosamente');
    } catch (e) {
      AppLogger.e('❌ Error reportando usuario: $e', e);
      rethrow;
    }
  }

  // Obtener reportes de un usuario
  Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select()
          .eq('reported_by_user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo reportes: $e');
      return [];
    }
  }

  // Verificar si ya se reportó a un usuario
  Future<bool> hasReportedUser(String reportedUserId, String reportedByUserId) async {
    try {
      final response = await _supabase
          .from('user_reports')
          .select()
          .eq('reported_user_id', reportedUserId)
          .eq('reported_by_user_id', reportedByUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.e('❌ Error verificando reporte: $e');
      return false;
    }
  }
}