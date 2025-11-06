import 'dart:typed_data'; // ✅ AÑADIR ESTA IMPORTACIÓN
import 'package:flutter/material.dart';
import '../models/story_editing_models.dart';

class StoryEditorProvider with ChangeNotifier {
  StoryEditingData _editingData;
  StoryElement? _selectedElement;
  StoryElementType _selectedTool = StoryElementType.text;

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
          position: const Offset(0.5, 0.2),
          content: 'OFERTA ESPECIAL',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black),
            ],
          ),
          properties: {},
        ),
        StoryElement(
          id: 'discount_1',
          type: StoryElementType.discountTag,
          position: const Offset(0.8, 0.1),
          content: '50%',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          // ignore: deprecated_member_use
          properties: {'backgroundColor': Colors.yellow.value},
        ),
      ],
    ),
    StoryTemplate(
      id: 'new_arrival_1',
      name: 'Nuevo Producto',
      category: 'Productos',
      elements: [
        StoryElement(
          id: 'title_2',
          type: StoryElementType.text,
          position: const Offset(0.5, 0.3),
          content: '¡NUEVO!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black),
            ],
          ),
          properties: {},
        ),
      ],
    ),
  ];

  // Stickers disponibles
  final List<String> _availableStickers = [
    '🔥', '⭐', '💥', '🎯', '💎', '🚀', '📱', '🛒',
    '💰', '🎁', '👑', '⚡', '❤️', '👍', '👀', '🕒'
  ];

  StoryEditorProvider(Uint8List imageBytes)
      : _editingData = StoryEditingData(imageBytes: imageBytes);

  // Getters
  StoryEditingData get editingData => _editingData;
  StoryElement? get selectedElement => _selectedElement;
  StoryElementType get selectedTool => _selectedTool;
  List<StoryTemplate> get templates => _templates;
  List<String> get availableStickers => _availableStickers;

  // Métodos de edición
  void selectTool(StoryElementType tool) {
    _selectedTool = tool;
    _selectedElement = null;
    notifyListeners();
  }

  void addTextElement(String text, Offset position) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.text,
      position: position,
      content: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.normal,
      ),
      properties: {},
    );

    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, newElement],
    );
    _selectedElement = newElement;
    notifyListeners();
  }

  void addStickerElement(String sticker, Offset position) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.sticker,
      position: position,
      content: sticker,
      style: const TextStyle(fontSize: 30),
      properties: {},
    );

    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, newElement],
    );
    _selectedElement = newElement;
    notifyListeners();
  }

  void addCTAElement(String text, Offset position, String link) {
    final newElement = StoryElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: StoryElementType.cta,
      position: position,
      content: text,
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      properties: {'link': link},
    );

    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, newElement],
    );
    _selectedElement = newElement;
    notifyListeners();
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
      // ignore: deprecated_member_use
      properties: {'backgroundColor': Colors.red.value},
    );

    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, newElement],
    );
    _selectedElement = newElement;
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

  void updateElementContent(String elementId, String newContent) {
    final updatedElements = _editingData.elements.map((element) {
      if (element.id == elementId) {
        return element.copyWith(content: newContent);
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
    _selectedElement = _editingData.elements
        .firstWhere((element) => element.id == elementId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedElement = null;
    notifyListeners();
  }

  void applyTemplate(StoryTemplate template) {
    _editingData = _editingData.copyWith(
      elements: [..._editingData.elements, ...template.elements],
      templateId: template.id,
      style: template.style,
    );
    notifyListeners();
  }

  void clearAllElements() {
    _editingData = _editingData.copyWith(elements: []);
    _selectedElement = null;
    notifyListeners();
  }

  Uint8List get finalImage => _editingData.imageBytes;
}