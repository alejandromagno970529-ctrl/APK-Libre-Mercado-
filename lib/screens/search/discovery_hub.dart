// lib/screens/search/discovery_hub.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/services/search_history_service.dart';
import 'package:libre_mercado_final__app/services/location_service.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';
import 'package:libre_mercado_final__app/constants.dart';

class DiscoveryHub extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Product) onProductTap;
  final Function(Product) onContactTap;

  const DiscoveryHub({
    super.key,
    required this.onSearch,
    required this.onProductTap,
    required this.onContactTap,
  });

  @override
  State<DiscoveryHub> createState() => _DiscoveryHubState();
}

class _DiscoveryHubState extends State<DiscoveryHub> {
  List<String> _recentSearches = [];
  List<Product> _nearbyProducts = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryData();
  }

  Future<void> _loadDiscoveryData() async {
    // Cargar búsquedas recientes
    _recentSearches = await SearchHistoryService.getSearchHistory();
    
    // Cargar productos en paralelo
    await Future.wait([
      _loadNearbyProducts(),
      _loadFeaturedProducts(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadNearbyProducts() async {
    try {
      final location = await LocationService.getCoordinatesOnly();
      if (location['success'] == true) {
        final productProvider = context.read<ProductProvider>();
        final userLat = location['latitude'] as double;
        final userLng = location['longitude'] as double;
        
        _nearbyProducts = productProvider.getNearbyProducts(
          userLat, 
          userLng, 
          5.0 // 5km radius
        ).take(6).toList();
      }
    } catch (e) {
      print('Error loading nearby products: $e');
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final productProvider = context.read<ProductProvider>();
      _featuredProducts = await productProvider.getFeaturedProducts(limit: 8);
    } catch (e) {
      print('Error loading featured products: $e');
    }
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Búsquedas Recientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    search,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () {
                    setState(() {
                      _recentSearches.removeAt(index);
                      SearchHistoryService.removeSearchItem(search);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  backgroundColor: Colors.grey.shade100,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = ['Todos', ...AppStrings.productCategories];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Explorar Categorías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onSearch(category),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.length > 10 
                          ? '${category.substring(0, 10)}...' 
                          : category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNearbyProducts() {
    if (_nearbyProducts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Cerca de Ti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _nearbyProducts.length,
            itemBuilder: (context, index) {
              final product = _nearbyProducts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  product: product,
                  onTap: () => widget.onProductTap(product),
                  onContactTap: () => widget.onContactTap(product),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.star, size: 20, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Productos Destacados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredProducts.length,
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  product: product,
                  onTap: () => widget.onProductTap(product),
                  onContactTap: () => widget.onContactTap(product),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrendingSearches() {
    final trending = ['iPhone', 'Zapatos', 'Laptop', 'Moto', 'Apartamento'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Tendencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trending.map((search) {
              return GestureDetector(
                onTap: () => widget.onSearch(search),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[category.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tecnología':
        return Icons.smartphone;
      case 'Electrodomésticos':
        return Icons.kitchen;
      case 'Ropa y Accesorios':
        return Icons.checkroom;
      case 'Hogar y Jardín':
        return Icons.home;
      case 'Deportes':
        return Icons.sports_soccer;
      case 'Videojuegos':
        return Icons.videogame_asset;
      case 'Libros':
        return Icons.menu_book;
      case 'Música y Películas':
        return Icons.music_note;
      case 'Salud y Belleza':
        return Icons.spa;
      case 'Juguetes':
        return Icons.toys;
      case 'Herramientas':
        return Icons.build;
      case 'Automóviles':
        return Icons.directions_car;
      case 'Motos':
        return Icons.motorcycle;
      case 'Bicicletas':
        return Icons.pedal_bike;
      case 'Mascotas':
        return Icons.pets;
      case 'Arte y Coleccionables':
        return Icons.palette;
      case 'Inmuebles':
        return Icons.apartment;
      case 'Empleos':
        return Icons.work;
      case 'Servicios':
        return Icons.handyman;
      case 'Otros':
        return Icons.category;
      case 'Todos':
        return Icons.all_inclusive;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando descubrimientos...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentSearches(),
          _buildCategoriesGrid(),
          _buildNearbyProducts(),
          _buildFeaturedProducts(),
          _buildTrendingSearches(),
          
          // Mensaje informativo
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Escribe en la barra de búsqueda para encontrar productos específicos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}