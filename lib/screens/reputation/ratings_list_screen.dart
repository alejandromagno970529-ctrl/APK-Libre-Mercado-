import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/reputation_provider.dart';
import 'package:libre_mercado_final__app/models/rating_model.dart';

class RatingsListScreen extends StatefulWidget {
  final String userId;

  const RatingsListScreen({super.key, required this.userId});

  @override
  State<RatingsListScreen> createState() => _RatingsListScreenState();
}

class _RatingsListScreenState extends State<RatingsListScreen> {
  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final reputationProvider = context.read<ReputationProvider>();
    await reputationProvider.getUserRatings(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final reputationProvider = context.watch<ReputationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valoraciones Recibidas'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: _buildRatingsList(reputationProvider),
    );
  }

  Widget _buildRatingsList(ReputationProvider reputationProvider) {
    if (reputationProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    if (reputationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${reputationProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRatings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final ratings = reputationProvider.userRatings;

    if (ratings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay valoraciones',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Este usuario aún no ha recibido valoraciones',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          final rating = ratings[index];
          return _buildRatingCard(rating);
        },
      ),
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estrellas y fecha
            Row(
              children: [
                // Estrellas
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < rating.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  _formatDate(rating.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comentario
            if (rating.comment != null && rating.comment!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.comment!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // Información del que valora
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating.fromUserName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (rating.fromUserEmail != null)
                          Text(
                            rating.fromUserEmail!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Información de transacción si existe
            if (rating.transactionId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Transacción: ${rating.transactionId!.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}'; // ✅ CORREGIDO
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}