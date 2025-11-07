import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/story_editing_models.dart';

class StoryEditorProvider with ChangeNotifier {
  StoryEditingData _editingData;
  StoryElement? _selectedElement;
  StoryElementType _selectedTool = StoryElementType.text;
  String? _productId;
  
  // ✅ NUEVO: Propiedades para el crop
  Rect _cropRect = Rect.zero;
  bool _isCropping = false;

  StoryEditorProvider() : _editingData = StoryEditingData.empty();

  StoryEditorProvider.withImage({required Uint8List imageBytes}) 
      : _editingData = StoryEditingData(
          imageBytes: imageBytes, 
          elements: [],
        );

  // Getters
  StoryEditingData get editingData => _editingData;
  StoryElement? get selectedElement => _selectedElement;
  StoryElementType get selectedTool => _selectedTool;
  String? get productId => _productId;
  
  Uint8List? get backgroundImageBytes => _editingData.imageBytes;
  List<StoryElement> get elements => _editingData.elements;
  
  // ✅ NUEVO: Getters para crop
  Rect get cropRect => _cropRect;
  bool get isCropping => _isCropping;

  // ✅ NUEVO: Plantillas predefinidas
  List<StoryTemplate> get templates => [
    StoryTemplate(
      id: 'template_1',
      name: 'Plantilla Simple',
      category: 'Básico',
      elements: [
        StoryElement(
          id: 'title_1',
          type: StoryElementType.text,
          position: const Offset(50, 100),
          content: 'Nueva Oferta',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black),
            ],
          ),
        ),
      ],
    ),
    StoryTemplate(
      id: 'template_2',
      name: 'Descuento',
      category: 'Promoción',
      elements: [
        StoryElement(
          id: 'title_2',
          type: StoryElementType.text,
          position: const Offset(50, 100),
          content: '50% OFF',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.white),
            ],
          ),
        ),
        StoryElement(
          id: 'sticker_1',
          type: StoryElementType.sticker,
          position: const Offset(200, 200),
          content: '🔥',
          style: const TextStyle(fontSize: 50),
        ),
      ],
    ),
    StoryTemplate(
      id: 'template_3',
      name: 'Llamada a la acción',
      category: 'Marketing',
      elements: [
        StoryElement(
          id: 'cta_1',
          type: StoryElementType.cta,
          position: const Offset(50, 300),
          content: '¡Compra ahora!',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    ),
  ];

  // ✅ NUEVO: Método para obtener templates
  List<StoryTemplate> getTemplates() {
    return templates;
  }

  // ✅ NUEVO: Método para aplicar plantilla
  void applyTemplate(StoryTemplate template) {
    for (final element in template.elements) {
      final newElement = element.copyWith(
        id: '${element.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      _addElement(newElement);
    }
    notifyListeners();
  }

  // Stickers disponibles
  final List<String> _availableStickers = [
    '🔥', '⭐', '💥', '🎯', '💎', '🚀', '📱', '🛒',
    '💰', '🎁', '👑', '⚡', '❤️', '👍'
  ];

  List<String> get availableStickers => _availableStickers;

  // Métodos principales
  void setBackgroundImage(Uint8List imageBytes) {
    _editingData = _editingData.copyWith(imageBytes: imageBytes);
    notifyListeners();
  }

  void setProductId(String? productId) {
    _productId = productId;
    notifyListeners();
  }

  void clearEditor() {
    _editingData = StoryEditingData(
      imageBytes: _editingData.imageBytes,
      elements: [],
    );
    _selectedElement = null;
    _selectedTool = StoryElementType.text;
    _productId = null;
    _cropRect = Rect.zero;
    _isCropping = false;
    notifyListeners();
  }

  // ✅ NUEVO: Métodos para crop
  void updateCropRect(Rect rect) {
    _cropRect = rect;
    notifyListeners();
  }

  void applyCrop(Rect cropRect, Uint8List imageBytes) {
    // Aquí iría la lógica real de recorte de imagen
    // Por ahora, simplemente actualizamos el estado
    _cropRect = cropRect;
    _isCropping = false;
    
    // En una implementación real, aquí procesarías la imagen:
    // final croppedImage = _cropImage(imageBytes, cropRect);
    // _editingData = _editingData.copyWith(imageBytes: croppedImage);
    
    notifyListeners();
  }

  void startCropping() {
    _isCropping = true;
    _cropRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    notifyListeners();
  }

  void cancelCropping() {
    _isCropping = false;
    _cropRect = Rect.zero;
    notifyListeners();
  }

  // Métodos para agregar elementos
  void addSimpleText(String text) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.text,
      position: const Offset(100, 100),
      content: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 10,
            color: Colors.black,
          ),
        ],
      ),
    );
    _addElement(newElement);
  }

  void addSimpleSticker(String sticker) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.sticker,
      position: const Offset(150, 150),
      content: sticker,
      style: const TextStyle(fontSize: 40),
    );
    _addElement(newElement);
  }

  void _addElement(StoryElement element) {
    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, element],
    );
    _selectedElement = element;
    notifyListeners();
  }

  // Gestión de elementos
  void selectTool(StoryElementType tool) {
    _selectedTool = tool;
    _selectedElement = null;
    notifyListeners();
  }

  void updateElementPosition(String elementId, Offset newPosition) {
    final updatedElements = _editingData.elements.map((element) {
      if (element.id == elementId) {
        return element.copyWith(position: newPosition);
      }
      return element;
    }).toList();

    _editingData = _editingData.copyWith(elements: updatedElements);
    notifyListeners();
  }

  void deleteElement(String elementId) {
    final updatedElements = _editingData.elements
        .where((element) => element.id != elementId)
        .toList();

    _editingData = _editingData.copyWith(elements: updatedElements);
    
    if (_selectedElement?.id == elementId) {
      _selectedElement = null;
    }
    notifyListeners();
  }

  void selectElement(String elementId) {
    try {
      _selectedElement = _editingData.elements
          .firstWhere((element) => element.id == elementId);
      notifyListeners();
    } catch (e) {
      _selectedElement = null;
    }
  }

  void clearSelection() {
    _selectedElement = null;
    notifyListeners();
  }

  // Métodos utilitarios
  List<StoryElement> getTextElements() {
    return _editingData.elements.where((element) => element.type == StoryElementType.text).toList();
  }

  List<StoryElement> getStickerElements() {
    return _editingData.elements.where((element) => element.type == StoryElementType.sticker).toList();
  }

  bool get hasElements => _editingData.elements.isNotEmpty;
  bool get hasImage => _editingData.imageBytes != null;

  void resetTool() {
    _selectedTool = StoryElementType.text;
    _selectedElement = null;
    notifyListeners();
  }
}