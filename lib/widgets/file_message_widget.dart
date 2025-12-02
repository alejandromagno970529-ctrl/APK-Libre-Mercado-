// lib/widgets/file_message_widget.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/message_model.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onLongPress;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: isMe ? Colors.blue[50] : Colors.grey[100],
              child: InkWell(
                onTap: () => _openFile(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono y nombre del archivo
                      Row(
                        children: [
                          _buildFileIcon(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.fileName ?? 'Archivo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Tamaño del archivo
                      if (message.fileSize != null)
                        Text(
                          message.fileSize!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Botón de descarga
                      // ignore: prefer_const_constructors
                      Row(
                        // ignore: prefer_const_literals_to_create_immutables
                        children: [
                          // ignore: prefer_const_constructors
                          Icon(
                            Icons.download_rounded,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          // ignore: prefer_const_constructors
                          Text(
                            'Descargar',
                            // ignore: prefer_const_constructors
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Hora del mensaje
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final mimeType = message.mimeType ?? '';
    final fileName = message.fileName ?? '';
    
    if (mimeType.contains('pdf') || fileName.toLowerCase().endsWith('.pdf')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
    } else if (mimeType.contains('image') || 
               fileName.toLowerCase().contains('.jpg') ||
               fileName.toLowerCase().contains('.jpeg') ||
               fileName.toLowerCase().contains('.png')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.image, color: Colors.green, size: 32);
    } else if (mimeType.contains('audio') || 
               fileName.toLowerCase().contains('.mp3') ||
               fileName.toLowerCase().contains('.wav')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.audiotrack, color: Colors.purple, size: 32);
    } else if (mimeType.contains('video') || 
               fileName.toLowerCase().contains('.mp4') ||
               fileName.toLowerCase().contains('.mov')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.videocam, color: Colors.orange, size: 32);
    } else if (fileName.toLowerCase().endsWith('.doc') || 
               fileName.toLowerCase().endsWith('.docx')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.description, color: Colors.blue, size: 32);
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      // ignore: prefer_const_constructors
      return Icon(Icons.text_snippet, color: Colors.grey, size: 32);
    } else {
      // ignore: prefer_const_constructors
      return Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (message.fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay URL de archivo disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final uri = Uri.parse(message.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el archivo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error abriendo archivo', e);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}