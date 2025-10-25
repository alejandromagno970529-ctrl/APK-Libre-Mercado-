import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/user_model.dart';

class ReputationStatsWidget extends StatelessWidget {
  final AppUser user;
  final bool showDetails;

  const ReputationStatsWidget({
    super.key,
    required this.user,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Reputación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Rating Principal
            _buildRatingSection(),

            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildTransactionStats(),
              const SizedBox(height: 12),
              _buildActivityStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        // Estrellas
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  user.rating?.toStringAsFixed(1) ?? '0.0',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
            Text(
              '${user.totalRatings ?? 0} valoración${user.totalRatings != 1 ? 'es' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Badge de Reputación
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getReputationColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getReputationBadge(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas de Transacciones',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatItem(
              icon: Icons.handshake,
              value: '${user.successfulTransactions ?? 0}',
              label: 'Éxitosas',
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              icon: Icons.trending_up,
              value: '${user.completionRate.toStringAsFixed(0)}%',
              label: 'Tasa de éxito',
            ),
          ],
        ),
        if (user.transactionStats != null) ...[
          const SizedBox(height: 8),
          Text(
            user.transactionStatsText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityStatus() {
    return Row(
      children: [
        Icon(
          Icons.circle,
          color: _getActivityColor(),
          size: 12,
        ),
        const SizedBox(width: 8),
        Text(
          user.activityStatus,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getReputationColor() {
    final rating = user.rating ?? 0;
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getReputationBadge() {
    final rating = user.rating ?? 0;
    final totalRatings = user.totalRatings ?? 0;

    if (totalRatings == 0) return 'Nuevo';
    if (rating >= 4.5 && totalRatings >= 10) return 'Excelente';
    if (rating >= 4.0 && totalRatings >= 5) return 'Confiable';
    if (rating >= 3.5) return 'Bueno';
    if (rating >= 3.0) return 'Regular';
    return 'En desarrollo';
  }

  Color _getActivityColor() {
    if (user.lastActive == null) return Colors.grey;
    
    final difference = DateTime.now().difference(user.lastActive!);
    if (difference.inMinutes < 5) return Colors.green;
    if (difference.inHours < 1) return Colors.lightGreen;
    if (difference.inHours < 24) return Colors.orange;
    return Colors.grey;
  }
}