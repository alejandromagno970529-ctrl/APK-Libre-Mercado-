import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/transaction_agreement.dart';

class AgreementMessageWidget extends StatelessWidget {
  final TransactionAgreement agreement;
  final bool isCurrentUser;
  final Function(TransactionAgreement, String) onStatusUpdate;

  const AgreementMessageWidget({
    super.key,
    required this.agreement,
    required this.isCurrentUser,
    required this.onStatusUpdate, required currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isCurrentUser ? Colors.blue[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Acuerdo de Transacción',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Precio acordado', '\$${agreement.agreedPrice}'),
            _buildInfoRow('Lugar de encuentro', agreement.meetingLocation),
            _buildInfoRow('Fecha y hora', 
              '${agreement.meetingTime.day}/${agreement.meetingTime.month}/${agreement.meetingTime.year} '
              '${agreement.meetingTime.hour}:${agreement.meetingTime.minute.toString().padLeft(2, '0')}'
            ),
            _buildStatusWidget(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    switch (agreement.status) {
      case 'pending':
        return isCurrentUser
            ? const Text(
                'Esperando respuesta...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              )
            : Row(
                children: [
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(agreement, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aceptar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(agreement, 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rechazar'),
                  ),
                ],
              );
      case 'accepted':
        return Text(
          '✅ Acuerdo aceptado',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        );
      case 'rejected':
        return Text(
          '❌ Acuerdo rechazado',
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        );
      case 'completed':
        return Text(
          '✅ Transacción completada',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return const SizedBox();
    }
  }
}