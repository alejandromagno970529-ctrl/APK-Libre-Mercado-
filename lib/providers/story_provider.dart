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

  // ✅ MÉTODO PARA VERIFICAR SI EL PROVIDER ESTÁ ACTIVO
  bool get isActive => !_isDisposed;

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
      
      // ✅ INICIAR AUTO-REFRESH SI HAY HISTORIAS
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

  // ✅ MÉTODO PARA INICIAR AUTO-REFRESH
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_stories.isNotEmpty && isActive) { // ✅ USAR isActive EN LUGAR DE mounted
        _cleanupExpiredStoriesSilently();
        // ✅ FORZAR ACTUALIZACIÓN DE TIEMPOS CADA 30 SEGUNDOS
        notifyListeners();
        AppLogger.d('🔄 Tiempos actualizados (${DateTime.now().toIso8601String()})');
      }
    });
    AppLogger.d('🔄 Auto-refresh iniciado (cada 30 segundos)');
  }

  // ✅ MÉTODO SILENCIOSO PARA LIMPIAR HISTORIAS EXPIRADAS
  Future<void> _cleanupExpiredStoriesSilently() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .lt('expires_at', now)
          .eq('is_active', true);

      // Actualizar lista local removiendo expiradas
      final expiredCount = _stories.where((story) => story.isExpired).length;
      if (expiredCount > 0) {
        _stories.removeWhere((story) => story.isExpired);
        AppLogger.d('🔄 $expiredCount historias expiradas removidas automáticamente');
      }
    } catch (e) {
      AppLogger.e('Error en cleanup automático', e);
    }
  }

  // ✅ MÉTODO ACTUALIZADO: GARANTIZAR 24 HORAS EXACTAS
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

      // Subir múltiples imágenes
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
        AppLogger.d('✅ Imagen ${i + 1} subida correctamente');
      }

      AppLogger.d('✅ Todas las imágenes subidas: ${imageUrls.length}');

      // ✅ GARANTIZAR FECHAS EXACTAS
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(hours: 24)); // ✅ 24 HORAS EXACTAS

      AppLogger.d('🕐 Fechas de la historia:');
      AppLogger.d('   Creada: $createdAt');
      AppLogger.d('   Expira: $expiresAt');
      AppLogger.d('   Duración total: 24 horas');

      // ✅ CREAR STORY DATA COMPATIBLE
      final storyData = {
        // Para compatibilidad con base de datos existente
        'image_url': imageUrls.isNotEmpty ? imageUrls[0] : null,
        // Nuevo campo para múltiples imágenes (si existe la columna)
        'image_urls': imageUrls,
        'text': text,
        'product_id': productId,
        'user_id': userId,
        'username': username,
        'created_at': createdAt.toUtc().toIso8601String(),
        'expires_at': expiresAt.toUtc().toIso8601String(), // ✅ 24 HORAS DESDE CREACIÓN
        'is_active': true,
      };

      // Intentar insertar con image_urls, si falla intentar sin él
      try {
        await _supabase
            .from('stories')
            .insert(storyData);
      } catch (e) {
        AppLogger.w('⚠️ Error insertando con image_urls, intentando sin él...');
        
        // Remover image_urls y intentar nuevamente
        storyData.remove('image_urls');
        await _supabase
            .from('stories')
            .insert(storyData);
        
        AppLogger.d('✅ Historia creada en modo compatibilidad (solo image_url)');
      }

      AppLogger.d('✅ Historia con ${imageUrls.length} imágenes creada exitosamente');
      
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

  // ✅ MÉTODO ORIGINAL MANTENIDO para compatibilidad
  Future<bool> createStory(File imageFile, String userId, String username, {String? text, String? productId}) async {
    return await createStoryWithMultipleImages([imageFile], userId, username, text: text, productId: productId);
  }

  // ✅ MÉTODO MEJORADO PARA ELIMINAR HISTORIA
  Future<bool> deleteStory(String storyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppLogger.d('🗑️ Eliminando historia: $storyId');

      // Primero obtener la historia para tener las URLs de las imágenes
      final storyResponse = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      // ignore: unnecessary_null_comparison
      if (storyResponse != null) {
        final story = Story.fromJson(storyResponse);
        
        // Eliminar todas las imágenes del almacenamiento
        try {
          final imageUploadService = ImageUploadService(_supabase);
          for (final imageUrl in story.imageUrls) {
            await imageUploadService.deleteImage(imageUrl);
          }
          AppLogger.d('✅ ${story.imageUrls.length} imágenes eliminadas del almacenamiento');
        } catch (e) {
          AppLogger.w('⚠️ No se pudieron eliminar algunas imágenes, pero continuando...');
        }
      }

      // Eliminar la historia de la base de datos
      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId);

      // Remover de la lista local
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

  // ✅ MÉTODO PARA OBTENER HISTORIAS DEL USUARIO ACTUAL
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

  // ✅ MÉTODO PARA VERIFICAR SI EL USUARIO ES PROPIETARIO
  bool isStoryOwner(String storyId, String userId) {
    try {
      final story = _stories.firstWhere((story) => story.id == storyId);
      return story.userId == userId;
    } catch (e) {
      return false;
    }
  }

  // ✅ MÉTODO PARA LIMPIAR HISTORIAS EXPIRADAS (manual)
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .lt('expires_at', now)
          .eq('is_active', true);

      await fetchStories();
      AppLogger.d('✅ Historias expiradas limpiadas manualmente');
    } catch (e) {
      AppLogger.e('Error en cleanupExpiredStories', e);
    }
  }

  // ✅ MÉTODO PARA FORZAR ACTUALIZACIÓN DE TIEMPOS
  void refreshStoryTimes() {
    if (isActive) {
      notifyListeners();
      AppLogger.d('🔄 Tiempos de historias actualizados manualmente');
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

  // ✅ MÉTODO PARA VERIFICAR INTEGRIDAD DE TIEMPOS
  void debugStoryTimes() {
    AppLogger.d('🔍 DEBUG - TIEMPOS DE HISTORIAS:');
    for (final story in _stories.take(3)) {
      final now = DateTime.now();
      final remaining = story.expiresAt.difference(now);
      AppLogger.d('   Story: ${story.username}');
      AppLogger.d('   Creada: ${story.createdAt}');
      AppLogger.d('   Expira: ${story.expiresAt}');
      AppLogger.d('   Restante: ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m');
      AppLogger.d('   TimeRemaining: ${story.timeRemaining}');
    }
  }
}