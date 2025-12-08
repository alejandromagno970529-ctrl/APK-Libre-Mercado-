import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/service_model.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/service_card.dart';

class MyServicesScreen extends StatefulWidget {
  static const String routeName = '/my-services';

  // ignore: use_super_parameters
  const MyServicesScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyServicesScreenState createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  late ServiceProvider _serviceProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyServices();
    });
  }

  Future<void> _loadMyServices() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await _serviceProvider.fetchMyServices(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios'),
      ),
      body: Consumer2<AuthProvider, ServiceProvider>(
        builder: (context, authProvider, serviceProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text('Inicia sesión para ver tus servicios'),
            );
          }

          if (serviceProvider.isLoading && serviceProvider.myServices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (serviceProvider.myServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes servicios publicados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comienza ofreciendo tus servicios',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _navigateToAddService(context),
                    child: const Text('Publicar mi primer servicio'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: serviceProvider.myServices.length,
            itemBuilder: (context, index) {
              final service = serviceProvider.myServices[index];
              return Dismissible(
                key: Key(service.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmation(service);
                },
                onDismissed: (direction) {
                  _deleteService(service.id);
                },
                child: ServiceCard(
                  service: service,
                  onTap: () => _navigateToEditService(context, service.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddService(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(ServiceModel service) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Servicio'),
        content: Text(
          '¿Desactivar "${service.title}"?\n'
          'Los usuarios ya no podrán ver este servicio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _deleteService(String serviceId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      await serviceProvider.deleteService(serviceId, user.id);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio desactivado')),
      );
    }
  }

  void _navigateToAddService(BuildContext context) {
    Navigator.pushNamed(context, '/add-edit-service');
  }

  void _navigateToEditService(BuildContext context, String serviceId) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final service = serviceProvider.myServices.firstWhere(
      (s) => s.id == serviceId,
    );
    
    Navigator.pushNamed(
      context,
      '/add-edit-service',
      arguments: service,
    );
  }
}