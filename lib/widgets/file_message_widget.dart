// lib/widgets/file_message_widget.dart
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const FileMessageWidget({
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
                        style: TextStyle(
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
                Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Descargar',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Hora
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final mimeType = message.mimeType ?? '';
    final fileName = message.fileName ?? '';
    
    if (mimeType.contains('pdf') || fileName.toLowerCase().endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: Colors.red, size: 32);
    } else if (mimeType.contains('image') || 
               fileName.toLowerCase().contains('.jpg') ||
               fileName.toLowerCase().contains('.jpeg') ||
               fileName.toLowerCase().contains('.png')) {
      return Icon(Icons.image, color: Colors.green, size: 32);
    } else if (mimeType.contains('audio') || 
               fileName.toLowerCase().contains('.mp3') ||
               fileName.toLowerCase().contains('.wav')) {
      return Icon(Icons.audiotrack, color: Colors.purple, size: 32);
    } else if (mimeType.contains('video') || 
               fileName.toLowerCase().contains('.mp4') ||
               fileName.toLowerCase().contains('.mov')) {
      return Icon(Icons.videocam, color: Colors.orange, size: 32);
    } else if (fileName.toLowerCase().endsWith('.doc') || 
               fileName.toLowerCase().endsWith('.docx')) {
      return Icon(Icons.description, color: Colors.blue, size: 32);
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return Icon(Icons.text_snippet, color: Colors.grey, size: 32);
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey, size: 32);
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (message.fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el archivo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error abriendo archivo', e);
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