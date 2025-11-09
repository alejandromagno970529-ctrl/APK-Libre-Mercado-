// lib/providers/reputation_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ReputationProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  
  List<Map<String, dynamic>> _userRatings = [];
  bool _isLoading = false;
  String? _error;

  ReputationProvider(this._supabase);

  List<Map<String, dynamic>> get userRatings => _userRatings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ MÉTODO CORREGIDO: createRating
  Future<String?> createRating({
    required String toUserId,
    required int rating,
    String? comment,
    String? transactionId,
  }) async {
    try {
      AppLogger.d('⭐ Creando rating para usuario: $toUserId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return 'Usuario no autenticado';
      }

      final ratingData = {
        'from_user_id': currentUser.id,
        'to_user_id': toUserId,
        'rating': rating,
        'comment': comment,
        'transaction_id': transactionId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('ratings')
          .insert(ratingData)
          .select();

      AppLogger.d('✅ Rating creado exitosamente');
      
      // Actualizar la reputación del usuario
      await _updateUserReputation(toUserId);
      
      return null; // Éxito
    } catch (e) {
      AppLogger.e('❌ Error creando rating', e);
      return 'Error al crear la valoración: $e';
    }
  }

  // Método para actualizar la reputación del usuario
  Future<void> _updateUserReputation(String userId) async {
    try {
      final ratingsResponse = await _supabase
          .from('ratings')
          .select('rating')
          .eq('to_user_id', userId);

      if (ratingsResponse.isEmpty) return;

      final totalRating = ratingsResponse
          .map((r) => (r['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      
      final averageRating = totalRating / ratingsResponse.length;

      await _supabase
          .from('profiles')
          .update({'reputation': averageRating})
          .eq('id', userId);

      AppLogger.d('✅ Reputación actualizada: $averageRating');
    } catch (e) {
      AppLogger.e('❌ Error actualizando reputación', e);
    }
  }

  // Método para obtener ratings de usuario
  Future<void> getUserRatings(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('📊 Cargando ratings del usuario: $userId');
      
      // Método principal con join
      try {
        final response = await _supabase
            .from('ratings')
            .select('''
              *,
              from_user:profiles!ratings_from_user_id_fkey(
                id,
                username,
                avatar_url
              )
            ''')
            .eq('to_user_id', userId)
            .order('created_at', ascending: false);

        _userRatings = response;
      } catch (e) {
        // Método alternativo si falla el join
        AppLogger.w('⚠️ Método principal falló, usando alternativo');
        final ratingsResponse = await _supabase
            .from('ratings')
            .select()
            .eq('to_user_id', userId)
            .order('created_at', ascending: false);

        _userRatings = [];
        for (var rating in ratingsResponse) {
          final fromUserId = rating['from_user_id'] as String;
          final userResponse = await _supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .eq('id', fromUserId)
              .single();

          _userRatings.add({
            ...rating,
            'from_user': userResponse,
          });
        }
      }

      AppLogger.d('✅ Ratings cargados: ${_userRatings.length}');
    } catch (e) {
      AppLogger.e('❌ Error en ReputationProvider.getUserRatings', e);
      _error = 'Error al cargar las calificaciones: $e';
      _userRatings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para refrescar ratings
  Future<void> refreshUserRatings(String userId) async {
    await getUserRatings(userId);
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Método para obtener reputación promedio
  Future<double> getUserReputation(String userId) async {
    try {
      final ratingsResponse = await _supabase
          .from('ratings')
          .select('rating')
          .eq('to_user_id', userId);

      if (ratingsResponse.isEmpty) return 0.0;
      
      final totalRating = ratingsResponse
          .map((r) => (r['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      
      return totalRating / ratingsResponse.length;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo reputación', e);
      return 0.0;
    }
  }
}