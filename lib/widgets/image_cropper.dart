import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';

class ImageCropper extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropper({super.key, required this.imageBytes});

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final GlobalKey _imageKey = GlobalKey();
  Rect _currentCropRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    _currentCropRect = provider.cropRect;
  }

  void _updateCropRect(Offset localPosition, Size imageSize) {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Convertir posición a coordenadas relativas (0-1)
    final relativeX = (localPosition.dx / imageSize.width).clamp(0.0, 1.0);
    final relativeY = (localPosition.dy / imageSize.height).clamp(0.0, 1.0);

    // Actualizar rectángulo de recorte (ejemplo: área central)
    setState(() {
      _currentCropRect = Rect.fromCenter(
        center: Offset(relativeX, relativeY),
        width: 0.6,
        height: 0.6,
      );
    });

    Provider.of<StoryEditorProvider>(context, listen: false)
        .updateCropRect(_currentCropRect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Recortar Imagen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Provider.of<StoryEditorProvider>(context, listen: false).applyCrop();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onPanUpdate: (details) {
            final imageSize = _getImageSize();
            if (imageSize != null) {
              _updateCropRect(details.localPosition, imageSize);
            }
          },
          child: Stack(
            children: [
              // Imagen
              Container(
                key: _imageKey,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
              
              // Overlay de recorte
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(cropRect: _currentCropRect),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botones de relación de aspecto
            _buildAspectRatioButton('1:1', 1.0),
            _buildAspectRatioButton('4:5', 4/5),
            _buildAspectRatioButton('9:16', 9/16),
            _buildAspectRatioButton('Original', 0),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, double ratio) {
    return ElevatedButton(
      onPressed: () {
        // Implementar cambio de relación de aspecto
      },
      child: Text(label),
    );
  }

  Size? _getImageSize() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Área exterior (oscurecida)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Área interior (transparente)
    final cropArea = Rect.fromLTWH(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.width * size.width,
      cropRect.height * size.height,
    );

    canvas.save();
    canvas.clipRect(cropArea);
    canvas.drawColor(Colors.transparent, BlendMode.clear);
    canvas.restore();

    // Bordes del área de recorte
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(cropArea, borderPaint);

    // Mangos de redimensionamiento
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const handleSize = 8.0;
    final handles = [
      Offset(cropArea.left, cropArea.top), // Top-left
      Offset(cropArea.right, cropArea.top), // Top-right
      Offset(cropArea.left, cropArea.bottom), // Bottom-left
      Offset(cropArea.right, cropArea.bottom), // Bottom-right
    ];

    for (final handle in handles) {
      canvas.drawCircle(handle, handleSize, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}