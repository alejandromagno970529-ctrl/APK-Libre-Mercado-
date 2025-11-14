import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/models/transaction_agreement.dart';
import 'package:libre_mercado_final__app/providers/agreement_provider.dart';

class TransactionAgreementButton extends StatefulWidget {
  final String chatId;
  final String productId;
  final String buyerId;
  final String sellerId;
  final Function(TransactionAgreement) onAgreementCreated;

  const TransactionAgreementButton({
    super.key,
    required this.chatId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.onAgreementCreated,
  });

  @override
  State<TransactionAgreementButton> createState() => _TransactionAgreementButtonState();
}

class _TransactionAgreementButtonState extends State<TransactionAgreementButton> {
  bool _isLoading = false;

  Future<void> _showAgreementDialog() async {
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.handshake, color: Colors.amber),
                SizedBox(width: 8),
                Text('Crear Acuerdo de Transacción'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio acordado',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar de encuentro',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Parque Central, Calle 42 #10-20',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Fecha y hora de encuentro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  leading: const Icon(Icons.calendar_today),
                                  title: Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  ),
                                  onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null && picked != selectedDate) {
                                      setState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: Text(
                                    selectedTime.format(context),
                                  ),
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime,
                                    );
                                    if (picked != null && picked != selectedTime) {
                                      setState(() {
                                        selectedTime = picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa el precio acordado'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa el lugar de encuentro'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa un precio válido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final meetingDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  if (meetingDateTime.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La fecha y hora deben ser futuras'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  await _createAgreement(
                    price: price,
                    location: locationController.text,
                    meetingTime: meetingDateTime,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Crear Acuerdo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createAgreement({
    required double price,
    required String location,
    required DateTime meetingTime,
  }) async {
    setState(() => _isLoading = true);

    try {
      final agreementProvider = Provider.of<AgreementProvider>(context, listen: false);
      
      final agreement = TransactionAgreement.createNew(
        chatId: widget.chatId,
        productId: widget.productId,
        buyerId: widget.buyerId,
        sellerId: widget.sellerId,
        agreedPrice: price,
        meetingLocation: location,
        meetingTime: meetingTime,
      );

      final newAgreement = await agreementProvider.createAgreement(agreement);
      
      widget.onAgreementCreated(newAgreement);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Acuerdo de transacción creado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creando el acuerdo: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : IconButton(
            icon: const Icon(Icons.handshake),
            onPressed: _showAgreementDialog,
            tooltip: 'Crear Acuerdo de Transacción',
          );
  }
}