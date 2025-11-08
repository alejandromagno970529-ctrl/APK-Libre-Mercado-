import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/story_model.dart';
import '../utils/logger.dart';
import '../services/image_upload_service.dart';

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

      AppLogger.d('🔄 Cargando historias...');

      final response = await _supabase
          .from('stories')
          .select()
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      _stories = response
          .map((json) => Story.fromJson(json))
          .where((story) => story.isValid)
          .toList();
      
      AppLogger.d('✅ ${_stories.length} historias cargadas exitosamente');
          
    } catch (e) {
      _error = 'Error al cargar historias: $e';
      AppLogger.e('Error en fetchStories', e);
      _stories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO SIMPLIFICADO: Solo campos que existen en la BD
  Future<bool> addStory({
    required String imageUrl,
    String? text,
    String? productId,
    required String userId,
    required String username,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('➕ Creando nueva historia...');

      final storyData = {
        'image_url': imageUrl,
        'text': text,
        'product_id': productId,
        'user_id': userId,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'is_active': true,
      };

      await _supabase
          .from('stories')
          .insert(storyData);

      AppLogger.d('✅ Historia creada exitosamente');
      
      await fetchStories();
      return true;
      
    } catch (e) {
      _error = 'Error al publicar historia: $e';
      AppLogger.e('Error en addStory', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO CORREGIDO: Sin campos que no existen en la BD
  Future<bool> addEditedStory({
    required Uint8List imageBytes,
    required String userId,
    required String username,
    String? text,
    String? productId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('🎨 Creando historia editada...');

      // 1. SUBIR IMAGEN
      final imageUploadService = ImageUploadService(_supabase);
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/story_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      try {
        await tempFile.writeAsBytes(imageBytes);
        final String? imageUrl = await imageUploadService.uploadStoryImage(tempFile, userId);
        
        await tempFile.delete();

        if (imageUrl == null) {
          _error = 'Error subiendo imagen de la historia editada';
          AppLogger.e('❌ Error: No se pudo subir la imagen');
          return false;
        }

        AppLogger.d('✅ Imagen editada subida correctamente: $imageUrl');

        // ✅ SOLO CAMPOS QUE EXISTEN EN LA BD
        final storyData = {
          'image_url': imageUrl,
          'text': text ?? 'Historia editada',
          'product_id': productId,
          'user_id': userId,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'is_active': true,
        };

        // Remover campos nulos
        storyData.removeWhere((key, value) => value == null);

        await _supabase
            .from('stories')
            .insert(storyData);

        AppLogger.d('✅ Historia editada creada exitosamente');
        
        await fetchStories();
        return true;

      } catch (uploadError) {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        rethrow;
      }
      
    } catch (e) {
      _error = 'Error al publicar historia editada: $e';
      AppLogger.e('Error en addEditedStory', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MÉTODOS UTILITARIOS EXISTENTES
  Future<bool> deleteStory(String storyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppLogger.d('🗑️ Eliminando historia: $storyId');

      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId);

      _stories.removeWhere((story) => story.id == storyId);
      
      AppLogger.d('✅ Historia eliminada');
      return true;
      
    } catch (e) {
      _error = 'Error al eliminar historia: $e';
      AppLogger.e('Error en deleteStory', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .lt('expires_at', now)
          .eq('is_active', true);

      await fetchStories();
      AppLogger.d('✅ Historias expiradas limpiadas');
    } catch (e) {
      AppLogger.e('Error en cleanupExpiredStories', e);
    }
  }

  Future<List<Story>> getUserStories(String userId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error en getUserStories', e);
      return [];
    }
  }

  Future<bool> deactivateStory(String storyId) async {
    try {
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .eq('id', storyId);

      final index = _stories.indexWhere((story) => story.id == storyId);
      if (index != -1) {
        _stories.removeAt(index);
      }
      
      notifyListeners();
      AppLogger.d('✅ Historia desactivada: $storyId');
      return true;
    } catch (e) {
      AppLogger.e('Error en deactivateStory', e);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchStories();
  }

  void resetLoading() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}