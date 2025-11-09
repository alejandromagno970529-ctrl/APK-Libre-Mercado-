// lib/services/rating_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class RatingService {
  final SupabaseClient _supabase;

  RatingService(this._supabase);

  // Método corregido para obtener ratings de usuario
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      AppLogger.d('📊 Obteniendo ratings para usuario: $userId');
      
      // Consulta corregida - unir con profiles para obtener información del usuario
      final response = await _supabase
          .from('ratings')
          .select('''
            *,
            from_user:profiles!ratings_from_user_id_fkey(
              id,
              username,
              avatar_url
            ),
            to_user:profiles!ratings_to_user_id_fkey(
              id, 
              username,
              avatar_url
            )
          ''')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      AppLogger.d('✅ Ratings obtenidos: ${response.length}');
      return response;
    } catch (e) {
      AppLogger.e('❌ Error getUserRatings', e);
      rethrow;
    }
  }

  // Método alternativo si la relación no existe
  Future<List<Map<String, dynamic>>> getUserRatingsAlternative(String userId) async {
    try {
      AppLogger.d('📊 Obteniendo ratings (método alternativo) para: $userId');
      
      // Obtener ratings directamente
      final ratingsResponse = await _supabase
          .from('ratings')
          .select()
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      // Obtener información de usuarios por separado
      final List<Map<String, dynamic>> completeRatings = [];
      
      for (var rating in ratingsResponse) {
        final fromUserId = rating['from_user_id'] as String;
        
        // Obtener información del usuario que calificó
        final userResponse = await _supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', fromUserId)
            .single();

        completeRatings.add({
          ...rating,
          'from_user': userResponse,
        });
      }

      AppLogger.d('✅ Ratings alternativos obtenidos: ${completeRatings.length}');
      return completeRatings;
    } catch (e) {
      AppLogger.e('❌ Error getUserRatingsAlternative', e);
      rethrow;
    }
  }

  // Calcular reputación promedio
  Future<double> calculateUserReputation(String userId) async {
    try {
      final ratings = await getUserRatings(userId);
      
      if (ratings.isEmpty) return 0.0;
      
      final totalRating = ratings
          .map((r) => (r['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      
      return totalRating / ratings.length;
    } catch (e) {
      AppLogger.e('❌ Error calculando reputación', e);
      return 0.0;
    }
  }
}