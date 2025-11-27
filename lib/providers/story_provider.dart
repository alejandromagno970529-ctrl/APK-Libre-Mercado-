import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/story_model.dart';
import '../utils/logger.dart';
import '../services/image_upload_service.dart';

class StoryProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _error;
  Timer? _autoRefreshTimer;
  bool _isDisposed = false;

  StoryProvider(this._supabase);

  List<Story> get stories => _stories.where((story) => !story.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  bool get isActive => !_isDisposed;

  Future<void> fetchStories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('🔄 Cargando historias...');

      // 1. LIMPIEZA ACTIVA: Eliminar basura (DB + Storage) antes de cargar
      await _performHardCleanupOfExpiredStories();

      // 2. Cargar historias vigentes
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
      
      if (_stories.isNotEmpty) {
        _startAutoRefresh();
      }
          
    } catch (e) {
      _error = 'Error al cargar historias: $e';
      AppLogger.e('Error en fetchStories', e);
      _stories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_stories.isNotEmpty && isActive) {
        // Ejecutar limpieza en segundo plano
        _performHardCleanupOfExpiredStories();
        notifyListeners();
        AppLogger.d('🔄 Tiempos actualizados (${DateTime.now().toIso8601String()})');
      }
    });
    AppLogger.d('🔄 Auto-refresh iniciado (cada 30 segundos)');
  }

  // ✅ NUEVO MÉTODO: REALIZA HARD DELETE (Elimina Imágenes + Datos)
  Future<void> _performHardCleanupOfExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // 1. Identificar historias expiradas para obtener sus URLs antes de borrar
      final expiredResponse = await _supabase
          .from('stories')
          .select()
          .lt('expires_at', now); // Buscar donde la fecha de expiración ya pasó

      if ((expiredResponse as List).isEmpty) return;

      final List<Story> expiredStories = (expiredResponse)
          .map((json) => Story.fromJson(json))
          .toList();

      AppLogger.d('🧹 Encontradas ${expiredStories.length} historias expiradas para eliminar...');

      final imageUploadService = ImageUploadService(_supabase);

      // 2. Iterar y borrar recursos físicos
      for (final story in expiredStories) {
        // A. Borrar imágenes del bucket
        if (story.imageUrls.isNotEmpty) {
           await imageUploadService.deleteMultipleImages(story.imageUrls);
           AppLogger.d('🗑️ Imágenes eliminadas para la historia: ${story.id}');
        }

        // B. Borrar fila de la base de datos (HARD DELETE)
        await _supabase
            .from('stories')
            .delete()
            .eq('id', story.id);
      }

      // 3. Limpiar lista local
      final localExpiredCount = _stories.where((story) => story.isExpired).length;
      if (localExpiredCount > 0) {
        _stories.removeWhere((story) => story.isExpired);
        AppLogger.d('✅ Lista local actualizada: removidas expiradas');
      }

    } catch (e) {
      // Logueamos pero no detenemos la app, es un proceso de mantenimiento
      AppLogger.e('⚠️ Error en cleanup automático (Hard Delete)', e);
    }
  }

  Future<bool> createStoryWithMultipleImages(
    List<File> imageFiles, 
    String userId, 
    String username, 
    {String? text, String? productId}
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('➕ Creando nueva historia con ${imageFiles.length} imágenes...');

      final imageUploadService = ImageUploadService(_supabase);
      final List<String> imageUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        AppLogger.d('📤 Subiendo imagen ${i + 1}/${imageFiles.length}...');
        final String? imageUrl = await imageUploadService.uploadStoryImage(imageFiles[i], userId);
        
        if (imageUrl == null) {
          _error = 'Error subiendo imagen ${i + 1} de la historia';
          AppLogger.e('❌ Error: No se pudo subir la imagen ${i + 1}');
          return false;
        }
        
        imageUrls.add(imageUrl);
      }

      // ✅ GARANTIZAR FECHAS EXACTAS
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24));

      final storyData = {
        'image_url': imageUrls.isNotEmpty ? imageUrls[0] : null,
        'image_urls': imageUrls,
        'text': text,
        'product_id': productId,
        'user_id': userId,
        'username': username,
        'created_at': createdAt.toUtc().toIso8601String(),
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'is_active': true,
      };

      try {
        await _supabase
            .from('stories')
            .insert(storyData);
      } catch (e) {
        AppLogger.w('⚠️ Error insertando con image_urls, intentando sin él...');
        storyData.remove('image_urls');
        await _supabase
            .from('stories')
            .insert(storyData);
      }

      AppLogger.d('✅ Historia creada exitosamente');
      
      await fetchStories();
      return true;
      
    } catch (e) {
      _error = 'Error al publicar historia: $e';
      AppLogger.e('Error en createStoryWithMultipleImages', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStory(File imageFile, String userId, String username, {String? text, String? productId}) async {
    return await createStoryWithMultipleImages([imageFile], userId, username, text: text, productId: productId);
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppLogger.d('🗑️ Eliminando historia: $storyId');

      final storyResponse = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      // ignore: unnecessary_null_comparison
      if (storyResponse != null) {
        final story = Story.fromJson(storyResponse);
        
        try {
          final imageUploadService = ImageUploadService(_supabase);
          if (story.imageUrls.isNotEmpty) {
             await imageUploadService.deleteMultipleImages(story.imageUrls);
          }
          AppLogger.d('✅ Imágenes eliminadas del almacenamiento');
        } catch (e) {
          AppLogger.w('⚠️ No se pudieron eliminar algunas imágenes, pero continuando...');
        }
      }

      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId);

      _stories.removeWhere((story) => story.id == storyId);
      
      AppLogger.d('✅ Historia eliminada completamente');
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

  Future<List<Story>> getUserStories(String userId) async {
    try {
      // Primero limpieza rápida
      await _performHardCleanupOfExpiredStories();

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

  bool isStoryOwner(String storyId, String userId) {
    try {
      final story = _stories.firstWhere((story) => story.id == storyId);
      return story.userId == userId;
    } catch (e) {
      return false;
    }
  }

  // Método manual expuesto si se necesita llamar desde UI
  Future<void> cleanupExpiredStories() async {
    await _performHardCleanupOfExpiredStories();
    await fetchStories();
  }

  void refreshStoryTimes() {
    if (isActive) {
      notifyListeners();
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

  void debugStoryTimes() {
    AppLogger.d('🔍 DEBUG - TIEMPOS DE HISTORIAS:');
    for (final story in _stories.take(3)) {
      final now = DateTime.now();
      final remaining = story.expiresAt.difference(now);
      AppLogger.d('   Story: ${story.username}');
      AppLogger.d('   Expira: ${story.expiresAt}');
      AppLogger.d('   Restante: ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m');
    }
  }
}