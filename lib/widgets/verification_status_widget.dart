// lib/widgets/verification_status_widget.dart
import 'package:flutter/material.dart';

class VerificationStatusWidget extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const VerificationStatusWidget({
    super.key,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    final verificationStatus = profileData['verification_status'] as String? ?? 'pending';
    final isVerified = verificationStatus == 'verified';
    final isPending = verificationStatus == 'pending';
    final isRejected = verificationStatus == 'rejected';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (isVerified) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusText = 'Verificado';
      statusDescription = 'Tu cuenta ha sido verificada exitosamente';
    } else if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'En revisión';
      statusDescription = 'Tu documentación está siendo revisada';
    } else if (isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Rechazado';
      statusDescription = 'Tu documentación fue rechazada. Por favor, sube nuevos documentos.';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.person_outline;
      statusText = 'No verificado';
      statusDescription = 'Completa tu verificación para más beneficios';
    }

    return Card(
      // ignore: deprecated_member_use
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}