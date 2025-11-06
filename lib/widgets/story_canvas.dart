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
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        // ✅ CORREGIDO: Solo manejar taps para seleccionar elementos, NO para crear
        onTapDown: (details) => _handleCanvasTap(details, provider),
        child: Stack(
          key: _canvasKey,
          clipBehavior: Clip.none,
          children: [
            // Imagen de fondo centrada y contenida
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Elementos superpuestos
            ...provider.editingData.elements.map((element) {
              return _StoryElementWidget(
                key: ValueKey(element.id),
                element: element,
                isSelected: provider.selectedElement?.id == element.id,
                onDelete: () => provider.deleteElement(element.id),
                canvasKey: _canvasKey,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ✅ CORREGIDO: Solo seleccionar elementos existentes, NO crear nuevos automáticamente
  void _handleCanvasTap(TapDownDetails details, StoryEditorProvider provider) {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Verificar que el tap esté dentro de los límites razonables del canvas
    final size = renderBox.size;
    if (localPosition.dx < 0 || localPosition.dx > size.width ||
        localPosition.dy < 0 || localPosition.dy > size.height) {
      provider.clearSelection();
      return;
    }
    
    // ✅ SOLO limpiar selección al tocar áreas vacías
    // NO abrir diálogos automáticamente
    provider.clearSelection();
  }
}

class _StoryElementWidget extends StatefulWidget {
  final StoryElement element;
  final bool isSelected;
  final VoidCallback onDelete;
  final GlobalKey canvasKey;

  const _StoryElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onDelete,
    required this.canvasKey,
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

  void _updatePosition(Offset newPosition) {
    final renderBox = widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    
    // Limitar la posición dentro de los límites del canvas con márgenes
    final constrainedX = newPosition.dx.clamp(0.0, size.width - 50);
    final constrainedY = newPosition.dy.clamp(0.0, size.height - 50);
    
    setState(() {
      _position = Offset(constrainedX, constrainedY);
    });
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
          _updatePosition(_position + details.delta);
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          Provider.of<StoryEditorProvider>(context, listen: false)
              .updateElementPosition(widget.element.id, _position);
        },
        child: Stack(
          clipBehavior: Clip.none,
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
                top: -8,
                right: -8,
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
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: safeStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
          constraints: const BoxConstraints(
            minWidth: 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            widget.element.content,
            style: safeStyle,
            textAlign: TextAlign.center,
          ),
        );
        
      case StoryElementType.cta:
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CTA: ${widget.element.content}'),
                backgroundColor: Colors.black,
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 80,
            ),
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
              textAlign: TextAlign.center,
            ),
          ),
        );
        
      default:
        return Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: safeStyle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }
}