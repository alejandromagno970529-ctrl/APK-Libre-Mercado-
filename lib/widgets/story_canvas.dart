import 'dart:typed_data'; // ✅ AÑADIR ESTA IMPORTACIÓN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';
import '../models/story_editing_models.dart';

class StoryCanvas extends StatefulWidget {
  final Uint8List imageBytes;

  const StoryCanvas({super.key, required this.imageBytes});

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);

    return GestureDetector(
      onTapDown: (details) => _handleCanvasTap(details, provider),
      child: Stack(
        children: [
          // Imagen de fondo
          Center(
            child: Image.memory(
              widget.imageBytes,
              fit: BoxFit.contain,
            ),
          ),
          
          // Elementos superpuestos
          ...provider.editingData.elements.map((element) {
            return _StoryElementWidget(
              element: element,
              isSelected: provider.selectedElement?.id == element.id,
            );
          }).toList(),
        ],
      ),
    );
  }

  void _handleCanvasTap(TapDownDetails details, StoryEditorProvider provider) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    switch (provider.selectedTool) {
      case StoryElementType.text:
        _showAddTextDialog(context, localPosition);
        break;
      case StoryElementType.sticker:
        _showStickersPanel(context, localPosition);
        break;
      case StoryElementType.discountTag:
        _showDiscountDialog(context, localPosition);
        break;
      case StoryElementType.cta:
        _showCTADialog(context, localPosition);
        break;
      default:
        provider.clearSelection();
    }
  }

  void _showAddTextDialog(BuildContext context, Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Texto'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe tu texto...'),
          onSubmitted: (text) {
            if (text.isNotEmpty) {
              Provider.of<StoryEditorProvider>(context, listen: false)
                  .addTextElement(text, position);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showStickersPanel(BuildContext context, Offset position) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _StickersGrid(position: position),
    );
  }

  void _showDiscountDialog(BuildContext context, Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etiqueta de Descuento'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ej: 50%',
            suffixText: '%',
          ),
          onSubmitted: (discount) {
            if (discount.isNotEmpty) {
              Provider.of<StoryEditorProvider>(context, listen: false)
                  .addDiscountTag('$discount%', position);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCTADialog(BuildContext context, Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Llamada a la Acción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Texto del CTA',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'URL de destino',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Implementar añadir CTA
              Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}

class _StoryElementWidget extends StatelessWidget {
  final StoryElement element;
  final bool isSelected;

  const _StoryElementWidget({
    required this.element,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        onTap: () {
          Provider.of<StoryEditorProvider>(context, listen: false)
              .selectElement(element.id);
        },
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                )
              : null,
          child: _buildElementContent(),
        ),
      ),
    );
  }

  Widget _buildElementContent() {
    switch (element.type) {
      case StoryElementType.text:
        return Text(
          element.content,
          style: element.style,
        );
      case StoryElementType.sticker:
        return Text(
          element.content,
          style: element.style,
        );
      case StoryElementType.discountTag:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Color(element.properties['backgroundColor'] ?? Colors.red.value),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            element.content,
            style: element.style,
          ),
        );
      case StoryElementType.cta:
        return GestureDetector(
          onTap: () {
            // Manejar tap en CTA
          },
          child: Text(
            element.content,
            style: element.style,
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

class _StickersGrid extends StatelessWidget {
  final Offset position;

  const _StickersGrid({required this.position});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: provider.availableStickers.length,
        itemBuilder: (context, index) {
          final sticker = provider.availableStickers[index];
          return GestureDetector(
            onTap: () {
              provider.addStickerElement(sticker, position);
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
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
    );
  }
}