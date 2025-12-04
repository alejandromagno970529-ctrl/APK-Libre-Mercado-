// lib/widgets/chat_bubble.dart - VERSIÓN COMPLETAMENTE CORREGIDA CON AVATARES E INDICADORES
import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool isTemporary;
  final String? userAvatarUrl; // ✅ NUEVO: URL del avatar real
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.isTemporary = false,
    this.userAvatarUrl, // ✅ NUEVO: Avatar real del usuario
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isTemporary 
                          ? Colors.grey[300] // ✅ Color diferente para mensajes temporales
                          : (isMe ? Colors.black : Colors.grey[100]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isTemporary 
                                ? Colors.grey[600] // ✅ Texto diferente para temporales
                                : (isMe ? Colors.white : Colors.black),
                            fontSize: 16,
                          ),
                        ),
                        if (isTemporary) // ✅ Indicador visual para mensajes temporales
                          const SizedBox(height: 4),
                        if (isTemporary)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Enviando...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // ✅ CORRECCIÓN: Mostrar tiempo e indicadores de estado
                  if (isMe && !isTemporary) 
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // ✅ INDICADORES DE ESTADO (PALOMILLAS)
                        Icon(
                          message.read ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.read ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ),
                  
                  if (!isMe || isTemporary)
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
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

  // ✅ CORRECCIÓN: Avatar real con imagen de perfil
  Widget _buildAvatar() {
    // ✅ USAR AVATAR REAL SI ESTÁ DISPONIBLE
    if (userAvatarUrl != null && userAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        backgroundImage: NetworkImage(userAvatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // ✅ Fallback si la imagen no carga
        },
        child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
            ? null
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
      );
    }
    
    // ✅ AVATAR POR DEFECTO
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}