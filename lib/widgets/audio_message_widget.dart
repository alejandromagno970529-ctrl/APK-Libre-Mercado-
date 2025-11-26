// VERSIÓN CORREGIDA - Compatible con tu modelo Message actual
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const AudioMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  Future<void> _playAudio(BuildContext context) async {
    final audioUrl = message.fileUrl;
    if (audioUrl == null) {
      _showError(context, 'No hay URL de audio disponible');
      return;
    }
    
    final uri = Uri.parse(audioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError(context, 'No se puede reproducir el audio');
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration() {
    // Extraer duración del metadata si está disponible
    final duration = message.metadata?['duration'];
    if (duration != null) {
      // La duración puede venir en segundos (como entero o string)
      final seconds = int.tryParse(duration.toString());
      if (seconds != null) {
        final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
        final secs = (seconds % 60).toString().padLeft(2, '0');
        return '$minutes:$secs';
      }
    }
    
    // Intentar extraer del nombre del archivo o texto
    final fileName = message.fileName;
    if (fileName?.contains('duration') == true) {
      // Lógica para extraer duración del nombre del archivo si es necesario
    }
    
    return 'Audio';
  }

  String _getFileName() {
    return message.fileName ?? 'audio_${message.id.substring(0, 8)}';
  }

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
          onTap: () => _playAudio(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            width: 200,
            child: Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileName(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (message.fileSize != null)
                        Text(
                          '${message.fileSize}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}