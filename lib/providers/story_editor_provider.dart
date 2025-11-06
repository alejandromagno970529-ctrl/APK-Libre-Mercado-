import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/story_editing_models.dart';

class StoryEditorProvider with ChangeNotifier {
  late StoryEditingData _editingData;
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
          position: const Offset(100, 50),
          content: 'OFERTA ESPECIAL',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black),
            ],
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
    StoryTemplate(
      id: 'new_arrival_1',
      name: 'Nuevo Producto',
      category: 'Productos',
      elements: [
        StoryElement(
          id: 'title_2',
          type: StoryElementType.text,
          position: const Offset(100, 80),
          content: '¡NUEVO!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black),
            ],
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

  StoryEditorProvider(Uint8List imageBytes) {
    _editingData = StoryEditingData(
      imageBytes: imageBytes,
      elements: [],
    );
  }

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

  // ✅ MÉTODO MEJORADO: Ahora acepta el parámetro style correctamente
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
    _editingData = StoryEditingData(
      imageBytes: _editingData.imageBytes,
      elements: [..._editingData.elements, element],
    );
    _selectedElement = element;
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
    // Clonar elementos de la plantilla con nuevos IDs
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

  void clearAllElements() {
    _editingData = _editingData.copyWith(elements: []);
    _selectedElement = null;
    notifyListeners();
  }

  // Método para obtener la imagen final
  Uint8List get finalImage => _editingData.imageBytes;

  // Métodos para edición avanzada de elementos seleccionados
  void moveSelectedElementUp() {
    if (_selectedElement != null) {
      final newPosition = Offset(
        _selectedElement!.position.dx,
        _selectedElement!.position.dy - 10,
      );
      updateElementPosition(_selectedElement!.id, newPosition);
    }
  }

  void moveSelectedElementDown() {
    if (_selectedElement != null) {
      final newPosition = Offset(
        _selectedElement!.position.dx,
        _selectedElement!.position.dy + 10,
      );
      updateElementPosition(_selectedElement!.id, newPosition);
    }
  }

  void moveSelectedElementLeft() {
    if (_selectedElement != null) {
      final newPosition = Offset(
        _selectedElement!.position.dx - 10,
        _selectedElement!.position.dy,
      );
      updateElementPosition(_selectedElement!.id, newPosition);
    }
  }

  void moveSelectedElementRight() {
    if (_selectedElement != null) {
      final newPosition = Offset(
        _selectedElement!.position.dx + 10,
        _selectedElement!.position.dy,
      );
      updateElementPosition(_selectedElement!.id, newPosition);
    }
  }

  void changeSelectedElementColor(Color color) {
    if (_selectedElement != null) {
      final currentStyle = _selectedElement!.style ?? const TextStyle();
      final newStyle = currentStyle.copyWith(color: color);
      updateElementStyle(_selectedElement!.id, newStyle);
    }
  }

  void changeSelectedElementFontSize(double size) {
    if (_selectedElement != null) {
      final currentStyle = _selectedElement!.style ?? const TextStyle();
      final newStyle = currentStyle.copyWith(fontSize: size);
      updateElementStyle(_selectedElement!.id, newStyle);
    }
  }

  void changeSelectedElementFontWeight(FontWeight weight) {
    if (_selectedElement != null) {
      final currentStyle = _selectedElement!.style ?? const TextStyle();
      final newStyle = currentStyle.copyWith(fontWeight: weight);
      updateElementStyle(_selectedElement!.id, newStyle);
    }
  }

  // Método para duplicar elemento seleccionado
  void duplicateSelectedElement() {
    if (_selectedElement != null) {
      final original = _selectedElement!;
      final newElement = original.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: Offset(
          original.position.dx + 20,
          original.position.dy + 20,
        ),
      );

      _addElement(newElement);
    }
  }

  // Método para verificar si hay elementos
  bool get hasElements => _editingData.elements.isNotEmpty;

  // Método para obtener estadísticas de elementos
  Map<String, int> get elementsStats {
    final stats = <String, int>{};
    for (final element in _editingData.elements) {
      final type = element.type.toString();
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }

  // Método para resetear el editor
  void resetEditor() {
    _editingData = StoryEditingData(
      imageBytes: _editingData.imageBytes,
      elements: [],
    );
    _selectedElement = null;
    _selectedTool = StoryElementType.text;
    notifyListeners();
  }

  // ✅ NUEVO: Método para recortar imagen (simulación mejorada)
  void cropImage(Rect cropRect) {
    // En una implementación real, aquí procesarías la imagen
    // Por ahora, solo notificamos que se recortó
    notifyListeners();
  }

  // ✅ NUEVO: Método para rotar imagen
  void rotateImage() {
    // En una implementación real, aquí rotarías la imagen
    // Por ahora, solo notificamos
    notifyListeners();
  }

  // ✅ NUEVO: Método para ajustar brillo
  void adjustBrightness(double value) {
    // En una implementación real, aquí ajustarías el brillo
    // Por ahora, solo notificamos
    notifyListeners();
  }

  // ✅ NUEVO: Método para ajustar contraste
  void adjustContrast(double value) {
    // En una implementación real, aquí ajustarías el contraste
    // Por ahora, solo notificamos
    notifyListeners();
  }
}