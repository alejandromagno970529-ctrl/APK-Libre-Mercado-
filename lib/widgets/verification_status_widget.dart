// lib/widgets/verification_status_widget.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class VerificationStatusWidget extends StatelessWidget {
  final AppUser user;

  const VerificationStatusWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (user.isVerificationVerified) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusText = 'Cuenta Verificada';
      statusDescription = 'Tu identidad ha sido verificada exitosamente';
    } else if (user.isVerificationPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'En Revisión';
      statusDescription = 'Tu documentación está siendo revisada';
    } else if (user.isVerificationRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Verificación Rechazada';
      statusDescription = 'Tu documentación fue rechazada. Contacta con soporte.';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.person_outline;
      statusText = 'No Verificado';
      statusDescription = 'Completa tu verificación para más beneficios';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        // ignore: deprecated_member_use
        color: statusColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDescription,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: statusColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!user.isVerificationVerified && !user.isVerificationPending)
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: statusColor, size: 16),
                  onPressed: () {
                    // Navegar a pantalla de verificación
                    _showVerificationInfo(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificación de Cuenta'),
        content: const Text(
          'La verificación de cuenta te permite:\n\n'
          '✅ Ganar confianza de otros usuarios\n'
          '✅ Acceder a todas las funciones premium\n'
          '✅ Vender más productos\n'
          '✅ Recibir pagos más rápido\n\n'
          'Para verificarte necesitas:\n'
          '• Foto de tu documento de identidad\n'
          '• Selfie con tu documento\n'
          '• Información personal básica',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a pantalla de verificación completa
              _navigateToVerificationScreen(context);
            },
            child: const Text('Verificarme'),
          ),
        ],
      ),
    );
  }

  void _navigateToVerificationScreen(BuildContext context) {
    // Esta función se integrará con el profile_screen
    // Por ahora muestra un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirigiendo a pantalla de verificación...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}