// lib/widgets/image_message_widget.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final_app/models/message_model.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class ImageMessageWidget extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onLongPress;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
  });

  @override
  State<ImageMessageWidget> createState() => _ImageMessageWidgetState();
}

class _ImageMessageWidgetState extends State<ImageMessageWidget> {
  bool _isImageLoading = true;
  bool _hasImageError = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d('🖼️ INICIANDO ImageMessageWidget - URL: ${widget.message.fileUrl}');
    _verifyImageUrl();
  }

  Future<void> _verifyImageUrl() async {
    try {
      final imageUrl = widget.message.fileUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        AppLogger.e('❌ URL de imagen vacía o nula');
        setState(() {
          _hasImageError = true;
          _isImageLoading = false;
        });
        return;
      }

      AppLogger.d('🔍 Verificando URL de imagen: $imageUrl');
      
      // Verificar que la URL sea válida
      final uri = Uri.tryParse(imageUrl);
      if (uri == null) {
        AppLogger.e('❌ URL de imagen inválida: $imageUrl');
        setState(() {
          _hasImageError = true;
          _isImageLoading = false;
        });
        return;
      }

      setState(() {
        _isImageLoading = false;
        _hasImageError = false;
      });
      
    } catch (e) {
      AppLogger.e('❌ Error verificando imagen: $e');
      setState(() {
        _hasImageError = true;
        _isImageLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.message.fileUrl;
    
    AppLogger.d('🎨 Construyendo ImageMessageWidget - URL: $imageUrl, Cargando: $_isImageLoading, Error: $_hasImageError');

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: widget.isMe ? 60 : 12,
          right: widget.isMe ? 12 : 60,
        ),
        child: Column(
          crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ✅ CONTENEDOR PRINCIPAL MEJORADO
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              color: widget.isMe ? Colors.blue[50] : Colors.grey[50],
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ IMAGEN CON MEJOR MANEJO DE ESTADOS
                    _buildImageContent(context, imageUrl),
                    
                    // ✅ INFORMACIÓN DEL ARCHIVO
                    if (widget.message.fileName != null || widget.message.fileSize != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                        child: _buildFileInfo(),
                      ),
                  ],
                ),
              ),
            ),
            
            // ✅ INFORMACIÓN DE TIEMPO Y ESTADO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(widget.message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  
                  if (widget.isMe) ...[
                    const SizedBox(width: 6),
                    Icon(
                      widget.message.read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: widget.message.read ? Colors.blue : Colors.grey,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, String? imageUrl) {
    if (_hasImageError || imageUrl == null || imageUrl.isEmpty) {
      return _buildErrorContent('No se pudo cargar la imagen');
    }

    if (_isImageLoading) {
      return _buildLoadingPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // ✅ CACHED NETWORK IMAGE CON MEJOR MANEJO
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) {
                AppLogger.e('❌ CachedNetworkImage error: $error - URL: $url');
                return _buildErrorContent('Error al cargar');
              },
              imageBuilder: (context, imageProvider) {
                AppLogger.d('✅ Imagen cargada exitosamente en CachedNetworkImage');
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            
            // ✅ BOTÓN DE AMPLIAR
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Cargando imagen...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String error) {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _retryImageLoad,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  void _retryImageLoad() {
    setState(() {
      _isImageLoading = true;
      _hasImageError = false;
    });
    _verifyImageUrl();
  }

  Widget _buildFileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.fileName != null)
          Text(
            _getCleanFileName(widget.message.fileName!),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        
        if (widget.message.fileSize != null)
          Row(
            children: [
              Text(
                widget.message.fileSize!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '•',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Imagen',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _getCleanFileName(String fileName) {
    if (fileName.length > 30) {
      return '${fileName.substring(0, 25)}...';
    }
    return fileName;
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black87,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => _buildLoadingPlaceholder(),
                  errorWidget: (context, url, error) => _buildErrorContent('Error al cargar imagen'),
                ),
              ),
            ),
            
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}