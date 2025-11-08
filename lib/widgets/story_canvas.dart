import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';
import '../models/story_editing_models.dart';

class StoryCanvas extends StatefulWidget {
  final Uint8List? imageBytes;
  final List<StoryElement> elements;

  const StoryCanvas({
    super.key, 
    required this.imageBytes,
    required this.elements,
  });

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  String? _draggingElementId;
  Offset? _dragStartPosition;

  void _onPanStart(DragStartDetails details, String elementId) {
    setState(() {
      _draggingElementId = elementId;
      _dragStartPosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, String elementId) {
    if (_draggingElementId == elementId && _dragStartPosition != null) {
      final provider = Provider.of<StoryEditorProvider>(context, listen: false);
      final delta = details.localPosition - _dragStartPosition!;
      
      // Encontrar el elemento actual para obtener su posición
      final currentElement = widget.elements.firstWhere(
        (element) => element.id == elementId,
        orElse: () => StoryElement(
          id: '',
          type: StoryElementType.text,
          position: Offset.zero,
          content: '',
        ),
      );

      final newPosition = currentElement.position + delta;
      provider.updateElementPosition(elementId, newPosition);
      
      _dragStartPosition = details.localPosition;
    }
  }

  void _onPanEnd(DragEndDetails details, String elementId) {
    setState(() {
      _draggingElementId = null;
      _dragStartPosition = null;
    });
  }

  void _onCanvasTap(TapDownDetails details) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    final selectedTool = provider.selectedTool;
    final tapPosition = details.localPosition;

    switch (selectedTool) {
      case StoryElementType.text:
        _showAddTextDialog(tapPosition);
        break;
      case StoryElementType.sticker:
        _showStickersDialog(tapPosition);
        break;
      case StoryElementType.discountTag:
        _addDiscountTag(tapPosition);
        break;
      case StoryElementType.cta:
        _addCallToAction(tapPosition);
        break;
      default:
        provider.clearSelection();
    }
  }

  void _showAddTextDialog(Offset position) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Texto'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe tu texto aquí...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                final provider = Provider.of<StoryEditorProvider>(context, listen: false);
                provider.addSimpleText(textController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showStickersDialog(Offset position) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Sticker'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.availableStickers.length,
            itemBuilder: (context, index) {
              final sticker = provider.availableStickers[index];
              return GestureDetector(
                onTap: () {
                  provider.addSimpleSticker(sticker);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      sticker,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _addDiscountTag(Offset position) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    provider.addSimpleText('🏷️ 50% OFF');
  }

  void _addCallToAction(Offset position) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    provider.addSimpleText('👉 ¡Compra Ahora!');
  }

  void _onElementTap(String elementId) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    provider.selectElement(elementId);
  }

  void _onElementLongPress(String elementId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Elemento'),
        content: const Text('¿Quieres eliminar este elemento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<StoryEditorProvider>(context, listen: false);
              provider.deleteElement(elementId);
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);
    final selectedElementId = provider.selectedElement?.id;

    return GestureDetector(
      onTapDown: _onCanvasTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Imagen de fondo
            if (widget.imageBytes != null)
              Center(
                child: Image.memory(
                  widget.imageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            
            // Elementos editables
            ...widget.elements.map((element) {
              return Positioned(
                left: element.position.dx,
                top: element.position.dy,
                child: GestureDetector(
                  onTap: () => _onElementTap(element.id),
                  onLongPress: () => _onElementLongPress(element.id),
                  onPanStart: (details) => _onPanStart(details, element.id),
                  onPanUpdate: (details) => _onPanUpdate(details, element.id),
                  onPanEnd: (details) => _onPanEnd(details, element.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: selectedElementId == element.id
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _buildElementContent(element),
                  ),
                ),
              );
            }).toList(),

            // Indicador de herramienta seleccionada
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getToolName(provider.selectedTool),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementContent(StoryElement element) {
    switch (element.type) {
      case StoryElementType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: element.style?.backgroundColor ?? Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            element.content,
            style: element.style ?? const TextStyle(
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
          ),
        );
      case StoryElementType.sticker:
        return Text(
          element.content,
          style: const TextStyle(fontSize: 40),
        );
      case StoryElementType.discountTag:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            element.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case StoryElementType.cta:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            element.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return Text(
          element.content,
          style: const TextStyle(color: Colors.white),
        );
    }
  }

  String _getToolName(StoryElementType tool) {
    switch (tool) {
      case StoryElementType.text:
        return 'Texto';
      case StoryElementType.sticker:
        return 'Stickers';
      case StoryElementType.discountTag:
        return 'Descuento';
      case StoryElementType.cta:
        return 'CTA';
      case StoryElementType.shape:
        return 'Formas';
    }
  }
}