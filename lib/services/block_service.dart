// lib/services/block_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class BlockService {
  final SupabaseClient _supabase;

  BlockService(this._supabase);

  // Bloquear usuario
  Future<void> blockUser(String blockedUserId, String blockedByUserId) async {
    try {
      AppLogger.d('🚫 Bloqueando usuario: $blockedUserId');
      
      final blockData = {
        'blocked_user_id': blockedUserId,
        'blocked_by_user_id': blockedByUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('blocked_users')
          .insert(blockData);

      AppLogger.d('✅ Usuario bloqueado exitosamente');
    } catch (e) {
      AppLogger.e('❌ Error bloqueando usuario: $e', e);
      rethrow;
    }
  }

  // Desbloquear usuario
  Future<void> unblockUser(String blockedUserId, String blockedByUserId) async {
    try {
      AppLogger.d('🔓 Desbloqueando usuario: $blockedUserId');
      
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocked_user_id', blockedUserId)
          .eq('blocked_by_user_id', blockedByUserId);

      AppLogger.d('✅ Usuario desbloqueado exitosamente');
    } catch (e) {
      AppLogger.e('❌ Error desbloqueando usuario: $e', e);
      rethrow;
    }
  }

  // Verificar si un usuario está bloqueado
  Future<bool> isUserBlocked(String blockedUserId, String blockedByUserId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select()
          .eq('blocked_user_id', blockedUserId)
          .eq('blocked_by_user_id', blockedByUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.e('❌ Error verificando bloqueo: $e');
      return false;
    }
  }

  // Obtener lista de usuarios bloqueados
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final response = await _supabase
          .from('blocked_users')
          .select('blocked_user_id')
          .eq('blocked_by_user_id', userId);

      return response.map((item) => item['blocked_user_id'] as String).toList();
    } catch (e) {
      AppLogger.e('❌ Error obteniendo usuarios bloqueados: $e');
      return [];
    }
  }
}