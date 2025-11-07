import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../providers/story_editor_provider.dart';

class ImageCropper extends StatefulWidget {
  final Uint8List imageBytes;
  final StoryEditorProvider provider;

  const ImageCropper({
    super.key, 
    required this.imageBytes,
    required this.provider,
  });

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final GlobalKey _imageKey = GlobalKey();
  late Rect _cropRect;
  Offset _startPan = Offset.zero;
  bool _isDragging = false;
  int _activeHandle = -1;

  @override
  void initState() {
    super.initState();
    // Usar cropRect del provider si existe, sino usar valor por defecto
    _cropRect = widget.provider.cropRect == Rect.zero 
        ? Rect.fromLTWH(0.1, 0.1, 0.8, 0.8)
        : widget.provider.cropRect;
  }

  void _onPanStart(DragStartDetails details) {
    final imageSize = _getImageSize();
    if (imageSize == null) return;

    final localPosition = details.localPosition;
    final relativeX = (localPosition.dx / imageSize.width).clamp(0.0, 1.0);
    final relativeY = (localPosition.dy / imageSize.height).clamp(0.0, 1.0);
    final tapPoint = Offset(relativeX, relativeY);

    _activeHandle = _getTouchedHandle(tapPoint, imageSize);
    
    if (_activeHandle == -1 && _cropRect.contains(tapPoint)) {
      _isDragging = true;
      _startPan = tapPoint;
    } else {
      _isDragging = false;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final imageSize = _getImageSize();
    if (imageSize == null) return;

    final localPosition = details.localPosition;
    final relativeX = (localPosition.dx / imageSize.width).clamp(0.0, 1.0);
    final relativeY = (localPosition.dy / imageSize.height).clamp(0.0, 1.0);
    final currentPoint = Offset(relativeX, relativeY);

    setState(() {
      if (_isDragging) {
        final delta = currentPoint - _startPan;
        _cropRect = Rect.fromLTWH(
          (_cropRect.left + delta.dx).clamp(0.0, 1.0 - _cropRect.width),
          (_cropRect.top + delta.dy).clamp(0.0, 1.0 - _cropRect.height),
          _cropRect.width,
          _cropRect.height,
        );
        _startPan = currentPoint;
      } else if (_activeHandle != -1) {
        _cropRect = _resizeFromHandle(_activeHandle, currentPoint);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _activeHandle = -1;
    _updateProviderCropRect();
  }

  int _getTouchedHandle(Offset point, Size imageSize) {
    final handles = [
      Offset(_cropRect.left, _cropRect.top),
      Offset(_cropRect.right, _cropRect.top),
      Offset(_cropRect.left, _cropRect.bottom),
      Offset(_cropRect.right, _cropRect.bottom),
    ];

    const handleSize = 0.05;
    for (int i = 0; i < handles.length; i++) {
      final handle = handles[i];
      final handleRect = Rect.fromCenter(
        center: handle,
        width: handleSize,
        height: handleSize,
      );
      if (handleRect.contains(point)) {
        return i;
      }
    }
    return -1;
  }

  Rect _resizeFromHandle(int handleIndex, Offset point) {
    double newLeft = _cropRect.left;
    double newTop = _cropRect.top;
    double newRight = _cropRect.right;
    double newBottom = _cropRect.bottom;

    switch (handleIndex) {
      case 0:
        newLeft = point.dx.clamp(0.0, newRight - 0.1);
        newTop = point.dy.clamp(0.0, newBottom - 0.1);
        break;
      case 1:
        newRight = point.dx.clamp(newLeft + 0.1, 1.0);
        newTop = point.dy.clamp(0.0, newBottom - 0.1);
        break;
      case 2:
        newLeft = point.dx.clamp(0.0, newRight - 0.1);
        newBottom = point.dy.clamp(newTop + 0.1, 1.0);
        break;
      case 3:
        newRight = point.dx.clamp(newLeft + 0.1, 1.0);
        newBottom = point.dy.clamp(newTop + 0.1, 1.0);
        break;
    }

    return Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
  }

  void _updateProviderCropRect() {
    widget.provider.updateCropRect(_cropRect);
  }

  void _applyCrop() {
    widget.provider.applyCrop(_cropRect, widget.imageBytes);
    Navigator.pop(context);
  }

  void _resetCrop() {
    setState(() {
      _cropRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
    });
    _updateProviderCropRect();
  }

  Size? _getImageSize() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Recortar Imagen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetCrop,
            tooltip: 'Reiniciar recorte',
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _applyCrop,
            tooltip: 'Aplicar recorte',
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            children: [
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
              
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(cropRect: _cropRect),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _resetCrop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Reiniciar'),
            ),
            ElevatedButton(
              onPressed: _applyCrop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

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

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(cropArea, borderPaint);

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleSize = 12.0;
    final handles = [
      Offset(cropArea.left, cropArea.top),
      Offset(cropArea.right, cropArea.top),
      Offset(cropArea.left, cropArea.bottom),
      Offset(cropArea.right, cropArea.bottom),
    ];

    for (final handle in handles) {
      canvas.drawCircle(handle, handleSize, handlePaint);
    }

    final guidePaint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = cropArea.left + cropArea.width / 2;
    canvas.drawLine(
      Offset(centerX, cropArea.top),
      Offset(centerX, cropArea.bottom),
      guidePaint,
    );

    final centerY = cropArea.top + cropArea.height / 2;
    canvas.drawLine(
      Offset(cropArea.left, centerY),
      Offset(cropArea.right, centerY),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}