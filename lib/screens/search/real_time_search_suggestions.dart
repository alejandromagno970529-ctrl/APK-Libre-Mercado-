import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/services/search_history_service.dart';

class RealTimeSearchSuggestions extends StatefulWidget {
  final String query;
  final Function(String) onSuggestionTap;
  final Function(Product) onProductTap;
  final Function(String) onCategoryTap;

  const RealTimeSearchSuggestions({
    super.key,
    required this.query,
    required this.onSuggestionTap,
    required this.onProductTap,
    required this.onCategoryTap,
  });

  @override
  State<RealTimeSearchSuggestions> createState() => _RealTimeSearchSuggestionsState();
}

class _RealTimeSearchSuggestionsState extends State<RealTimeSearchSuggestions> {
  List<String> _textSuggestions = [];
  List<Product> _productSuggestions = [];
  List<String> _categorySuggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(RealTimeSearchSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _loadSuggestions();
    }
  }

  Future<void> _loadInitialData() async {
    _recentSearches = await SearchHistoryService.getSearchHistory();
  }

  Future<void> _loadSuggestions() async {
    if (widget.query.isEmpty) {
      setState(() {
        _textSuggestions = [];
        _productSuggestions = [];
        _categorySuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = context.read<ProductProvider>();
      
      await Future.wait([
        _loadProductSuggestions(productProvider),
        _loadCategorySuggestions(),
        _loadTextSuggestions(),
      ]);
    } catch (e) {
      print('Error cargando sugerencias: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProductSuggestions(ProductProvider productProvider) async {
    try {
      final products = await productProvider.getSimilarProductsByTitle(widget.query, limit: 3);
      setState(() {
        _productSuggestions = products;
      });
    } catch (e) {
      print('Error cargando sugerencias de productos: $e');
    }
  }

  Future<void> _loadCategorySuggestions() async {
    try {
      // ✅ ACTUALIZADO: Incluir "Alimentos y bebidas"
      final allCategories = [
        'Tecnología', 'Ropa', 'Hogar', 'Deportes', 'Electrodomésticos',
        'Videojuegos', 'Alimentos y bebidas', 'Libros', 'Herramientas', 'Juguetes',
        'Belleza', 'Salud', 'Automóviles', 'Motos', 'Bicicletas'
      ];
      
      final matchingCategories = allCategories
          .where((category) => category.toLowerCase().contains(widget.query.toLowerCase()))
          .take(2)
          .toList();

      setState(() {
        _categorySuggestions = matchingCategories;
      });
    } catch (e) {
      print('Error cargando sugerencias de categorías: $e');
    }
  }

  Future<void> _loadTextSuggestions() async {
    try {
      final popularSearches = ['iPhone', 'Zapatos', 'Laptop', 'Moto', 'Apartamento', 'Bicicleta'];
      
      final matchingSearches = popularSearches
          .where((search) => search.toLowerCase().contains(widget.query.toLowerCase()))
          .take(2)
          .toList();

      final matchingRecent = _recentSearches
          .where((search) => search.toLowerCase().contains(widget.query.toLowerCase()))
          .take(2)
          .toList();

      setState(() {
        _textSuggestions = [...matchingSearches, ...matchingRecent].take(3).toList();
      });
    } catch (e) {
      print('Error cargando sugerencias de texto: $e');
    }
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontSize: 14),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: onTap,
    );
  }

  Widget _buildProductItem(Product product) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
        ),
        child: product.imagenUrl != null && product.imagenUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product.imagenUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.photo, color: Colors.grey.shade400);
                  },
                ),
              )
            : Icon(Icons.photo, color: Colors.grey.shade400),
      ),
      title: Text(
        product.titulo,
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        product.precioFormateado,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () => widget.onProductTap(product),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSuggestionsContent() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            'Sugerencias',
            _textSuggestions
                .map((suggestion) => _buildSuggestionItem(
                      suggestion,
                      Icons.search,
                      () => widget.onSuggestionTap(suggestion),
                    ))
                .toList(),
          ),
          
          _buildSection(
            'Productos',
            _productSuggestions
                .map((product) => _buildProductItem(product))
                .toList(),
          ),
          
          _buildSection(
            'Categorías',
            _categorySuggestions
                .map((category) => _buildSuggestionItem(
                      category,
                      Icons.category,
                      () => widget.onCategoryTap(category),
                    ))
                .toList(),
          ),
          
          if (widget.query.isEmpty && _recentSearches.isNotEmpty)
            _buildSection(
              'Búsquedas Recientes',
              _recentSearches
                  .map((search) => ListTile(
                        leading: const Icon(Icons.history, size: 20, color: Colors.grey),
                        title: Text(
                          search,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14),
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () async {
                            await SearchHistoryService.removeSearchItem(search);
                            _recentSearches.remove(search);
                            setState(() {});
                          },
                        ),
                        onTap: () => widget.onSuggestionTap(search),
                      ))
                  .toList(),
            ),
          
          if (_textSuggestions.isEmpty && 
              _productSuggestions.isEmpty && 
              _categorySuggestions.isEmpty &&
              widget.query.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No se encontraron sugerencias',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          
          if (widget.query.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Presiona Enter para buscar todos los resultados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty && _recentSearches.isEmpty) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ✅ ALTURA MÁXIMA REDUCIDA PARA ELIMINAR LOS 68PX RESTANTES
      constraints: const BoxConstraints(
        maxHeight: 180, // Reducido de 250 a 180 para eliminar el overflow
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) _buildLoadingIndicator(),
          
          Expanded(
            child: _buildSuggestionsContent(),
          ),
        ],
      ),
    );
  }
}