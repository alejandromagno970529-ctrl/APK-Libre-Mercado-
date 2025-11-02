import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/screens/product/add_product_screen.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  bool _isLoading = false;
  String _selectedFilter = 'Todos';

  final List<String> _filters = [
    'Todos',
    'Disponibles',
    'Vendidos',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await productProvider.fetchUserProducts(authProvider.currentUser!.id);
      } catch (e) {
        AppLogger.e('Error cargando productos del usuario', e);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    switch (_selectedFilter) {
      case 'Disponibles':
        return products.where((product) => product.disponible).toList();
      case 'Vendidos':
        return products.where((product) => !product.disponible).toList();
      default:
        return products;
    }
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    ).then((_) {
      // Recargar productos después de agregar uno nuevo
      _loadUserProducts();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes productos publicados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Publica tu primer producto y comienza a vender',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Publicar Primer Producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: isSelected ? Colors.amber : Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    if (products.isEmpty) {
      String message = '';
      String icon = '';

      switch (_selectedFilter) {
        case 'Disponibles':
          message = 'No tienes productos disponibles';
          icon = '🛍️';
          break;
        case 'Vendidos':
          message = 'No tienes productos vendidos';
          icon = '💰';
          break;
        default:
          return _buildEmptyState();
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(product),
          showStatus: true,
        );
      },
    );
  }

  Widget _buildStats(List<Product> products) {
    final totalProducts = products.length;
    final availableProducts = products.where((p) => p.disponible).length;
    final soldProducts = totalProducts - availableProducts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', totalProducts, Icons.inventory),
            _buildStatItem('Disponibles', availableProducts, Icons.shopping_cart),
            _buildStatItem('Vendidos', soldProducts, Icons.attach_money),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                strokeWidth: 2,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProducts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final filteredProducts = _getFilteredProducts(productProvider.userProducts);

          return Column(
            children: [
              // ESTADÍSTICAS
              if (productProvider.userProducts.isNotEmpty) ...[
                _buildStats(productProvider.userProducts),
                const SizedBox(height: 8),
              ],
              
              // FILTROS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildFilterChips(),
              ),
              
              // CONTADOR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filteredProducts.length} producto${filteredProducts.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // LISTA DE PRODUCTOS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildProductsGrid(filteredProducts),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        child: const Icon(Icons.add),
      ),
    );
  }
}