// 3. MEJORAR service_detail_screen.dart con información detallada
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/service_model.dart';
import '../../widgets/user_profile_header.dart';
import '../../utils/time_utils.dart';

class ServiceDetailScreen extends StatefulWidget {
  static const String routeName = '/service-detail';
  final String serviceId;

  // ignore: use_super_parameters
  const ServiceDetailScreen({Key? key, required this.serviceId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final provider = Provider.of<ServiceProvider>(context, listen: false);
      final service = await provider.getServiceById(widget.serviceId);
      
      if (service != null) {
        setState(() => _service = service);
      } else {
        // Buscar en servicios ya cargados
        final allServices = provider.services;
        final foundService = allServices.firstWhere(
          (s) => s.id == widget.serviceId,
          orElse: () => ServiceModel(
            id: '',
            userId: '',
            title: '',
            description: '',
            category: '',
            price: 0.0,
            priceUnit: '',
            location: '',
            serviceType: '',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          ),
        );
        
        if (foundService.id.isNotEmpty) {
          setState(() => _service = foundService);
        }
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
    final isOwnService = currentUserId == _service?.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // ignore: prefer_const_constructors
        title: Text(
          'Detalles',
          // ignore: prefer_const_constructors
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.black),
            onPressed: _shareService,
          ),
          if (isOwnService)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.black),
              onPressed: _editService,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _service == null
              ? _buildErrorState()
              : _buildServiceDetail(currentUserId, isOwnService),
      bottomNavigationBar: !_isLoading && _service != null
          ? _buildBottomBar(currentUserId, isOwnService)
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Servicio no encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El servicio que buscas no está disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text('Volver a servicios'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetail(String? currentUserId, bool isOwnService) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel de imágenes
          _buildImageCarousel(),
          
          // Indicador de imágenes
          if (_service!.images != null && _service!.images!.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_service!.images!.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index 
                          ? Colors.black 
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Perfil del proveedor
                UserProfileHeader(
                  userId: _service!.userId,
                  showRating: true,
                ),
                
                const SizedBox(height: 24),
                
                // Título y precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _service!.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _service!.location,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_service!.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _service!.priceUnit.toLowerCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Badges informativos
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoBadge(
                      icon: Icons.category_rounded,
                      label: _service!.category,
                    ),
                    if (_service!.subCategory != null)
                      _buildInfoBadge(
                        icon: Icons.settings_rounded,
                        label: _service!.subCategory!,
                      ),
                    _buildInfoBadge(
                      icon: Icons.settings_rounded,
                      label: _capitalize(_service!.serviceType),
                    ),
                    if (_service!.rating != null)
                      _buildInfoBadge(
                        icon: Icons.star_rounded,
                        label: '${_service!.rating!.toStringAsFixed(1)} (${_service!.totalReviews ?? 0})',
                        color: Colors.amber.shade600,
                      ),
                    if (_service!.experienceYears != null)
                      _buildInfoBadge(
                        icon: Icons.work_history_rounded,
                        label: '${_service!.experienceYears!} exp',
                      ),
                    if (_service!.capacity != null)
                      _buildInfoBadge(
                        icon: Icons.people_alt_rounded,
                        label: '${_service!.capacity!} personas',
                      ),
                    if (_service!.isCertified == true)
                      _buildInfoBadge(
                        icon: Icons.verified_rounded,
                        label: 'Certificado',
                        color: Colors.blue.shade600,
                      ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Descripción
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        if (_service!.description.length > 200)
                          TextButton(
                            onPressed: () => setState(() => _showFullDescription = !_showFullDescription),
                            child: Text(
                              _showFullDescription ? 'Ver menos' : 'Ver más',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _service!.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        height: 1.6,
                      ),
                      maxLines: _showFullDescription ? null : 4,
                      overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                    ),
                  ],
                ),
                
                // Horarios y disponibilidad
                if (_service!.availabilitySchedule != null) ...[
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Horarios y disponibilidad',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.grey.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _service!.availabilitySchedule!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                
                // Servicios/Comodidades incluidos
                if (_service!.amenities != null && _service!.amenities!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicios incluidos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _service!.amenities!.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  amenity,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
                
                // Portafolio (para decoración, construcción, etc.)
                if (_service!.portfolioImages != null && _service!.portfolioImages!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portafolio de trabajos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Trabajos anteriores realizados por el proveedor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _service!.portfolioImages!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 180,
                              margin: EdgeInsets.only(
                                right: index < _service!.portfolioImages!.length - 1 ? 12 : 0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  _service!.portfolioImages![index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Etiquetas
                if (_service!.tags.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Habilidades y especialidades',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _service!.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
                
                // Información de fecha
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publicado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimeUtils.formatTimeAgo(_service!.createdAt),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_service?.images == null || _service!.images!.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _service?.category ?? 'Servicio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            autoPlay: _service!.images!.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          itemCount: _service!.images!.length,
          itemBuilder: (context, index, realIndex) {
            return Image.network(
              _service!.images![index],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.black,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color ?? Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String? currentUserId, bool isOwnService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isOwnService) ...[
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _contactProvider,
                  icon: const Icon(Icons.message_rounded, size: 22),
                  label: const Text(
                    'Contactar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _callProvider,
                  icon: const Icon(Icons.call_rounded, size: 22),
                  label: const Text(
                    'Llamar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _editService,
                  icon: const Icon(Icons.edit_rounded, size: 22),
                  label: const Text(
                    'Editar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _deactivateService,
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 22),
                  label: const Text(
                    'Pausar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
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

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para contactar al proveedor'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    try {
      await chatProvider.startChat(
        otherUserId: _service!.userId,
        currentUserId: authProvider.currentUser!.id,
        productId: '',
        serviceId: _service!.id,
      );
      
      // ignore: use_build_context_synchronously
      Navigator.pushNamed(context, '/chat');
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar chat: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _callProvider() async {
    if (_service == null) return;
    
    // ignore: prefer_const_declarations
    final phoneNumber = 'tel:+1234567890'; // Esto debería venir del perfil del usuario
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo realizar la llamada'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _shareService() {
    if (_service == null) return;
    
    // Implementar lógica de compartir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartir servicio (funcionalidad en desarrollo)'),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _editService() {
    if (_service == null) return;
    
    Navigator.pushNamed(
      context,
      '/add-edit-service',
      arguments: _service,
    );
  }

  void _deactivateService() {
    if (_service == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pausar Servicio'),
        content: const Text('¿Estás seguro de que quieres pausar este servicio? Los usuarios ya no podrán verlo hasta que lo reactives.'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pausar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate() async {
    if (_service == null) return;
    
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
        const SnackBar(
          content: Text('Servicio pausado correctamente'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}