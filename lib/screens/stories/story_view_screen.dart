import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/models/story_model.dart';
import 'package:libre_mercado_final__app/providers/story_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';

class StoryViewScreen extends StatefulWidget {
  final Story story;
  final bool isOwner;

  const StoryViewScreen({
    super.key, 
    required this.story,
    this.isOwner = false,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            // Imagen de la historia
            if (widget.story.imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.story.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Texto de la historia (si existe)
            if (widget.story.text != null && widget.story.text!.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.story.text!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Header con información del usuario
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.story.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.story.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.story.timeRemaining,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón de eliminar (solo para el propietario)
                  if (widget.isOwner && currentUserId == widget.story.userId)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _showDeleteConfirmation(context, storyProvider),
                    ),
                ],
              ),
            ),

            // Barra de progreso
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _calculateProgress(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Botón de cerrar
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress() {
    final now = DateTime.now();
    final totalDuration = widget.story.expiresAt.difference(widget.story.createdAt);
    final elapsed = now.difference(widget.story.createdAt);
    
    if (elapsed.inSeconds <= 0) return 0.0;
    if (elapsed.inSeconds >= totalDuration.inSeconds) return 1.0;
    
    return elapsed.inSeconds / totalDuration.inSeconds;
  }

  void _showDeleteConfirmation(BuildContext context, StoryProvider storyProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Historia'),
        content: const Text('¿Estás seguro de que quieres eliminar esta historia? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              final success = await storyProvider.deleteStory(widget.story.id);
              
              if (success && context.mounted) {
                Navigator.pop(context); // Cerrar pantalla de story
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historia eliminada correctamente')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar la historia')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}