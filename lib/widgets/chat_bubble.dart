// lib/widgets/chat_bubble.dart - VERSIÓN COMPLETA MEJORADA
import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool isTemporary;
  final String? userAvatarUrl;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.isTemporary = false,
    this.userAvatarUrl,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar) _buildAvatar(),
            if (!isMe) const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isTemporary 
                          ? Colors.grey[300]
                          : (isMe ? const Color(0xFF1E88E5) : Colors.grey[100]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        if (!isTemporary)
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
                        // Nombre del remitente (solo para mensajes de otros)
                        if (!isMe && message.fromName != null && message.fromName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.fromName!,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        
                        // Texto del mensaje
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isTemporary 
                                ? Colors.grey[600]
                                : (isMe ? Colors.white : Colors.black),
                            fontSize: 16,
                          ),
                        ),
                        
                        // Indicador de envío pendiente
                        if (isTemporary)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isMe ? Colors.white70 : Colors.grey[600]!,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Enviando...',
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey[600],
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Indicador de archivo o imagen
                        if (message.isFileMessage || message.isImageMessage)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  message.isImageMessage ? Icons.image : Icons.insert_drive_file,
                                  size: 16,
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    message.fileName ?? 'Archivo',
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Fila con hora y estado del mensaje
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        // Hora del mensaje
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        
                        // Espaciado
                        const SizedBox(width: 6),
                        
                        // Indicadores de estado (solo para mensajes míos y no temporales)
                        if (isMe && !isTemporary)
                          _buildMessageStatus(message, isMe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isMe && showAvatar) const SizedBox(width: 8),
            if (isMe && showAvatar) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  // Widget para construir el avatar
  Widget _buildAvatar() {
    if (userAvatarUrl != null && userAvatarUrl!.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            userAvatarUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 20,
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isMe ? const Color(0xFF1E88E5) : Colors.grey[300],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        color: isMe ? Colors.white : Colors.grey[600],
        size: 20,
      ),
    );
  }

  // Widget para construir el indicador de estado del mensaje
  Widget _buildMessageStatus(Message message, bool isMe) {
    if (!isMe) return const SizedBox.shrink();
    
    IconData icon;
    Color color;
    
    if (message.read) {
      icon = Icons.done_all;
      color = const Color(0xFF4CAF50); // Verde para leído
    // ignore: invalid_null_aware_operator
    } else if (message.metadata?['delivered'] == true) {
      icon = Icons.done_all;
      color = Colors.grey[600]!; // Gris para entregado
    // ignore: invalid_null_aware_operator
    } else if (message.metadata?['sent'] == true) {
      icon = Icons.done;
      color = Colors.grey[600]!; // Gris para enviado
    } else {
      icon = Icons.access_time;
      color = Colors.orange; // Naranja para pendiente
    }
    
    return Icon(icon, size: 14, color: color);
  }

  // Formatear la hora
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}