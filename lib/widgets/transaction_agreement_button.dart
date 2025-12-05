import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/models/transaction_agreement.dart';
import 'package:libre_mercado_final_app/providers/agreement_provider.dart';

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
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85, // Reducido para evitar overflow
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      // ignore: prefer_const_constructors
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.handshake, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Crear Acuerdo de Transacción',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio acordado',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            // ignore: prefer_const_constructors
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'Lugar de encuentro',
                              border: OutlineInputBorder(),
                              hintText: 'Ej: Parque Central, Calle 42 #10-20',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Date and Time Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fecha y hora de encuentro',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Date Picker
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
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
                                        child: const Text('Cambiar'),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Time Picker
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selectedTime.format(context),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
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
                                        child: const Text('Cambiar'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
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
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Crear Acuerdo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Acuerdo de transacción creado'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // ignore: use_build_context_synchronously
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
        : IconButton(
            icon: const Icon(Icons.handshake, color: Colors.black),
            onPressed: _showAgreementDialog,
            tooltip: 'Crear Acuerdo de Transacción',
          );
  }
}