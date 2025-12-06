import 'package:flutter/material.dart';

class ChatBadgeIndicator extends StatelessWidget {
  final int unreadCount;
  final bool isTyping;
  final double size;

  const ChatBadgeIndicator({
    super.key,
    this.unreadCount = 0,
    this.isTyping = false,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay notificaciones ni typing, no mostrar nada
    if (unreadCount <= 0 && !isTyping) {
      return const SizedBox.shrink();
    }

    // Prioridad: mostrar número de notificaciones no leídas
    if (unreadCount > 0) {
      return _buildUnreadBadge();
    }
    
    // Si no hay notificaciones pero alguien está escribiendo
    return _buildTypingIndicator();
  }

  Widget _buildUnreadBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.red.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          unreadCount > 9 ? '9+' : unreadCount.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}