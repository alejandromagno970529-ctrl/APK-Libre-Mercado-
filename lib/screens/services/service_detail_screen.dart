import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:url_launcher/url_launcher.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/service_model.dart';
import '../../widgets/user_profile_header.dart';

class ServiceDetailScreen extends StatefulWidget {
  static const String routeName = '/service-detail';

  // ignore: use_super_parameters
  const ServiceDetailScreen({Key? key, required String serviceId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _isLoading = true;
  late String _serviceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serviceId = ModalRoute.of(context)!.settings.arguments as String;
    _loadService();
  }

  Future<void> _loadService() async {
    final provider = Provider.of<ServiceProvider>(context, listen: false);
    
    try {
      // Buscar en la lista actual primero
      final allServices = provider.services;
      _service = allServices.firstWhere(
        (s) => s.id == _serviceId,
        orElse: () => ServiceModel(
          id: '',
          userId: '',
          title: '',
          description: '',
          category: '',
          price: 0,
          priceUnit: '',
          location: '',
          serviceType: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Si no está en la lista, cargar individualmente
      if (_service!.id.isEmpty) {
        // Nota: Necesitarías un método getServiceById en el provider
        // Por ahora, mostramos un placeholder
      }
    } catch (error) {
      // ignore: avoid_print
      print('Error loading service: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Servicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareService,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _service == null
              ? const Center(child: Text('Servicio no encontrado'))
              : _buildServiceDetail(currentUserId),
      bottomNavigationBar: _buildBottomBar(currentUserId),
    );
  }

  Widget _buildServiceDetail(String? currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del proveedor
          UserProfileHeader(
            userId: _service!.userId,
            showRating: true,
          ),
          
          const SizedBox(height: 20),
          
          // Título y precio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _service!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '\$${_service!.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          
          Text(
            _service!.priceUnit,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Categoría y ubicación
          Row(
            children: [
              Icon(
                Icons.category,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _service!.category,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.location_on,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _service!.location,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Descripción
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _service!.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          
          const SizedBox(height: 24),
          
          // Información adicional
          if (_service!.metadata != null) ...[
            const Text(
              'Información Adicional',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._service!.metadata!.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: 24),
          
          // Tags
          if (_service!.tags.isNotEmpty) ...[
            const Text(
              'Habilidades y Etiquetas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _service!.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.grey[100],
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(String? currentUserId) {
    final isOwnService = currentUserId == _service?.userId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (!isOwnService) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _contactProvider,
                icon: const Icon(Icons.message),
                label: const Text('Contactar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _callProvider,
                icon: const Icon(Icons.call),
                label: const Text('Llamar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editService,
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deactivateService,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Desactivar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _contactProvider() async {
    if (_service == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await chatProvider.startChat(
        otherUserId: _service!.userId,
        currentUserId: authProvider.currentUser!.id,
        productId: null,
        serviceId: _service!.id,
      );
      
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, '/chat');
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar chat: $error')),
      );
    }
  }

  void _callProvider() async {
    // Esto requeriría que tengas el número de teléfono en el perfil del usuario
    // Por ahora, solo mostramos un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de llamada en desarrollo')),
    );
  }

  void _shareService() {
    // Implementar compartir servicio
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartir servicio')),
    );
  }

  void _editService() {
    Navigator.pushNamed(
      context,
      '/edit-service',
      arguments: _service!.id,
    );
  }

  void _deactivateService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Servicio'),
        content: const Text('¿Estás seguro de que quieres desactivar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeactivate();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate() async {
    final provider = Provider.of<ServiceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await provider.deleteService(
        _service!.id,
        authProvider.currentUser!.id,
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio desactivado')),
      );
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}