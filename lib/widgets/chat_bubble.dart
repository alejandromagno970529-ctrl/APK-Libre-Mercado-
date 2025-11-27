// lib/widgets/chat_bubble.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import 'file_message_widget.dart';
import 'audio_message_widget.dart';
import 'image_message_widget.dart'; // Lo crearemos después

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isFirstInSequence;
  final bool isLastInSequence;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInSequence = true,
    this.isLastInSequence = true,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    // Para mensajes que no son de texto, usar widgets especializados
    if (message.isFileMessage) {
      return FileMessageWidget(message: message, isMe: isMe);
    }
    
    if (message.isAudioMessage) {
      return AudioMessageWidget(message: message, isMe: isMe);
    }

    if (message.isImageMessage) {
      return ImageMessageWidget(message: message, isMe: isMe);
    }

    return Container(
      margin: EdgeInsets.only(
        top: isFirstInSequence ? 6 : 2,
        bottom: isLastInSequence ? 6 : 2,
        left: isMe ? 50 : 8,
        right: isMe ? 8 : 50,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _getMessageColor() : Colors.grey[50],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: Border.all(
                  color: isMe ? Colors.transparent : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mensaje de texto
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.grey[800],
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Información del mensaje (hora y estado)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[100],
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMessageColor() {
    // Gradiente de colores para mensajes propios
    return const Color(0xFF007AFF); // Azul iOS moderno
  }
}

// Widget para separadores de fecha mejorados
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hoy';
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }
}