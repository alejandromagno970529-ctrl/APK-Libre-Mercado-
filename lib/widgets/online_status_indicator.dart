// CONTENIDO COMPLETO - Copiar y pegar en nuevo archivo
// lib/widgets/online_status_indicator.dart - NUEVO
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnlineStatusIndicator extends StatelessWidget {
  final String? status;
  final DateTime? lastSeen;
  final double indicatorSize;
  final bool showText;

  const OnlineStatusIndicator({
    super.key,
    this.status,
    this.lastSeen,
    this.indicatorSize = 8,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = status == 'online';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: indicatorSize,
          height: indicatorSize,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            isOnline 
                ? 'En línea' 
                : _formatLastSeen(lastSeen),
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      // ignore: unnecessary_brace_in_string_interps
      return 'Hace ${minutes} min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      // ignore: unnecessary_brace_in_string_interps
      return 'Hace ${hours} h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      // ignore: unnecessary_brace_in_string_interps
      return 'Hace ${days} d';
    } else {
      return DateFormat('d MMM').format(lastSeen);
    }
  }
}