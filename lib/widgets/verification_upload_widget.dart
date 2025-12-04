// lib/widgets/verification_upload_widget.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationUploadWidget extends StatefulWidget {
  final String userId;
  final VoidCallback onVerificationSubmitted;

  const VerificationUploadWidget({
    super.key,
    required this.userId,
    required this.onVerificationSubmitted,
  });

  @override
  State<VerificationUploadWidget> createState() => _VerificationUploadWidgetState();
}

class _VerificationUploadWidgetState extends State<VerificationUploadWidget> {
  bool _isUploading = false;

  Future<void> _uploadVerificationDocument() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Simular subida de documento (implementar lógica real aquí)
      await Future.delayed(const Duration(seconds: 2));
      
      // Actualizar estado de verificación en la base de datos
      final supabase = Supabase.instance.client;
      await supabase
          .from('profiles')
          .update({'verification_status': 'pending'})
          .eq('id', widget.userId);

      // Notificar que se completó la subida
      widget.onVerificationSubmitted();
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Documento subido exitosamente. En revisión.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al subir documento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Verificación de Cuenta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Verifica tu cuenta para ganar la confianza de otros usuarios y acceder a todas las funciones de la aplicación.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📋 Documentos aceptados:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Cédula de identidad'),
            const Text('• Pasaporte'),
            const Text('• Licencia de conducir'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadVerificationDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Subiendo documento...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload),
                          SizedBox(width: 8),
                          Text('Subir Documento de Verificación'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}