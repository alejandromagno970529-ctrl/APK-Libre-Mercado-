// lib/screens/product/product_search_screen.dart - VERSIÓN SIN SPEECH_TO_TEXT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/widgets/product_search_list_item.dart';
import 'package:libre_mercado_final__app/widgets/products_map_view.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final__app/screens/search/discovery_hub.dart';
import 'package:libre_mercado_final__app/screens/search/real_time_search_suggestions.dart';
import 'package:libre_mercado_final__app/services/search_history_service.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  String _selectedCategory = 'Todos';
  List<Product> _filteredProducts = [];
  TabController? _tabController;
  
  // Variables para sincronización
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _mapScrollController = ScrollController();
  int _currentListIndex = 0;
  bool _isSyncingScroll = false;
  
  // Nuevas variables para mejoras
  bool _isSearchFocused = false;
  bool _showRealTimeSuggestions = false;
  bool _isGridView = false;
  bool _showFilters = false;
  
  // Filtros
  double? _minPrice;
  double? _maxPrice;
  bool _onlyAvailable = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _tabController = TabController(length: 2, vsync: this);
    
    // Listeners para sincronización de scroll
    _listScrollController.addListener(_onListScroll);
    _mapScrollController.addListener(_onMapScroll);
    _tabController?.addListener(_onTabChanged);
    
    // Listeners para búsqueda en tiempo real
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterProducts();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _showRealTimeSuggestions = _searchController.text.isNotEmpty && _isSearchFocused;
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
      _showRealTimeSuggestions = _searchController.text.isNotEmpty && _isSearchFocused;
    });
  }

  void _onListScroll() {
    if (_isSyncingScroll) return;
    
    final scrollPosition = _listScrollController.position;
    if (scrollPosition.hasContentDimensions) {
      final itemHeight = _isGridView ? 255 : 110;
      final newIndex = (scrollPosition.pixels / itemHeight).floor();
      if (newIndex != _currentListIndex && newIndex >= 0 && newIndex < _filteredProducts.length) {
        setState(() {
          _currentListIndex = newIndex;
        });
        
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
      final itemHeight = 100.0;
      final newIndex = (scrollPosition.pixels / itemHeight).floor();
      if (newIndex >= 0 && newIndex < _filteredProducts.length) {
        setState(() {
          _currentListIndex = newIndex;
        });
        
        if (_tabController?.index == 1) {
          _syncToList(newIndex);
        }
      }
    }
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController?.index == 1) {
          _syncToMap(_currentListIndex);
        } else {
          _syncToList(_currentListIndex);
        }
      });
    }
  }

  void _syncToMap(int listIndex) {
    if (_isSyncingScroll || _filteredProducts.isEmpty) return;
    
    _isSyncingScroll = true;
    
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
      final itemHeight = _isGridView ? 255.0 : 110.0;
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
    List<Product> products = productProvider.products;

    // Aplicar filtro de búsqueda por texto
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      products = products.where((product) {
        final title = product.titulo.toLowerCase();
        final description = product.descripcion?.toLowerCase() ?? '';
        final category = product.categorias.toLowerCase();
        return title.contains(query) || description.contains(query) || category.contains(query);
      }).toList();

      // Guardar en historial
      SearchHistoryService.saveSearch(_searchController.text);
    }

    // Aplicar filtro de categoría
    if (_selectedCategory != 'Todos') {
      products = products.where((product) => product.categorias == _selectedCategory).toList();
    }

    // Aplicar filtros avanzados
    if (_onlyAvailable) {
      products = products.where((product) => product.disponible).toList();
    }

    if (_minPrice != null) {
      products = products.where((product) => product.precio != null && product.precio! >= _minPrice!).toList();
    }

    if (_maxPrice != null) {
      products = products.where((product) => product.precio != null && product.precio! <= _maxPrice!).toList();
    }

    _filteredProducts = products;
    _currentListIndex = 0;
    
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _showRealTimeSuggestions = false;
    });
    _filterProducts();
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _onlyAvailable = true;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
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
            child: _isGridView
                ? GridView.builder(
                    controller: _listScrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
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
                  )
                : ListView.builder(
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
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedCategory = category;
        _filterProducts();
      }),
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
            if (_showFilters)
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Limpiar filtros'),
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

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filtros Avanzados'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Precio mínimo y máximo
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Mín',
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _minPrice = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Máx',
                            hintText: '10000',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxPrice = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Solo disponibles
                  CheckboxListTile(
                    title: const Text('Solo productos disponibles'),
                    value: _onlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        _onlyAvailable = value ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearFilters();
                },
                child: const Text('Limpiar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _filterProducts();
                  setState(() {
                    _showFilters = true;
                  });
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', ...AppStrings.productCategories];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Productos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Botón para cambiar vista lista/grid
          if (_tabController?.index == 0 && _filteredProducts.isNotEmpty)
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
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
          // Barra de búsqueda con funcionalidades avanzadas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos, categorías, vendedores...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Icono de cámara
                        IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Búsqueda visual - Próximamente'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        // Icono de limpiar
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: _clearSearch,
                          ),
                      ],
                    ),
                  ),
                  onChanged: (value) => _filterProducts(),
                  onSubmitted: (value) {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _showRealTimeSuggestions = false;
                    });
                    _filterProducts();
                  },
                ),
                
                // Sugerencias en tiempo real
                if (_showRealTimeSuggestions)
                  RealTimeSearchSuggestions(
                    query: _searchController.text,
                    onSuggestionTap: (suggestion) {
                      _searchController.text = suggestion;
                      _searchFocusNode.unfocus();
                      setState(() {
                        _showRealTimeSuggestions = false;
                      });
                      _filterProducts();
                    },
                    onProductTap: (product) {
                      _searchFocusNode.unfocus();
                      setState(() {
                        _showRealTimeSuggestions = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    onCategoryTap: (category) {
                      _searchController.text = category;
                      _searchFocusNode.unfocus();
                      setState(() {
                        _showRealTimeSuggestions = false;
                        _selectedCategory = category;
                      });
                      _filterProducts();
                    },
                  ),
              ],
            ),
          ),

          // Filtros de categoría
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

          // Contador de resultados y estado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'producto' : 'productos'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                if (_filteredProducts.isNotEmpty) ...[
                  const Spacer(),
                  if (_tabController?.index == 0)
                    Text(
                      _isGridView ? 'Vista Grid' : 'Vista Lista',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (_tabController?.index == 1)
                    Text(
                      'Sincronizado',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _tabController?.index == 0
                        ? (_isGridView ? Icons.grid_view : Icons.list)
                        : Icons.sync,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
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
                // Pestaña 1: Lista con Hub de Descubrimiento
                _searchController.text.isEmpty && _selectedCategory == 'Todos'
                    ? DiscoveryHub(
                        onSearch: (query) {
                          _searchController.text = query;
                          _filterProducts();
                        },
                        onProductTap: (product) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onContactTap: _startChatWithSeller,
                      )
                    : _buildProductListView(),
                
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
    _searchFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    _mapScrollController.removeListener(_onMapScroll);
    _mapScrollController.dispose();
    super.dispose();
  }
}