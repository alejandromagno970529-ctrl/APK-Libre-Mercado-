import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isFirstInSequence; // Si es el primero de un bloque del mismo usuario
  final bool isLastInSequence;  // Si es el último de un bloque
  final bool isFirstOfDate;     // Si hay que mostrar la fecha arriba

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInSequence = true,
    this.isLastInSequence = true,
    this.isFirstOfDate = false,
  });

  @override
  Widget build(BuildContext context) {
    // Definir bordes dinámicos según la secuencia
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isMe 
          ? const Radius.circular(12) 
          : (isLastInSequence ? Radius.zero : const Radius.circular(12)),
      bottomRight: isMe 
          ? (isLastInSequence ? Radius.zero : const Radius.circular(12)) 
          : const Radius.circular(12),
    );

    // Margen reducido si es parte de una secuencia
    final double marginBottom = isLastInSequence ? 8.0 : 2.0;

    return Column(
      children: [
        if (isFirstOfDate) _buildDateChip(message.createdAt),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.fromLTRB(
              isMe ? 60 : 10, // Margen lateral para no ocupar todo el ancho
              0,
              isMe ? 10 : 60,
              marginBottom
            ),
            child: Material(
              elevation: 1,
              borderRadius: borderRadius,
              color: isMe ? const Color(0xFFE7FFDB) : Colors.white, // Color WhatsApp moderno
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Stack(
                  children: [
                    // Texto del mensaje con padding extra para la hora
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, right: 10), 
                      child: Text(
                        message.text,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    // Hora y Checks posicionados absolutamente en la esquina inferior derecha
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.createdAt),
                            style: TextStyle(
                              fontSize: 11, 
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.read ? Icons.done_all : Icons.done,
                              size: 16,
                              color: message.read ? Colors.blue : Colors.grey[500],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDDDDDD), // Gris suave para fondo de fecha
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatDate(date),
          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Hoy';
    if (messageDate == yesterday) return 'Ayer';
    return DateFormat('d MMM yyyy').format(date);
  }
}