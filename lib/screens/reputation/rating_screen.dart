import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/reputation_provider.dart';
// ✅ CORREGIDO: Eliminada importación no utilizada

class RatingScreen extends StatefulWidget {
  final String toUserId;
  final String? transactionId;
  final String? productId;

  const RatingScreen({
    super.key,
    required this.toUserId,
    this.transactionId,
    this.productId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dejar Valoración'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              '¿Cómo fue tu experiencia?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu valoración ayuda a otros usuarios a confiar en este vendedor/comprador.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Selección de estrellas
            _buildStarRating(),
            const SizedBox(height: 32),

            // Comentario
            _buildCommentSection(),
            const SizedBox(height: 40),

            // Botón enviar
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        const Text(
          'Selecciona una calificación:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = starNumber;
                });
              },
              child: Icon(
                starNumber <= _selectedRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 50,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_selectedRating),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentario (opcional):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            hintText: 'Describe tu experiencia con este usuario...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ej: "Muy buen trato, producto en perfecto estado"',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _selectedRating > 0 && !_isSubmitting ? _submitRating : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              )
            : const Text(
                'ENVIAR VALORACIÓN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reputationProvider = context.read<ReputationProvider>();
      // ✅ CORREGIDO: Eliminada variable no utilizada

      final error = await reputationProvider.createRating(
        toUserId: widget.toUserId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty 
            ? _commentController.text.trim() 
            : null,
        transactionId: widget.transactionId,
      );

      if (error == null) {
        // Éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Valoración enviada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error enviando valoración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy Malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return 'Selecciona una calificación';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}