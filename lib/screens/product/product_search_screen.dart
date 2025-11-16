// lib/screens/search/product_search_screen.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/providers/store_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/models/store_model.dart';
import 'package:libre_mercado_final__app/widgets/product_search_list_item.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';
import 'package:libre_mercado_final__app/widgets/store_card.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final__app/screens/search/discovery_hub.dart';
import 'package:libre_mercado_final__app/screens/search/real_time_search_suggestions.dart';
import 'package:libre_mercado_final__app/services/search_history_service.dart';
import 'package:libre_mercado_final__app/screens/store_screen.dart';

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
  List<StoreModel> _filteredStores = [];
  TabController? _tabController;
  
  final ScrollController _productsScrollController = ScrollController();
  final ScrollController _storesScrollController = ScrollController();
  
  bool _isSearchFocused = false;
  bool _showRealTimeSuggestions = false;
  bool _isProductsGridView = false;
  bool _isStoresGridView = true;
  bool _showFilters = false;
  bool _isLoadingStores = false;
  bool _storesLoaded = false;
  bool _storesInitialized = false;
  
  double? _minPrice;
  double? _maxPrice;
  bool _onlyAvailable = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _tabController = TabController(length: 2, vsync: this);
    
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
    
    // ✅ CORREGIDO: INICIALIZAR PROVIDERS AUTOMÁTICAMENTE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  // ✅ NUEVO MÉTODO: Inicializar todos los providers necesarios
  Future<void> _initializeProviders() async {
    print('🔄 INICIALIZANDO PROVIDERS...');
    
    // Inicializar ProductProvider si no está inicializado
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (!productProvider.isInitialized) {
      await productProvider.initialize();
    }
    
    // ✅ CORREGIDO: Inicializar StoreProvider automáticamente
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    if (!storeProvider.isInitialized) {
      await storeProvider.initialize();
    }
    
    // Cargar datos iniciales
    await _loadAllStoresAutomatically();
    _filterContent();
    
    setState(() {
      _storesInitialized = true;
    });
    
    print('✅ PROVIDERS INICIALIZADOS CORRECTAMENTE');
  }

  // ✅ MÉTODO COMPLETAMENTE CORREGIDO: Cargar tiendas automáticamente
  Future<void> _loadAllStoresAutomatically() async {
    if (_storesLoaded && _storesInitialized) return;
    
    setState(() {
      _isLoadingStores = true;
    });
    
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
      // ✅ VERIFICAR SI EL PROVIDER ESTÁ INICIALIZADO
      if (!storeProvider.isInitialized) {
        await storeProvider.initialize();
      }
      
      // ✅ FORZAR CARGA DE TIENDAS
      await storeProvider.fetchAllStores();
      
      setState(() {
        _filteredStores = storeProvider.stores;
        _isLoadingStores = false;
        _storesLoaded = true;
        _storesInitialized = true;
      });
      
      print('✅ TIENDAS CARGADAS AUTOMÁTICAMENTE: ${storeProvider.stores.length}');
      storeProvider.debugStores(); // Diagnóstico
      
    } catch (e) {
      print('❌ ERROR CARGANDO TIENDAS: $e');
      setState(() {
        _isLoadingStores = false;
        _storesLoaded = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _showRealTimeSuggestions = _searchController.text.isNotEmpty && _isSearchFocused;
    });
    _filterContent();
  }

  void _onSearchFocusChanged() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
      _showRealTimeSuggestions = _searchController.text.isNotEmpty && _isSearchFocused;
    });
  }

  // ✅ MÉTODO CORREGIDO: Filtrar contenido
  Future<void> _filterContent() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    // Filtrar productos
    _filteredProducts = productProvider.searchWithFilters(
      query: _searchController.text.isNotEmpty ? _searchController.text : null,
      category: _selectedCategory != 'Todos' ? _selectedCategory : null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      onlyAvailable: _onlyAvailable,
    );

    // ✅ CORREGIDO: Lógica de filtrado de tiendas mejorada
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isLoadingStores = true;
      });
      
      try {
        _filteredStores = await storeProvider.searchStores(_searchController.text);
      } catch (e) {
        print('❌ Error buscando tiendas: $e');
        _filteredStores = storeProvider.stores; // Fallback a todas las tiendas
      }
      
      setState(() {
        _isLoadingStores = false;
      });
    } else {
      // ✅ SI NO HAY BÚSQUEDA, MOSTRAR TODAS LAS TIENDAS AUTOMÁTICAMENTE
      _filteredStores = storeProvider.stores;
    }

    // Guardar en historial si hay búsqueda
    if (_searchController.text.isNotEmpty) {
      SearchHistoryService.saveSearch(_searchController.text);
    }

    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _showRealTimeSuggestions = false;
    });
    _filterContent();
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _onlyAvailable = true;
      _selectedCategory = 'Todos';
      _minPriceController.clear();
      _maxPriceController.clear();
      _showFilters = false;
    });
    _filterContent();
  }

  // ✅ MÉTODO MEJORADO: Mostrar filtros de tiendas
  void _showStoreFiltersDialog() {
    String selectedCategory = _selectedCategory;
    bool onlyWithProducts = false;
    bool onlyVerified = false;
    bool onlyProfessional = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.store, color: Colors.black),
                SizedBox(width: 8),
                Text('Filtros de Tiendas'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoría de Tienda',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedCategory,
                    items: [
                      'Todos',
                      'Tecnología',
                      'Ropa y Moda',
                      'Hogar y Jardín',
                      'Electrodomésticos',
                      'Deportes',
                      'Salud y Belleza',
                      'Automotriz',
                      'Alimentos',
                      'Libros y Educación',
                      'Juguetes y Niños',
                      'Mascotas',
                      'Arte y Manualidades',
                      'Servicios',
                      'Otros',
                    ].map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: const Text('Solo tiendas con productos'),
                    value: onlyWithProducts,
                    onChanged: (value) {
                      setState(() {
                        onlyWithProducts = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Solo tiendas verificadas'),
                    value: onlyVerified,
                    onChanged: (value) {
                      setState(() {
                        onlyVerified = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Solo tiendas profesionales'),
                    value: onlyProfessional,
                    onChanged: (value) {
                      setState(() {
                        onlyProfessional = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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
                child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedCategory = selectedCategory;
                  });
                  _filterContent();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aplicar Filtros'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  void _showFiltersDialog() {
    String selectedCategory = _selectedCategory;
    bool onlyAvailable = _onlyAvailable;
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.black),
                SizedBox(width: 8),
                Text('Filtros Avanzados'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoría',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedCategory,
                    items: [
                      'Todos',
                      'Tecnología',
                      'Ropa',
                      'Hogar',
                      'Deportes',
                      'Electrodomésticos',
                      'Videojuegos',
                      'Alimentos y bebidas',
                      'Libros',
                      'Herramientas',
                      'Juguetes',
                      'Belleza',
                      'Salud',
                      'Automóviles',
                      'Motos',
                      'Bicicletas',
                    ].map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rango de Precio',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            minPrice = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            hintText: '100000',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            maxPrice = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: const Text('Solo productos disponibles'),
                    value: onlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        onlyAvailable = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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
                child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedCategory = selectedCategory;
                    _onlyAvailable = onlyAvailable;
                    _minPrice = minPrice;
                    _maxPrice = maxPrice;
                    _showFilters = true;
                  });
                  _filterContent();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aplicar Filtros'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
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

  Widget _buildProductsSection() {
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
          return _buildEmptyProductsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await productProvider.fetchProducts();
            _filterContent();
          },
          child: Scrollbar(
            controller: _productsScrollController,
            child: _isProductsGridView
                ? GridView.builder(
                    controller: _productsScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
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
                    controller: _productsScrollController,
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

  Widget _buildStoresSection() {
    final storeProvider = Provider.of<StoreProvider>(context);
    
    // ✅ MEJORADO: Mostrar loading state
    if (_isLoadingStores && _filteredStores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando tiendas...'),
          ],
        ),
      );
    }

    // ✅ MEJORADO: Estado vacío con diagnóstico
    if (_filteredStores.isEmpty) {
      return _buildEmptyStoresState(storeProvider);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAllStoresAutomatically();
        _filterContent();
      },
      child: Scrollbar(
        controller: _storesScrollController,
        child: _isStoresGridView
            ? GridView.builder(
                controller: _storesScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _filteredStores.length,
                itemBuilder: (context, index) {
                  final store = _filteredStores[index];
                  return StoreCard(
                    store: store,
                    isGrid: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreScreen(
                            userId: store.ownerId,
                            isCurrentUser: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            : ListView.builder(
                controller: _storesScrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredStores.length,
                itemBuilder: (context, index) {
                  final store = _filteredStores[index];
                  return StoreCard(
                    store: store,
                    isGrid: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreScreen(
                            userId: store.ownerId,
                            isCurrentUser: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return SingleChildScrollView(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron productos'
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

  // ✅ NUEVO MÉTODO MEJORADO: Estado vacío de tiendas con diagnóstico
  Widget _buildEmptyStoresState(StoreProvider storeProvider) {
    return SingleChildScrollView(
      child: Container(
        height: 300, // Aumentado para mostrar más información
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            
            // Información de diagnóstico
            if (!_storesInitialized)
              Column(
                children: [
                  const Text(
                    'Inicializando tiendas...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(),
                ],
              )
            else if (_searchController.text.isNotEmpty)
              Column(
                children: [
                  const Text(
                    'No se encontraron tiendas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _clearSearch,
                    child: const Text('Limpiar búsqueda'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text(
                    'No hay tiendas disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'StoreProvider: ${storeProvider.isInitialized ? "Inicializado" : "No inicializado"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Tiendas en provider: ${storeProvider.stores.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAllStoresAutomatically,
                    child: const Text('Recargar tiendas'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Container(
        height: 200,
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
                productProvider.fetchProducts().then((_) => _filterContent());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_searchController.text.isEmpty && _selectedCategory == 'Todos') {
      return DiscoveryHub(
        onSearch: (query) {
          _searchController.text = query;
          _filterContent();
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
      );
    }

    return Column(
      children: [
        // Estadísticas de resultados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[50],
          child: Row(
            children: [
              Text(
                '${_filteredProducts.length} productos • ${_filteredStores.length} tiendas',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_tabController?.index == 0)
                IconButton(
                  icon: Icon(_isProductsGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isProductsGridView = !_isProductsGridView;
                    });
                  },
                  iconSize: 20,
                  tooltip: _isProductsGridView ? 'Vista lista' : 'Vista grid',
                ),
              if (_tabController?.index == 1)
                IconButton(
                  icon: Icon(_isStoresGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isStoresGridView = !_isStoresGridView;
                    });
                  },
                  iconSize: 20,
                  tooltip: _isStoresGridView ? 'Vista lista' : 'Vista grid',
                ),
            ],
          ),
        ),
        
        // Contenido principal (Productos o Tiendas)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductsSection(),
              _buildStoresSection(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Buscar Productos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              if (_tabController?.index == 0) {
                _showFiltersDialog(); // Filtros de productos
              } else {
                _showStoreFiltersDialog(); // Filtros de tiendas
              }
            },
            tooltip: 'Filtros',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // ✅ CORREGIDO: CARGAR TIENDAS AUTOMÁTICAMENTE AL CAMBIAR A PESTAÑA TIENDAS
            if (index == 1 && (!_storesLoaded || !_storesInitialized)) {
              _loadAllStoresAutomatically();
            }
          },
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
            Tab(icon: Icon(Icons.store), text: 'Tiendas'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos, categorías, tiendas...',
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
                    onChanged: (value) => _filterContent(),
                    onSubmitted: (value) {
                      _searchFocusNode.unfocus();
                      setState(() {
                        _showRealTimeSuggestions = false;
                      });
                      _filterContent();
                    },
                  ),
                  
                  if (_showRealTimeSuggestions)
                    RealTimeSearchSuggestions(
                      query: _searchController.text,
                      onSuggestionTap: (suggestion) {
                        _searchController.text = suggestion;
                        _searchFocusNode.unfocus();
                        setState(() {
                          _showRealTimeSuggestions = false;
                        });
                        _filterContent();
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
                        _filterContent();
                      },
                    ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _tabController?.dispose();
    _productsScrollController.dispose();
    _storesScrollController.dispose();
    super.dispose();
  }
}