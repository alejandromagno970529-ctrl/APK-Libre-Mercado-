// lib/widgets/verification_status_widget.dart
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/profile_model.dart';

class VerificationStatusWidget extends StatelessWidget {
  final Profile profile;

  const VerificationStatusWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de Verificación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (profile.isVerified) ...[
              _buildStatusRow(
                '✅ Verificado',
                'Tu cuenta ha sido verificada exitosamente',
                Colors.green,
              ),
            ] else if (profile.isVerificationPending) ...[
              _buildStatusRow(
                '⏳ Pendiente',
                'Tu solicitud de verificación está en revisión',
                Colors.orange,
              ),
              if (profile.verificationSubmittedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Enviado: ${_formatDate(profile.verificationSubmittedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ] else if (profile.isVerificationRejected) ...[
              _buildStatusRow(
                '❌ Rechazado',
                'Tu solicitud de verificación fue rechazada',
                Colors.red,
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor contacta al soporte para más información',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              _buildStatusRow(
                '📝 No Verificado',
                'Verifica tu cuenta para ganar confianza',
                Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String title, String subtitle, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}