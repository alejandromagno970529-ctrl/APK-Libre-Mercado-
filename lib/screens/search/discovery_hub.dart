// lib/screens/search/discovery_hub.dart - VERSIÓN CORREGIDA Y MEJORADA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/product_provider.dart';
import 'package:libre_mercado_final_app/services/search_history_service.dart';
import 'package:libre_mercado_final_app/services/location_service.dart';
import 'package:libre_mercado_final_app/models/product_model.dart';
import 'package:libre_mercado_final_app/widgets/product_card.dart';
import 'package:libre_mercado_final_app/screens/categories/categories_screen.dart';

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
  List<Product> _popularProducts = [];
  bool _isLoading = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadDiscoveryData();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  Future<void> _loadDiscoveryData() async {
    try {
      _recentSearches = await SearchHistoryService.getSearchHistory();
      
      await Future.wait([
        _loadNearbyProducts(),
        _loadFeaturedProducts(),
        _loadPopularProducts(),
        _loadTrendingData(),
      ]);
    } catch (e) {
      // ignore: avoid_print
      print('Error en _loadDiscoveryData: $e');
    } finally {
      if (_isMounted) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNearbyProducts() async {
    try {
      final location = await LocationService.getCoordinatesOnly();
      if (location['success'] == true && _isMounted) {
        // ignore: use_build_context_synchronously
        final productProvider = context.read<ProductProvider>();
        final userLat = location['latitude'] as double;
        final userLng = location['longitude'] as double;
        
        if (_isMounted) {
          _safeSetState(() {
            _nearbyProducts = productProvider.getNearbyProducts(
              userLat, 
              userLng, 
              5.0
            ).take(6).toList();
          });
        }
      }
    } catch (e) {
      if (_isMounted) {
        // ignore: avoid_print
        print('Error loading nearby products: $e');
      }
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final products = await productProvider.getFeaturedProducts(limit: 8);
      
      if (_isMounted) {
        _safeSetState(() {
          _featuredProducts = products;
        });
      }
    } catch (e) {
      if (_isMounted) {
        // ignore: avoid_print
        print('Error loading featured products: $e');
      }
    }
  }

  Future<void> _loadPopularProducts() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final products = await productProvider.getPopularProducts(limit: 6);
      
      if (_isMounted) {
        _safeSetState(() {
          _popularProducts = products;
        });
      }
    } catch (e) {
      if (_isMounted) {
        // ignore: avoid_print
        print('Error loading popular products: $e');
      }
    }
  }

  Future<void> _loadTrendingData() async {
    try {
      final productProvider = context.read<ProductProvider>();
      final popularCategories = await productProvider.getPopularCategories();
      
      if (_isMounted) {
        // ignore: avoid_print
        print('Categorías populares: $popularCategories');
      }
    } catch (e) {
      if (_isMounted) {
        // ignore: avoid_print
        print('Error cargando tendencias: $e');
      }
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
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                ),
                child: Chip(
                  label: Text(
                    search,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () {
                    _safeSetState(() {
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
    // Lista expandida para coincidir con lo que se ve en la captura si quisieras mostrarlas todas,
    // o mantener las principales. Aquí pongo las principales pero con el diseño arreglado.
    final mainCategories = [
      'Tecnología', 'Ropa y Accesorios', 'Hogar y Jardín', 'Deportes',
      'Electrodomésticos', 'Videojuegos', 'Alimentos y bebidas', 'Libros'
    ];
    
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
            crossAxisSpacing: 8, // Espaciado horizontal un poco más abierto
            mainAxisSpacing: 12, // Más espacio vertical entre filas
            childAspectRatio: 0.72, // ✅ SOLUCIÓN OVERFLOW: Hacemos las celdas más altas
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: mainCategories.length,
          itemBuilder: (context, index) {
            final category = mainCategories[index];
            return _buildMinimalistCategoryItem(category);
          },
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesScreen(
                      onCategorySelected: (category) {
                        widget.onSearch(category);
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Ver todas las categorías',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalistCategoryItem(String category) {
    final color = _getCategoryColor(category);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => widget.onSearch(category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56, // Iconos más grandes y definidos
            height: 56,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.08), // Fondo sutil
              borderRadius: BorderRadius.circular(18), // Squircle (Moderno)
              border: Border.all(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Icon(
              _getCategoryIcon(category),
              size: 26, // Icono más visible
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2), // Menos padding lateral
          child: Text(
            _getShortCategoryName(category),
            style: const TextStyle(
              fontSize: 11, // Fuente ligeramente ajustada
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getShortCategoryName(String category) {
    final shortNames = {
      'Tecnología': 'Tecnología', // Cabe bien si la caja es ancha
      'Ropa y Accesorios': 'Ropa',
      'Hogar y Jardín': 'Hogar',
      'Deportes': 'Deportes',
      'Electrodomésticos': 'Electro',
      'Videojuegos': 'Juegos',
      'Alimentos y bebidas': 'Comida',
      'Libros': 'Libros',
      'Salud y Belleza': 'Salud',
      'Automóvil': 'Autos',
      'Herramientas': 'Herram.',
      'Motos': 'Motos',
      'Bicicletas': 'Bicis',
      'Mascotas': 'Mascotas',
      'Juguetes': 'Juguetes',
    };
    
    return shortNames[category] ?? category;
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Tecnología': Colors.blue,
      'Ropa y Accesorios': Colors.pinkAccent,
      'Hogar y Jardín': Colors.green,
      'Deportes': Colors.orange,
      'Electrodomésticos': Colors.teal,
      'Videojuegos': Colors.deepPurple,
      'Alimentos y bebidas': Colors.redAccent,
      'Libros': Colors.indigo,
      'Salud y Belleza': Colors.pink,
      'Automóvil': Colors.red,
      'Motos': Colors.deepOrange,
      'Bicicletas': Colors.lightGreen,
      'Mascotas': Colors.brown,
      'Juguetes': Colors.amber,
      'Herramientas': Colors.blueGrey,
    };
    
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tecnología':
        return Icons.devices_other; // Icono más general
      case 'Ropa y Accesorios':
        return Icons.checkroom;
      case 'Hogar y Jardín':
        return Icons.chair_outlined; // Más representativo de hogar
      case 'Deportes':
        return Icons.sports_soccer;
      case 'Electrodomésticos':
        return Icons.kitchen;
      case 'Videojuegos':
        return Icons.sports_esports;
      case 'Alimentos y bebidas':
        return Icons.restaurant_menu;
      case 'Libros':
        return Icons.auto_stories;
      case 'Salud y Belleza':
        return Icons.spa;
      case 'Automóvil':
        return Icons.directions_car_filled;
      case 'Motos':
        return Icons.two_wheeler;
      case 'Bicicletas':
        return Icons.pedal_bike;
      case 'Mascotas':
        return Icons.pets;
      case 'Juguetes':
        return Icons.toys;
      case 'Herramientas':
        return Icons.home_repair_service;
      default:
        return Icons.category_outlined;
    }
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

  Widget _buildPopularProducts() {
    if (_popularProducts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Productos Populares',
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
            itemCount: _popularProducts.length,
            itemBuilder: (context, index) {
              final product = _popularProducts[index];
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
    final trending = _recentSearches.isNotEmpty 
        ? _recentSearches.take(5).toList()
        : ['Tecnología', 'Ropa', 'Hogar', 'Deportes', 'Electrodomésticos'];
    
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
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                ),
                child: GestureDetector(
                  onTap: () => widget.onSearch(search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            search,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildLoadingState() {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentSearches(),
          _buildCategoriesGrid(),
          _buildNearbyProducts(),
          _buildFeaturedProducts(),
          _buildPopularProducts(),
          _buildTrendingSearches(),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Escribe en la barra de búsqueda para encontrar productos específicos',
              style: TextStyle(
                fontSize: 11,
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

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
}