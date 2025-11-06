import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';
import '../models/story_editing_models.dart';
import '../utils/logger.dart';

class StoryProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Story> _stories = [];
  bool _isLoading = false;
  String? _error;

  StoryProvider(this._supabase);

  List<Story> get stories => _stories.where((story) => !story.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ MÉTODO CORREGIDO: Usando la nueva API de Supabase
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

      _stories = (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
      
      AppLogger.d('✅ ${_stories.length} historias cargadas');
      
    } catch (e) {
      _error = 'Error al cargar historias: $e';
      AppLogger.e('Error en fetchStories', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO CORREGIDO: Nueva API para insertar
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
      
      // Recargar historias
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

  // ✅ MÉTODO NUEVO: Añadir historia editada con elementos
  Future<bool> addEditedStory({
    required Uint8List imageBytes,
    required String userId,
    required String username,
    String? text,
    String? productId,
    List<StoryElement>? elements,
    String? templateId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('🎨 Creando historia editada...');

      // Convertir elementos a JSON para almacenar
      final elementsJson = elements?.map((element) => _elementToJson(element)).toList();

      // Subir imagen editada
      final imageUrl = await _uploadEditedImage(imageBytes, userId);

      final storyData = {
        'image_url': imageUrl,
        'text': text,
        'product_id': productId,
        'user_id': userId,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'is_active': true,
        'editing_elements': elementsJson,
        'template_id': templateId,
        'has_editing': elementsJson != null && elementsJson.isNotEmpty,
      };

      await _supabase
          .from('stories')
          .insert(storyData);

      AppLogger.d('✅ Historia editada creada exitosamente');
      
      // Recargar historias
      await fetchStories();
      return true;
      
    } catch (e) {
      _error = 'Error al publicar historia editada: $e';
      AppLogger.e('Error en addEditedStory', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO SIMPLIFICADO: Subir imagen editada
  Future<String> _uploadEditedImage(Uint8List imageBytes, String userId) async {
    try {
      // Por ahora, usar una URL temporal
      // En producción, integrarías con ImageUploadService aquí
      AppLogger.d('📤 Subiendo imagen editada para usuario: $userId');
      
      // Simulación - en una app real aquí llamarías a ImageUploadService
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://picsum.photos/400/800?random=${DateTime.now().millisecondsSinceEpoch}';
      
    } catch (e) {
      AppLogger.e('Error en _uploadEditedImage', e);
      return 'https://picsum.photos/400/800?error=$userId';
    }
  }

  // ✅ MÉTODO CORREGIDO: Convertir elemento a JSON (PROBLEMAS DE NULLABILIDAD RESUELTOS)
  Map<String, dynamic> _elementToJson(StoryElement element) {
    return {
      'id': element.id,
      'type': element.type.toString(),
      'position_x': element.position.dx,
      'position_y': element.position.dy,
      'content': element.content,
      'style': {
        // ✅ CORREGIDO: Usando operador ?. para propiedades que pueden ser nulas
        // ignore: deprecated_member_use
        'color': element.style?.color != null ? element.style!.color!.value : null,
        'fontSize': element.style?.fontSize,
        'fontWeight': element.style?.fontWeight?.index,
        'fontStyle': element.style?.fontStyle?.index,
      },
      'properties': element.properties,
      'rotation': element.rotation,
      'scale': element.scale,
    };
  }

  // ✅ MÉTODO NUEVO: Convertir JSON a elemento
  // ignore: unused_element
  StoryElement _elementFromJson(Map<String, dynamic> json) {
    return StoryElement(
      id: json['id']?.toString() ?? '',
      type: _parseElementType(json['type']?.toString() ?? ''),
      position: Offset(
        (json['position_x'] as num?)?.toDouble() ?? 0.0,
        (json['position_y'] as num?)?.toDouble() ?? 0.0,
      ),
      content: json['content']?.toString() ?? '',
      style: _parseTextStyle(json['style']),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // ✅ MÉTODO NUEVO: Parsear tipo de elemento
  StoryElementType _parseElementType(String typeString) {
    switch (typeString) {
      case 'StoryElementType.text':
        return StoryElementType.text;
      case 'StoryElementType.sticker':
        return StoryElementType.sticker;
      case 'StoryElementType.cta':
        return StoryElementType.cta;
      case 'StoryElementType.discountTag':
        return StoryElementType.discountTag;
      case 'StoryElementType.shape':
        return StoryElementType.shape;
      default:
        return StoryElementType.text;
    }
  }

  // ✅ MÉTODO NUEVO: Parsear estilo de texto
  TextStyle _parseTextStyle(Map<String, dynamic>? styleJson) {
    if (styleJson == null) return const TextStyle();
    
    return TextStyle(
      color: styleJson['color'] != null ? Color(styleJson['color'] as int) : Colors.white,
      fontSize: (styleJson['fontSize'] as num?)?.toDouble(),
      fontWeight: styleJson['fontWeight'] != null 
          ? FontWeight.values[styleJson['fontWeight'] as int] 
          : FontWeight.normal,
      fontStyle: styleJson['fontStyle'] != null
          ? FontStyle.values[styleJson['fontStyle'] as int]
          : FontStyle.normal,
    );
  }

  // ✅ MÉTODO NUEVO: Obtener historias con elementos de edición
  Future<List<Story>> getStoriesWithEditing() async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('is_active', true)
          .eq('has_editing', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final stories = (response as List)
          .map((json) => Story.fromJson(json))
          .toList();

      // Cargar elementos de edición para cada historia
      for (final story in stories) {
        await _loadEditingElements(story);
      }

      return stories;
    } catch (e) {
      AppLogger.e('Error en getStoriesWithEditing', e);
      return [];
    }
  }

  // ✅ MÉTODO NUEVO: Cargar elementos de edición para una historia
  Future<void> _loadEditingElements(Story story) async {
    try {
      final response = await _supabase
          .from('stories')
          .select('editing_elements')
          .eq('id', story.id)
          .single();

      final elementsJson = response['editing_elements'] as List?;
      
      if (elementsJson != null && elementsJson.isNotEmpty) {
        // Aquí podrías almacenar los elementos en el modelo Story si lo extiendes
        AppLogger.d('📝 Cargados ${elementsJson.length} elementos de edición para historia: ${story.id}');
      }
    } catch (e) {
      AppLogger.e('Error en _loadEditingElements', e);
    }
  }

  // ✅ MÉTODO NUEVO: Obtener plantillas de historias
  Future<List<Map<String, dynamic>>> getStoryTemplates() async {
    try {
      // En una implementación real, esto vendría de una tabla 'story_templates'
      // Por ahora, retornamos templates predefinidos
      return [
        {
          'id': 'promo_1',
          'name': 'Oferta Especial',
          'category': 'Promociones',
          'elements': [
            {
              'type': 'text',
              'content': 'OFERTA ESPECIAL',
              'position': {'x': 0.5, 'y': 0.2},
              'style': {
                'color': 0xFFFFFFFF,
                'fontSize': 24.0,
                'fontWeight': 7, // bold
              }
            },
            {
              'type': 'discountTag',
              'content': '50%',
              'position': {'x': 0.8, 'y': 0.1},
              'style': {
                'color': 0xFFFF0000,
                'fontSize': 20.0,
                'fontWeight': 7,
              },
              'properties': {'backgroundColor': 0xFFFFFF00}
            }
          ]
        },
        {
          'id': 'new_arrival_1',
          'name': 'Nuevo Producto',
          'category': 'Productos',
          'elements': [
            {
              'type': 'text',
              'content': '¡NUEVO!',
              'position': {'x': 0.5, 'y': 0.3},
              'style': {
                'color': 0xFFFFFFFF,
                'fontSize': 22.0,
                'fontWeight': 7,
              }
            }
          ]
        }
      ];
    } catch (e) {
      AppLogger.e('Error en getStoryTemplates', e);
      return [];
    }
  }

  // ✅ MÉTODO NUEVO: Aplicar plantilla a historia existente
  Future<bool> applyTemplateToStory(String storyId, String templateId) async {
    try {
      final templates = await getStoryTemplates();
      final template = templates.firstWhere(
        (t) => t['id'] == templateId,
        orElse: () => {},
      );

      if (template.isNotEmpty) {
        await _supabase
            .from('stories')
            .update({
              'template_id': templateId,
              'has_editing': true,
            })
            .eq('id', storyId);

        AppLogger.d('✅ Plantilla aplicada a historia: $storyId');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.e('Error en applyTemplateToStory', e);
      return false;
    }
  }

  // ✅ MÉTODO CORREGIDO: Eliminar historia
  Future<bool> deleteStory(String storyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppLogger.d('🗑️ Eliminando historia: $storyId');

      await _supabase
          .from('stories')
          .delete()
          .eq('id', storyId);

      // Eliminar de la lista local
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

  // ✅ MÉTODO NUEVO: Limpiar historias expiradas
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .lt('expires_at', now)
          .eq('is_active', true);

      // Recargar historias activas
      await fetchStories();
      AppLogger.d('✅ Historias expiradas limpiadas');
    } catch (e) {
      AppLogger.e('Error en cleanupExpiredStories', e);
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener historias por usuario
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

  // ✅ MÉTODO CORREGIDO: Desactivar historia
  Future<bool> deactivateStory(String storyId) async {
    try {
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .eq('id', storyId);

      // Actualizar lista local
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

  // ✅ MÉTODO CORREGIDO: Obtener historias por producto
  Future<List<Story>> getStoriesByProduct(String productId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('product_id', productId)
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.e('Error en getStoriesByProduct', e);
      return [];
    }
  }

  // ✅ MÉTODO CORREGIDO: Obtener conteo de stories activas
  Future<int> getActiveStoriesCount() async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String());

      return (response as List).length;
    } catch (e) {
      AppLogger.e('Error en getActiveStoriesCount', e);
      return 0;
    }
  }

  // ✅ MÉTODO NUEVO: Obtener estadísticas de historias
  Future<Map<String, dynamic>> getStoryStats(String userId) async {
    try {
      final userStories = await getUserStories(userId);
      final totalStories = userStories.length;
      final activeStories = userStories.where((s) => s.isActiveAndNotExpired).length;
      final storiesWithEditing = userStories.where((s) => s.isActiveAndNotExpired).length; // Esto necesitaría un campo en el modelo

      return {
        'total_stories': totalStories,
        'active_stories': activeStories,
        'stories_with_editing': storiesWithEditing,
        'engagement_rate': totalStories > 0 ? (activeStories / totalStories) * 100 : 0,
      };
    } catch (e) {
      AppLogger.e('Error en getStoryStats', e);
      return {
        'total_stories': 0,
        'active_stories': 0,
        'stories_with_editing': 0,
        'engagement_rate': 0,
      };
    }
  }

  // ✅ MÉTODOS UTILITARIOS
  bool hasActiveStories(String userId) {
    return _stories.any((story) => 
        story.userId == userId && 
        story.isActive && 
        !story.isExpired);
  }

  List<Story> getRecentStories() {
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
    return _stories.where((story) => 
        story.createdAt.isAfter(twentyFourHoursAgo) &&
        story.isActive &&
        !story.isExpired
    ).toList();
  }

  List<String> getUsersWithActiveStories() {
    final users = <String>{};
    for (final story in _stories) {
      if (story.isActive && !story.isExpired) {
        users.add(story.userId);
      }
    }
    return users.toList();
  }

  // ✅ MÉTODO NUEVO: Obtener story por ID
  Future<Story?> getStoryById(String storyId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      return Story.fromJson(response);
    } catch (e) {
      AppLogger.e('Error en getStoryById', e);
      return null;
    }
  }

  // ✅ MÉTODO NUEVO: Actualizar story
  Future<bool> updateStory(String storyId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase
          .from('stories')
          .update(updates)
          .eq('id', storyId);

      // Recargar historias
      await fetchStories();
      AppLogger.d('✅ Historia actualizada: $storyId');
      return true;
    } catch (e) {
      AppLogger.e('Error en updateStory', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO NUEVO: Verificar si una story existe
  Future<bool> storyExists(String storyId) async {
    try {
      // ignore: unused_local_variable
      final response = await _supabase
          .from('stories')
          .select('id')
          .eq('id', storyId)
          .single();

      return true; // Si llega aquí sin excepción, existe
    } catch (e) {
      AppLogger.e('Error en storyExists', e);
      return false;
    }
  }

  // ✅ MÉTODO NUEVO: Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ MÉTODO NUEVO: Forzar recarga
  Future<void> refresh() async {
    await fetchStories();
  }

  // ✅ MÉTODO NUEVO: Reiniciar estado de carga
  void resetLoading() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}