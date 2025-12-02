// CONTENIDO COMPLETO - Copiar y pegar en nuevo archivo
// lib/widgets/typing_indicator.dart - NUEVO
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/animation.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/typing_provider.dart';

class TypingIndicator extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String? otherUserName;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.currentUserId,
    this.otherUserName = 'Usuario',
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription? _typingSubscription;
  String? _typingUserId;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _subscribeToTypingEvents();
  }

  void _subscribeToTypingEvents() {
    final typingProvider = context.read<TypingProvider>();
    
    _typingSubscription = typingProvider.subscribeToTypingEvents(
      widget.chatId,
      (userId) {
        if (mounted) {
          setState(() {
            _typingUserId = userId;
          });
          
          // AppLogger.d('👀 Typing indicator actualizado: $userId');
        }
      }
    );
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = _typingUserId != null && _typingUserId != widget.currentUserId;
    
    if (!isTyping) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 20,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 2),
                    _buildDot(0.2),
                    const SizedBox(width: 2),
                    _buildDot(0.4),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.otherUserName} está escribiendo...',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return Transform.scale(
      scale: _animationController.value > delay && _animationController.value < delay + 0.3
          ? 1.2
          : 1.0,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}