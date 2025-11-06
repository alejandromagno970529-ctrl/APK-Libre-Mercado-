import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/story_editing_models.dart';

class StoryEditorProvider with ChangeNotifier {
  StoryEditingData _editingData;
  StoryElement? _selectedElement;
  StoryElementType _selectedTool = StoryElementType.text;
  Rect _cropRect = Rect.zero;
  bool _isCropping = false;

  StoryEditorProvider({required Uint8List imageBytes}) 
      : _editingData = StoryEditingData(imageBytes: imageBytes, elements: []);

  // Getters
  StoryEditingData get editingData => _editingData;
  StoryElement? get selectedElement => _selectedElement;
  StoryElementType get selectedTool => _selectedTool;
  Rect get cropRect => _cropRect;
  bool get isCropping => _isCropping;
  
  // Plantillas predefinidas
  final List<StoryTemplate> _templates = [
    StoryTemplate(
      id: 'promo_1',
      name: 'Oferta Especial',
      category: 'Promociones',
      elements: [
        StoryElement(
          id: 'title_1',
          type: StoryElementType.text,
          position: const Offset(100, 50),
          content: 'OFERTA ESPECIAL',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
        ),
        StoryElement(
          id: 'discount_1',
          type: StoryElementType.discountTag,
          position: const Offset(250, 30),
          content: '50%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ];

  // Stickers disponibles
  final List<String> _availableStickers = [
    '🔥', '⭐', '💥', '🎯', '💎', '🚀', '📱', '🛒',
    '💰', '🎁', '👑', '⚡', '❤️', '👍', '👀', '🕒'
  ];

  List<StoryTemplate> get templates => _templates;
  List<String> get availableStickers => _availableStickers;

  // ✅ MÉTODOS COMPLETOS - SIN ERRORES
  void addTextElement(String text, Offset position, {TextStyle? style}) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.text,
      position: position,
      content: text,
      style: style ?? const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
    );
    _addElement(newElement);
  }

  void addStickerElement(String sticker, Offset position) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.sticker,
      position: position,
      content: sticker,
      style: const TextStyle(fontSize: 30),
    );
    _addElement(newElement);
  }

  void addCTAElement(String text, Offset position, String url) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.cta,
      position: position,
      content: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      properties: {'url': url},
    );
    _addElement(newElement);
  }

  void addDiscountTag(String discount, Offset position) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.discountTag,
      position: position,
      content: discount,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
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

  // Métodos de gestión
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

  void updateElementStyle(String elementId, TextStyle newStyle) {
    final updatedElements = _editingData.elements.map((element) {
      if (element.id == elementId) {
        return element.copyWith(style: newStyle);
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

  void applyTemplate(StoryTemplate template) {
    final clonedElements = template.elements.map((element) {
      return element.copyWith(
        id: '${DateTime.now().millisecondsSinceEpoch}_${element.id}',
      );
    }).toList();

    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, ...clonedElements],
    );
    notifyListeners();
  }

  // Métodos de edición de imagen
  void cropImage(Rect cropRect) {
    _cropRect = cropRect;
    notifyListeners();
  }

  void rotateImage() => notifyListeners();
  void adjustBrightness(double value) => notifyListeners();
  void adjustContrast(double value) => notifyListeners();

  // Métodos para recorte interactivo
  void startCropping() {
    _isCropping = true;
    _cropRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    notifyListeners();
  }

  void updateCropRect(Rect newRect) {
    _cropRect = newRect;
    notifyListeners();
  }

  void applyCrop() {
    _isCropping = false;
    notifyListeners();
  }

  void cancelCrop() {
    _isCropping = false;
    _cropRect = Rect.zero;
    notifyListeners();
  }

  Uint8List get finalImage => _editingData.imageBytes;
}