// lib/widgets/verification_status_widget.dart
import 'package:flutter/material.dart';

class VerificationStatusWidget extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const VerificationStatusWidget({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final verificationStatus = profileData['verification_status'] as String? ?? 'pending';
    final isVerified = verificationStatus == 'verified';
    final isPending = verificationStatus == 'pending';

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
            
            if (isVerified) _buildVerifiedStatus(),
            if (isPending) _buildPendingStatus(),
            if (!isVerified && !isPending) _buildNotVerifiedStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedStatus() {
    return _buildStatusRow(
      '✅ Cuenta Verificada',
      'Tu identidad ha sido confirmada oficialmente',
      Colors.green,
    );
  }

  Widget _buildPendingStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          '⏳ Verificación en Proceso',
          'Estamos revisando tu documentación',
          Colors.orange,
        ),
        const SizedBox(height: 8),
        if (profileData['verification_submitted_at'] != null)
          Text(
            'Solicitud enviada: ${_formatDate(profileData['verification_submitted_at'])}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildNotVerifiedStatus() {
    return _buildStatusRow(
      '📝 Verificación Pendiente',
      'Verifica tu cuenta para generar más confianza',
      Colors.grey,
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
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return 'Fecha no disponible';
    } catch (e) {
      return 'Fecha no disponible';
    }
  }
}