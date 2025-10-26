import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/rating_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ReputationProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  
  bool _isLoading = false;
  String? _error;
  List<Rating> _userRatings = [];
  Map<String, double> _userRatingsCache = {};

  ReputationProvider(this._supabase);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Rating> get userRatings => _userRatings;

  // ✅ Calcular promedio de valoraciones para un usuario
  Future<double> calculateUserRating(String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('rating')
          .eq('to_user_id', userId);

      if (response.isEmpty) return 0.0;

      final ratings = response.map((r) => (r['rating'] as num).toDouble()).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      
      // Actualizar cache
      _userRatingsCache[userId] = average;
      
      return average;
    } catch (e) {
      AppLogger.e('Error calculando rating del usuario', e);
      return 0.0;
    }
  }

  // ✅ Obtener valoraciones de un usuario con información del que valora
  Future<List<Rating>> getUserRatings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Obtener valoraciones con información del usuario que valora
      final response = await _supabase
          .from('ratings')
          .select('''
            *,
            profiles!ratings_from_user_id_fkey (
              username,
              email
            )
          ''')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      _userRatings = (response as List)
          .map((ratingData) {
            final data = Map<String, dynamic>.from(ratingData);
            final profileData = data['profiles'] != null 
                ? Map<String, dynamic>.from(data['profiles'])
                : {};
            
            return Rating(
              id: data['id'] as String,
              fromUserId: data['from_user_id'] as String,
              toUserId: data['to_user_id'] as String,
              rating: data['rating'] as int,
              comment: data['comment'] as String?,
              transactionId: data['transaction_id'] as String?,
              createdAt: DateTime.parse(data['created_at']),
              fromUserName: profileData['username'] as String?,
              fromUserEmail: profileData['email'] as String?,
            );
          })
          .toList();

      AppLogger.d('✅ Valoraciones cargadas: ${_userRatings.length} para usuario: $userId');
      return _userRatings;
    } catch (e) {
      _error = 'Error al cargar valoraciones: $e';
      AppLogger.e('Error getUserRatings', e);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Crear nueva valoración
  Future<String?> createRating({
    required String toUserId,
    required int rating,
    required String? comment,
    required String? transactionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fromUser = _supabase.auth.currentUser;
      if (fromUser == null) return 'Usuario no autenticado';

      // Validar rating
      if (rating < 1 || rating > 5) {
        return 'La valoración debe ser entre 1 y 5 estrellas';
      }

      // Verificar que no se esté valorando a sí mismo
      if (fromUser.id == toUserId) {
        return 'No puedes valorarte a ti mismo';
      }

      AppLogger.d('⭐ Creando valoración para usuario: $toUserId');

      final response = await _supabase
          .from('ratings')
          .insert({
            'from_user_id': fromUser.id,
            'to_user_id': toUserId,
            'rating': rating,
            'comment': comment,
            'transaction_id': transactionId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select();

      if (response.isNotEmpty) {
        AppLogger.d('🎉 Valoración creada exitosamente');

        // Actualizar estadísticas del usuario valorado
        await _updateUserStats(toUserId);

        // Recargar valoraciones
        await getUserRatings(toUserId);

        return null;
      }
      
      return 'Error al crear la valoración';
    } catch (e) {
      AppLogger.e('Error creando valoración', e);
      return 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Actualizar estadísticas del usuario
  Future<void> _updateUserStats(String userId) async {
    try {
      final averageRating = await calculateUserRating(userId);
      final totalRatings = await _getTotalRatings(userId);

      await _supabase
          .from('profiles')
          .update({
            'rating': averageRating,
            'total_ratings': totalRatings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.d('📊 Estadísticas actualizadas para usuario: $userId - Rating: $averageRating, Total: $totalRatings');
    } catch (e) {
      AppLogger.e('Error actualizando estadísticas del usuario', e);
    }
  }

  // ✅ Obtener total de valoraciones
  Future<int> _getTotalRatings(String userId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('id')
          .eq('to_user_id', userId);

      return response.length;
    } catch (e) {
      AppLogger.e('Error obteniendo total de valoraciones', e);
      return 0;
    }
  }

  // ✅ Obtener rating desde cache o calcular
  Future<double> getCachedUserRating(String userId) async {
    if (_userRatingsCache.containsKey(userId)) {
      return _userRatingsCache[userId]!;
    }
    return await calculateUserRating(userId);
  }

  // ✅ Verificar si ya se valoró a un usuario en una transacción
  Future<bool> hasRatedTransaction(String transactionId, String currentUserId) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('id')
          .eq('transaction_id', transactionId)
          .eq('from_user_id', currentUserId);

      return response.isNotEmpty;
    } catch (e) {
      AppLogger.e('Error verificando valoración de transacción', e);
      return false;
    }
  }

  // ✅ Obtener valoraciones recientes (para dashboard)
  Future<List<Rating>> getRecentRatings({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('ratings')
          .select('''
            *,
            profiles!ratings_from_user_id_fkey (
              username,
              email
            )
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((ratingData) {
            final data = Map<String, dynamic>.from(ratingData);
            final profileData = data['profiles'] != null 
                ? Map<String, dynamic>.from(data['profiles'])
                : {};
            
            return Rating(
              id: data['id'] as String,
              fromUserId: data['from_user_id'] as String,
              toUserId: data['to_user_id'] as String,
              rating: data['rating'] as int,
              comment: data['comment'] as String?,
              transactionId: data['transaction_id'] as String?,
              createdAt: DateTime.parse(data['created_at']),
              fromUserName: profileData['username'] as String?,
              fromUserEmail: profileData['email'] as String?,
            );
          })
          .toList();
    } catch (e) {
      AppLogger.e('Error obteniendo valoraciones recientes', e);
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}