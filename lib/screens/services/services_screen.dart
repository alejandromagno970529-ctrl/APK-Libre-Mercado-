import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/service_model.dart';
import 'package:provider/provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/service_card.dart';
import '../../constants/service_categories.dart';
// ignore: unused_import
import '../../constants/app_colors.dart';

class ServicesScreen extends StatefulWidget {
  static const String routeName = '/services';

  // ignore: use_super_parameters
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ServiceProvider _serviceProvider;
  bool _showSearchBar = false;
  // ignore: unused_field
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      _serviceProvider.fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showSearchBar ? _buildSearchAppBar() : _buildDefaultAppBar(context, isLoggedIn),
      body: Column(
        children: [
          _buildCategoriesSection(),
          Expanded(
            child: _buildServicesList(),
          ),
        ],
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: () => _navigateToAddService(context),
              backgroundColor: Colors.black,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context, bool isLoggedIn) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      title: const Text(
        'Servicios',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.black),
          onPressed: () {
            setState(() {
              _showSearchBar = true;
            });
          },
        ),
        if (isLoggedIn)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'my_services') {
                _navigateToMyServices(context);
              } else if (value == 'refresh') {
                _refreshServices();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'my_services',
                child: Row(
                  children: [
                    Icon(Icons.work_outline_rounded, size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Mis servicios', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Actualizar', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        onPressed: () {
          setState(() {
            _showSearchBar = false;
            _searchController.clear();
          });
        },
      ),
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Buscar servicios...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _showSearchBar = false;
                });
              },
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(context, value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ServiceCategories.allCategories.length,
        itemBuilder: (context, index) {
          final category = ServiceCategories.allCategories[index];
          return _buildCategoryItem(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.selectedCategory == category['id'] || 
                          (provider.selectedCategory == null && index == 0);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategoryIndex = index;
            });
            
            if (isSelected && provider.selectedCategory != null) {
              provider.clearCategory();
              provider.fetchServices();
            } else {
              provider.fetchServices(category: category['id']);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade200,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                category['icon'] is IconData
                    ? Icon(
                        category['icon'] as IconData,
                        size: 28,
                        color: isSelected ? Colors.white : Colors.black87,
                      )
                    : Text(
                        category['icon'] is String ? category['icon'] as String : '📦',
                        style: const TextStyle(fontSize: 28),
                      ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServicesList() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.services.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2.5,
            ),
          );
        }

        if (provider.services.isEmpty) {
          return _buildEmptyState(provider);
        }

        return RefreshIndicator(
          color: Colors.black,
          onRefresh: () => _refreshServices(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: provider.services.length,
            itemBuilder: (context, index) {
              final service = provider.services[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ServiceCard(
                  service: service,
                  onTap: () => _navigateToServiceDetail(context, service),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ServiceProvider provider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                provider.selectedCategory != null
                    ? 'No hay servicios en esta categoría'
                    : 'No hay servicios disponibles',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                provider.selectedCategory != null
                    ? 'Sé el primero en publicar un servicio\nen esta categoría'
                    : 'Comienza ofreciendo tus servicios\no productos',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _navigateToAddService(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Publicar servicio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _refreshServices(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Recargar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshServices() async {
    final provider = Provider.of<ServiceProvider>(context, listen: false);
    await provider.fetchServices();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Servicios actualizados'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _performSearch(BuildContext context, String query) {
    Navigator.pushNamed(
      context,
      '/service-search',
      arguments: query,
    );
  }

  void _navigateToAddService(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/add-edit-service');
    } else {
      _showLoginRequiredDialog(context);
    }
  }

  void _navigateToServiceDetail(BuildContext context, ServiceModel service) {
    Navigator.pushNamed(
      context,
      '/service-detail',
      arguments: service.id,
    );
  }

  void _navigateToMyServices(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/my-services');
    } else {
      _showLoginRequiredDialog(context);
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 32,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inicio de sesión requerido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Debes iniciar sesión para acceder a esta función.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}