// CONTENIDO COMPLETO - Copiar y pegar en nuevo archivo
// lib/widgets/notification_badge.dart - NUEVO
import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color color;
  final Color textColor;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.color = Colors.red,
    this.textColor = Colors.white,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if ((count <= 0 && !showZero) || count > 99) {
      return const SizedBox.shrink();
    }

    final badgeCount = count > 99 ? '99+' : count.toString();
    final fontSize = badgeCount.length > 2 ? 8.0 : 10.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          badgeCount,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}