// lib/screens/search/real_time_search_suggestions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/models/user_model.dart';
import 'package:libre_mercado_final__app/constants.dart';

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
  List<AppUser> _userSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(RealTimeSearchSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _loadSuggestions();
    }
  }

  void _loadSuggestions() {
    if (widget.query.isEmpty) {
      setState(() {
        _textSuggestions = [];
        _productSuggestions = [];
        _categorySuggestions = [];
        _userSuggestions = [];
      });
      return;
    }

    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();

    // Sugerencias de texto (simuladas)
    _textSuggestions = _getTextSuggestions(widget.query);

    // Productos que coinciden
    _productSuggestions = productProvider.searchProducts(widget.query).take(3).toList();

    // Categorías que coinciden
    _categorySuggestions = AppStrings.productCategories
        .where((category) => category.toLowerCase().contains(widget.query.toLowerCase()))
        .take(2)
        .toList();

    // Usuarios que coinciden (simulado por ahora)
    _userSuggestions = _getUserSuggestions(widget.query, authProvider);

    setState(() {});
  }

  List<String> _getTextSuggestions(String query) {
    final popularSearches = ['iPhone', 'Zapatos', 'Laptop', 'Moto', 'Apartamento'];
    return popularSearches
        .where((search) => search.toLowerCase().contains(query.toLowerCase()))
        .take(2)
        .toList();
  }

  List<AppUser> _getUserSuggestions(String query, AuthProvider authProvider) {
    // Simulamos usuarios por ahora - en una implementación real buscarías en la base de datos
    return [];
  }

  Widget _buildTextSuggestions() {
    if (_textSuggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Sugerencias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ..._textSuggestions.map((suggestion) => ListTile(
              leading: const Icon(Icons.search, size: 20, color: Colors.grey),
              title: Text(suggestion),
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () => widget.onSuggestionTap(suggestion),
            )),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildProductSuggestions() {
    if (_productSuggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Productos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ..._productSuggestions.map((product) => ListTile(
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
              ),
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () => widget.onProductTap(product),
            )),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildCategorySuggestions() {
    if (_categorySuggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Categorías',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ..._categorySuggestions.map((category) => ListTile(
              leading: const Icon(Icons.category, size: 20, color: Colors.grey),
              title: Text(category),
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () => widget.onCategoryTap(category),
            )),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildUserSuggestions() {
    if (_userSuggestions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Vendedores',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ..._userSuggestions.map((user) => ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null 
                    ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                    : null,
              ),
              title: Text(user.username),
              subtitle: Text(user.reputationText),
              dense: true,
              visualDensity: VisualDensity.compact,
              onTap: () {
                
              },
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) {
      return const SizedBox();
    }

    return Material(
      elevation: 4,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextSuggestions(),
              _buildProductSuggestions(),
              _buildCategorySuggestions(),
              _buildUserSuggestions(),
              
              // Footer
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
        ),
      ),
    );
  }
}