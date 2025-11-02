import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  final String? searchQuery;
  final String? category;

  const ProductListScreen({
    super.key,
    this.searchQuery,
    this.category,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
    
    setState(() {
      _filteredProducts = _filterProducts(productProvider.products);
      _isLoading = false;
    });
  }

  List<Product> _filterProducts(List<Product> allProducts) {
    List<Product> filtered = allProducts;

    // Filtrar por búsqueda
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      filtered = filtered.where((product) {
        final title = product.titulo.toLowerCase();
        final description = product.descripcion?.toLowerCase() ?? '';
        final category = product.categorias.toLowerCase();
        
        return title.contains(query) || 
               description.contains(query) || 
               category.contains(query);
      }).toList();
    }

    // Filtrar por categoría
    if (widget.category != null && widget.category != 'Todos') {
      filtered = filtered.where((product) => product.categorias == widget.category).toList();
    }

    return filtered;
  }

  String _getScreenTitle() {
    if (widget.searchQuery != null) {
      return 'Resultados: "${widget.searchQuery}"';
    } else if (widget.category != null) {
      return 'Categoría: ${widget.category}';
    } else {
      return 'Todos los Productos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _filteredProducts.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            widget.searchQuery != null
                ? 'No hay resultados para "${widget.searchQuery}"'
                : 'No hay productos en esta categoría',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Intenta con otras palabras clave o categorías',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Volver a buscar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              var showStatus = null;
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  );
                }, showStatus: showStatus,
              );
            },
          ),
        ),
      ],
    );
  }
}