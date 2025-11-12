// lib/screens/product/product_search_screen.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/widgets/product_search_list_item.dart';
import 'package:libre_mercado_final__app/widgets/products_map_view.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_screen.dart';

// Importamos las constantes para tener acceso a AppStrings
import 'package:libre_mercado_final__app/constants.dart';

class ProductSearchScreen extends StatefulWidget {
  final String initialQuery;

  const ProductSearchScreen({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos';
  List<Product> _filteredProducts = [];
  TabController? _tabController;
  
  // Variables para sincronización
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _mapScrollController = ScrollController();
  int _currentListIndex = 0;
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _tabController = TabController(length: 2, vsync: this);
    
    // Listeners para sincronización de scroll
    _listScrollController.addListener(_onListScroll);
    _mapScrollController.addListener(_onMapScroll);
    _tabController?.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterProducts();
    });
  }

  void _onListScroll() {
    if (_isSyncingScroll) return;
    
    final scrollPosition = _listScrollController.position;
    if (scrollPosition.hasContentDimensions) {
      final itemHeight = 110.0; // Altura estimada del item
      final newIndex = (scrollPosition.pixels / itemHeight).floor();
      if (newIndex != _currentListIndex && newIndex >= 0 && newIndex < _filteredProducts.length) {
        setState(() {
          _currentListIndex = newIndex;
        });
        
        // Sincronizar con mapa si estamos en la pestaña de lista
        if (_tabController?.index == 0) {
          _syncToMap(newIndex);
        }
      }
    }
  }

  void _onMapScroll() {
    if (_isSyncingScroll) return;
    
    final scrollPosition = _mapScrollController.position;
    if (scrollPosition.hasContentDimensions) {
      final itemHeight = 100.0; // Altura estimada del item del mapa
      final newIndex = (scrollPosition.pixels / itemHeight).floor();
      if (newIndex >= 0 && newIndex < _filteredProducts.length) {
        setState(() {
          _currentListIndex = newIndex;
        });
        
        // Sincronizar con lista si estamos en la pestaña de mapa
        if (_tabController?.index == 1) {
          _syncToList(newIndex);
        }
      }
    }
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == true) {
      // Cuando cambia la pestaña, sincronizar la vista
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController?.index == 1) {
          // Cambió a mapa, sincronizar desde lista
          _syncToMap(_currentListIndex);
        } else {
          // Cambió a lista, sincronizar desde mapa
          _syncToList(_currentListIndex);
        }
      });
    }
  }

  void _syncToMap(int listIndex) {
    if (_isSyncingScroll || _filteredProducts.isEmpty) return;
    
    _isSyncingScroll = true;
    
    // Filtrar productos con ubicación para el mapa
    final productsWithLocation = _filteredProducts.where((p) => p.hasLocation).toList();
    if (productsWithLocation.isNotEmpty) {
      final product = _filteredProducts[listIndex];
      final mapIndex = productsWithLocation.indexWhere((p) => p.id == product.id);
      if (mapIndex != -1 && _mapScrollController.hasClients) {
        final itemHeight = 100.0;
        final targetPosition = mapIndex * itemHeight;
        
        _mapScrollController.animateTo(
          targetPosition.clamp(0.0, _mapScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSyncingScroll = false;
    });
  }

  void _syncToList(int mapIndex) {
    if (_isSyncingScroll || _filteredProducts.isEmpty) return;
    
    _isSyncingScroll = true;
    
    if (_listScrollController.hasClients && mapIndex < _filteredProducts.length) {
      final itemHeight = 110.0;
      final targetPosition = mapIndex * itemHeight;
      
      _listScrollController.animateTo(
        targetPosition.clamp(0.0, _listScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSyncingScroll = false;
    });
  }

  void _filterProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final products = productProvider.products;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      _filteredProducts = products.where((product) {
        final title = product.titulo.toLowerCase();
        final description = product.descripcion?.toLowerCase() ?? '';
        final category = product.categorias.toLowerCase();
        return title.contains(query) || description.contains(query) || category.contains(query);
      }).toList();
    } else {
      _filteredProducts = products;
    }

    if (_selectedCategory != 'Todos') {
      _filteredProducts = _filteredProducts.where((product) => product.categorias == _selectedCategory).toList();
    }

    // Resetear índice actual al filtrar
    _currentListIndex = 0;
    
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _filterProducts();
  }

  Future<void> _startChatWithSeller(Product product) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }

    if (currentUser.id == product.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este es tu propio producto')),
      );
      return;
    }

    try {
      final chatId = await chatProvider.getOrCreateChat(
        productId: product.id,
        buyerId: currentUser.id,
        sellerId: product.userId,
      );

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: product.userId,
            productId: product.id,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar sesión requerido'),
        content: const Text('Debes iniciar sesión para contactar al vendedor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListView() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (productProvider.error != null) {
          return _buildErrorState(productProvider.error!);
        }

        if (_filteredProducts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await productProvider.fetchProducts();
            _filterProducts();
          },
          child: Scrollbar(
            controller: _listScrollController,
            child: ListView.builder(
              controller: _listScrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ProductSearchListItem(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  onContactTap: () => _startChatWithSeller(product),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductMapView() {
    return ProductsMapView(
      products: _filteredProducts,
      onProductTap: (product) {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      onContactTap: _startChatWithSeller,
      scrollController: _mapScrollController,
    );
  }

  Widget _buildCategoryFilter(String category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedCategory = category;
        _filterProducts();
      }),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      backgroundColor: Colors.white,
      selectedColor: Colors.black,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron resultados'
                  : 'No hay productos disponibles',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isNotEmpty)
              OutlinedButton(
                onPressed: _clearSearch,
                child: const Text('Limpiar búsqueda'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar productos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                final productProvider = context.read<ProductProvider>();
                productProvider.fetchProducts().then((_) => _filterProducts());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar todas las categorías definidas en constants.dart
    final categories = ['Todos', ...AppStrings.productCategories];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Productos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Lista'),
            Tab(icon: Icon(Icons.map), text: 'Mapa'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: (value) => _filterProducts(),
            ),
          ),

          // Filtros de categoría - MODIFICADO PARA SCROLL HORIZONTAL
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: _buildCategoryFilter(category),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'producto' : 'productos'} encontrado${_filteredProducts.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                if (_filteredProducts.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'Sincronizado',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.sync, size: 14, color: Colors.green.shade600),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Contenido de pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Lista
                _buildProductListView(),
                
                // Pestaña 2: Mapa
                _buildProductMapView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    _mapScrollController.removeListener(_onMapScroll);
    _mapScrollController.dispose();
    super.dispose();
  }
}