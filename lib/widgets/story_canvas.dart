import 'dart:typed_data';
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
              key: ValueKey(element.id),
              element: element,
              isSelected: provider.selectedElement?.id == element.id,
              onDelete: () => provider.deleteElement(element.id),
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
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Añadir Texto',
          style: TextStyle(color: Colors.black),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe tu texto...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Provider.of<StoryEditorProvider>(context, listen: false)
                    .addTextElement(text, position);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Añadir',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showStickersPanel(BuildContext context, Offset position) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => _StickersGrid(position: position),
    );
  }

  void _showDiscountDialog(BuildContext context, Offset position) {
    final discountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Etiqueta de Descuento',
          style: TextStyle(color: Colors.black),
        ),
        content: TextField(
          controller: discountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ej: 50',
            suffixText: '%',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              final discount = discountController.text.trim();
              if (discount.isNotEmpty) {
                Provider.of<StoryEditorProvider>(context, listen: false)
                    .addDiscountTag('$discount%', position);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Añadir',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showCTADialog(BuildContext context, Offset position) {
    final textController = TextEditingController();
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Añadir Llamada a la Acción',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Texto del CTA',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'URL de destino',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              final url = urlController.text.trim();
              if (text.isNotEmpty && url.isNotEmpty) {
                Provider.of<StoryEditorProvider>(context, listen: false)
                    .addCTAElement(text, position, url);
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Añadir',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryElementWidget extends StatefulWidget {
  final StoryElement element;
  final bool isSelected;
  final VoidCallback onDelete;

  const _StoryElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onDelete,
  });

  @override
  State<_StoryElementWidget> createState() => __StoryElementWidgetState();
}

class __StoryElementWidgetState extends State<_StoryElementWidget> {
  Offset _position = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.element.position;
  }

  @override
  void didUpdateWidget(_StoryElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.position != widget.element.position) {
      _position = widget.element.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () {
          Provider.of<StoryEditorProvider>(context, listen: false)
              .selectElement(widget.element.id);
        },
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
          Provider.of<StoryEditorProvider>(context, listen: false)
              .selectElement(widget.element.id);
        },
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          Provider.of<StoryEditorProvider>(context, listen: false)
              .updateElementPosition(widget.element.id, _position);
        },
        child: Stack(
          children: [
            Container(
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: _buildElementContent(),
            ),
            
            // Botón de eliminar (solo cuando está seleccionado)
            if (widget.isSelected && !_isDragging)
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementContent() {
    // Función auxiliar para obtener el estilo seguro
    TextStyle getSafeStyle() {
      if (widget.element.style != null) {
        return widget.element.style!;
      }
      
      // Estilos por defecto según el tipo de elemento
      switch (widget.element.type) {
        case StoryElementType.text:
          return const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          );
        case StoryElementType.sticker:
          return const TextStyle(fontSize: 30);
        case StoryElementType.discountTag:
          return const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          );
        case StoryElementType.cta:
          return const TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          );
        default:
          return const TextStyle(
            color: Colors.white,
            fontSize: 18,
          );
      }
    }

    final safeStyle = getSafeStyle();

    switch (widget.element.type) {
      case StoryElementType.text:
        return Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: safeStyle,
          ),
        );
        
      case StoryElementType.sticker:
        return Container(
          padding: const EdgeInsets.all(4),
          child: Text(
            widget.element.content,
            style: safeStyle,
          ),
        );
        
      case StoryElementType.discountTag:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            widget.element.content,
            style: safeStyle,
          ),
        );
        
      case StoryElementType.cta:
        return GestureDetector(
          onTap: () {
            // Manejar tap en CTA - abrir URL
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CTA: ${widget.element.content}'),
                backgroundColor: Colors.black,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              widget.element.content,
              style: safeStyle,
            ),
          ),
        );
        
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: safeStyle,
          ),
        );
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
      color: Colors.white,
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