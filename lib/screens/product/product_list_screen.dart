import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Todos';
  String _selectedSort = 'Más recientes';
  bool _isLoadingMore = false;

  final List<String> _categories = [
    'Todos',
    'Tecnología', 'Electrodomésticos', 'Ropa y Accesorios', 'Hogar y Jardín',
    'Deportes', 'Videojuegos', 'Libros', 'Música y Películas', 'Salud y Belleza',
    'Juguetes', 'Herramientas', 'Automóviles', 'Motos', 'Bicicletas', 'Mascotas',
    'Arte y Coleccionables', 'Inmuebles', 'Empleos', 'Servicios', 'Otros'
  ];

  final List<String> _sortOptions = [
    'Más recientes',
    'Precio: Menor a mayor',
    'Precio: Mayor a menor',
    'Cercanía',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    // Simular carga de más productos (en una implementación real, 
    // aquí harías paginación con Supabase)
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    List<Product> filtered = List.from(products);

    // Filtrar por categoría
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((product) => 
        product.categorias == _selectedCategory
      ).toList();
    }

    // Ordenar
    switch (_selectedSort) {
      case 'Más recientes':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Precio: Menor a mayor':
        filtered.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case 'Precio: Mayor a menor':
        filtered.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case 'Cercanía':
        // Por implementar: ordenar por distancia
        break;
    }

    return filtered;
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Filtrar y Ordenar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          
          // CATEGORÍAS
          const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  Navigator.pop(context);
                },
                backgroundColor: isSelected ? Colors.amber : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          
          // ORDENAR POR
          const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._sortOptions.map((sortOption) {
            return RadioListTile<String>(
              title: Text(sortOption),
              value: sortOption,
              // ignore: deprecated_member_use
              groupValue: _selectedSort,
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Todos';
                  _selectedSort = 'Más recientes';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
              child: const Text('Limpiar Filtros'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Intenta con otros filtros',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => _navigateToProductDetail(product),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libre Mercado'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar productos',
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar productos',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _getFilteredProducts(productProvider.products);

          return Column(
            children: [
              // CONTADOR DE RESULTADOS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    Text(
                      '${filteredProducts.length} producto${filteredProducts.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != 'Todos' || _selectedSort != 'Más recientes')
                      GestureDetector(
                        onTap: _showFilterDialog,
                        child: Row(
                          children: [
                            Text(
                              'Filtros activos',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.tune, size: 16, color: Colors.amber),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // LISTA DE PRODUCTOS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildProductGrid(filteredProducts),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}