// lib/widgets/typing_indicator.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/typing_provider.dart';

class TypingIndicator extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserName;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TypingProvider>(
      builder: (context, typingProvider, _) {
        // ✅ CORRECCIÓN: Obtener datos de typing sin tipo específico primero
        final dynamic typingData = typingProvider.getTypingUsers(chatId);
        
        // ✅ CORRECCIÓN: Verificar si es null o no es un Map
        if (typingData == null || typingData is! Map) {
          return const SizedBox.shrink();
        }

        // ✅ CORRECCIÓN: Convertir a Map<String, bool> de forma segura
        final Map<String, bool> typingUsers = {};
        
        try {
          typingData.forEach((key, value) {
            if (key is String && value is bool) {
              typingUsers[key] = value;
            }
          });
        } catch (e) {
          // Si hay error en la conversión, no mostrar nada
          return const SizedBox.shrink();
        }

        // ✅ CORRECCIÓN: Verificar si el mapa está vacío
        if (typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        // ✅ CORRECCIÓN: Filtrar usuarios que no sean el actual y que estén escribiendo
        final otherTypingUsers = typingUsers.entries
            .where((entry) => entry.key != currentUserId && entry.value == true)
            .toList();

        if (otherTypingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animación de puntos
              _buildTypingAnimation(),
              const SizedBox(width: 12),
              // Texto
              Text(
                otherTypingUsers.length == 1
                    ? '$otherUserName está escribiendo...'
                    : '${otherTypingUsers.length} personas están escribiendo...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingAnimation() {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedDot(0),
          _buildAnimatedDot(1),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400 + (index * 200)),
        curve: Curves.easeInOut,
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 1200 + (index * 200)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}