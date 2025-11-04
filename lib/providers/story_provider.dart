import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';

class StoryProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _error;

  StoryProvider(this._supabase);

  List<Story> get stories => _stories.where((story) => !story.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('stories')
          .select()
          .order('created_at', ascending: false);

      _stories = (response as List).map((json) => Story.fromJson(json)).toList();
      
      // Eliminar historias expiradas
      _stories = _stories.where((story) => !story.isExpired).toList();
      
    } catch (e) {
      _error = 'Error al cargar historias: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStory({
    required String userId,
    required String username,
    String? imageUrl,
    String? text,
    String? color,
    String? productId, // ✅ NUEVO: Vincular con producto
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      final story = {
        'user_id': userId,
        'username': username,
        'image_url': imageUrl,
        'text': text,
        'color': color,
        'product_id': productId, // ✅ NUEVO
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

      await _supabase.from('stories').insert(story);
      
      // Recargar historias
      await fetchStories();
      
    } catch (e) {
      _error = 'Error al publicar historia: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('stories')
          .delete()
          .lt('expires_at', now);
    } catch (e) {
      if (kDebugMode) {
        print('Error eliminando historias expiradas: $e');
      }
    }
  }
}