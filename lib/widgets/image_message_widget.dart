// lib/widgets/image_message_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';

class ImageMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 50 : 8,
        right: isMe ? 8 : 50,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: isMe ? Colors.blue[50] : Colors.grey[100],
        child: InkWell(
          onTap: () => _showImagePreview(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen con aspect ratio mantenido
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.fileUrl!,
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Error cargando imagen'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Información de la imagen
                Text(
                  message.fileName ?? 'Imagen',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                
                if (message.fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.fileSize!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Imagen a pantalla completa
            Center(
              child: CachedNetworkImage(
                imageUrl: message.fileUrl!,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            
            // Botón de cerrar
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}