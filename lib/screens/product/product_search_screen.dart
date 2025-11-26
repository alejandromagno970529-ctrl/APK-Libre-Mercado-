// lib/screens/search/product_search_screen.dart - VERSIÓN FINAL (SIN OVERFLOW EN BUSCADOR NI EN DIÁLOGOS)
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
  
  // ✅ CONTROLADORES
  final TextEditingController _productsSearchController = TextEditingController();
  final TextEditingController _storesSearchController = TextEditingController();
  final FocusNode _productsSearchFocusNode = FocusNode();
  final FocusNode _storesSearchFocusNode = FocusNode();
  
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  // ✅ ESTADOS
  String _productsSelectedCategory = 'Todos';
  String _storesSelectedCategory = 'Todos';
  List<Product> _filteredProducts = [];
  List<StoreModel> _filteredStores = [];
  TabController? _tabController;
  
  final ScrollController _productsScrollController = ScrollController();
  final ScrollController _storesScrollController = ScrollController();
  
  // ✅ ESTADOS DE UI
  bool _isProductsSearchFocused = false;
  bool _isStoresSearchFocused = false;
  bool _showProductsRealTimeSuggestions = false;
  // ignore: unused_field
  bool _showStoresRealTimeSuggestions = false;
  bool _isProductsGridView = false;
  bool _isStoresGridView = false;
  bool _showProductsFilters = false;
  // ignore: unused_field
  bool _showStoresFilters = false;
  bool _isLoadingStores = false;
  bool _storesLoaded = false;
  bool _storesInitialized = false;
  
  double? _minPrice;
  double? _maxPrice;
  bool _onlyAvailable = true;

  // Altura estimada de la barra de búsqueda para el padding
  final double _searchBarHeight = 90.0;

  @override
  void initState() {
    super.initState();
    
    _productsSearchController.text = widget.initialQuery;
    _storesSearchController.text = '';
    
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController?.addListener(() {
      if (_tabController!.indexIsChanging) {
        _productsSearchFocusNode.unfocus();
        _storesSearchFocusNode.unfocus();
        setState(() {
          _showProductsRealTimeSuggestions = false;
          _showStoresRealTimeSuggestions = false;
        });
        
        if (_tabController!.index == 1 && (!_storesLoaded || !_storesInitialized)) {
          _loadAllStoresAutomatically();
        }
      }
      // Forzar reconstrucción para actualizar UI
      if (mounted) setState(() {});
    });
    
    _productsSearchController.addListener(_onProductsSearchChanged);
    _storesSearchController.addListener(_onStoresSearchChanged);
    _productsSearchFocusNode.addListener(_onProductsSearchFocusChanged);
    _storesSearchFocusNode.addListener(_onStoresSearchFocusChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🎯 INICIANDO PANTALLA DE BÚSQUEDA');
      await _initializeProviders();
      await _loadAllStoresAutomatically();
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeProviders() async {
    print('🔄 INICIALIZANDO PROVIDERS...');
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (!productProvider.isInitialized) {
      await productProvider.initialize();
    }
    
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    if (!storeProvider.isInitialized) {
      await storeProvider.initialize();
    }
    
    if (storeProvider.stores.isEmpty) {
      await storeProvider.fetchStoresWithRealData();
    }
    
    _filteredStores = storeProvider.stores;
    _filterProducts();
    _filterStores();
    
    if (mounted) {
      setState(() {
        _storesInitialized = true;
      });
    }
    print('✅ PROVIDERS INICIALIZADOS CORRECTAMENTE');
  }

  Future<void> _loadAllStoresAutomatically() async {
    if (_storesLoaded && _storesInitialized) return;
    
    print('🔄 CARGANDO TIENDAS CON DATOS REALES...');
    
    setState(() {
      _isLoadingStores = true;
    });
    
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
      if (!storeProvider.isInitialized) {
        await storeProvider.initialize();
      } else {
        await storeProvider.fetchStoresWithRealData();
      }
      
      _filteredStores = storeProvider.stores;
      _logRealTimeStoreDiagnostics(storeProvider);
      
      if (mounted) {
        setState(() {
          _isLoadingStores = false;
          _storesLoaded = true;
          _storesInitialized = true;
        });
      }
      
      print('✅ TIENDAS CARGADAS EXITOSAMENTE: ${storeProvider.stores.length}');
      
    } catch (e) {
      print('❌ ERROR CARGANDO TIENDAS: $e');
      if (mounted) {
        setState(() {
          _isLoadingStores = false;
          _storesLoaded = false;
        });
      }
    }
  }

  void _logRealTimeStoreDiagnostics(StoreProvider storeProvider) {
    print('''
🎯 DIAGNÓSTICO TIENDAS CON DATOS REALES:
   =====================================
   - Total tiendas: ${storeProvider.stores.length}
   - Tiendas con productos: ${storeProvider.stores.where((s) => s.productCount > 0).length}
   - Tiendas con ventas: ${storeProvider.stores.where((s) => s.totalSales > 0).length}
''');
  }

  // ✅ MÉTODOS DE CAMBIO DE ESTADO DE BÚSQUEDA
  void _onProductsSearchChanged() {
    setState(() {
      _showProductsRealTimeSuggestions = _productsSearchController.text.isNotEmpty && _isProductsSearchFocused;
    });
    _filterProducts();
  }

  void _onProductsSearchFocusChanged() {
    setState(() {
      _isProductsSearchFocused = _productsSearchFocusNode.hasFocus;
      _showProductsRealTimeSuggestions = _productsSearchController.text.isNotEmpty && _isProductsSearchFocused;
    });
  }

  void _onStoresSearchChanged() {
    setState(() {
      _showStoresRealTimeSuggestions = _storesSearchController.text.isNotEmpty && _isStoresSearchFocused;
    });
    _filterStores();
  }

  void _onStoresSearchFocusChanged() {
    setState(() {
      _isStoresSearchFocused = _storesSearchFocusNode.hasFocus;
      _showStoresRealTimeSuggestions = _storesSearchController.text.isNotEmpty && _isStoresSearchFocused;
    });
  }

  // ✅ MÉTODOS DE FILTRADO
  void _filterProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    _filteredProducts = productProvider.searchWithFilters(
      query: _productsSearchController.text.isNotEmpty ? _productsSearchController.text : null,
      category: _productsSelectedCategory != 'Todos' ? _productsSelectedCategory : null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      onlyAvailable: _onlyAvailable,
    );

    if (_productsSearchController.text.isNotEmpty) {
      SearchHistoryService.saveSearch(_productsSearchController.text);
    }

    if (mounted) setState(() {});
  }

  void _filterStores() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);

    try {
      _filteredStores = storeProvider.searchWithFilters(
        query: _storesSearchController.text.isNotEmpty ? _storesSearchController.text : null,
        category: _storesSelectedCategory != 'Todos' ? _storesSelectedCategory : null,
      );
    } catch (e) {
      print('❌ Error filtrando tiendas: $e');
      _filteredStores = storeProvider.stores;
    }

    if (mounted) setState(() {});
  }

  // ✅ MÉTODOS DE LIMPIEZA
  void _clearProductsSearch() {
    _productsSearchController.clear();
    _productsSearchFocusNode.unfocus();
    setState(() {
      _showProductsRealTimeSuggestions = false;
    });
    _filterProducts();
  }

  void _clearStoresSearch() {
    _storesSearchController.clear();
    _storesSearchFocusNode.unfocus();
    setState(() {
      _showStoresRealTimeSuggestions = false;
    });
    _filterStores();
  }

  void _clearProductsFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _onlyAvailable = true;
      _productsSelectedCategory = 'Todos';
      _minPriceController.clear();
      _maxPriceController.clear();
      _showProductsFilters = false;
    });
    _filterProducts();
  }

  void _clearStoresFilters() {
    setState(() {
      _storesSelectedCategory = 'Todos';
      _showStoresFilters = false;
    });
    _filterStores();
  }

  // ✅ DIÁLOGO DE FILTROS DE PRODUCTOS (CORREGIDO OVERFLOW)
  void _showProductsFiltersDialog() {
    String selectedCategory = _productsSelectedCategory;
    bool onlyAvailable = _onlyAvailable;
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            // 👇👇 AQUÍ ESTÁ LA CORRECCIÓN DEL TÍTULO 👇👇
            title: const Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.black),
                SizedBox(width: 8),
                // Usamos Expanded para evitar que el texto se salga si es muy largo
                Expanded(
                  child: Text(
                    'Filtros de Productos',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                    isExpanded: true, // Asegura que el dropdown no cause overflow
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
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    contentPadding: EdgeInsets.zero, // Reduce padding lateral
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearProductsFilters();
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
                    _productsSelectedCategory = selectedCategory;
                    _onlyAvailable = onlyAvailable;
                    _minPrice = minPrice;
                    _maxPrice = maxPrice;
                    _showProductsFilters = true;
                  });
                  _filterProducts();
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

  // ✅ DIÁLOGO DE FILTROS DE TIENDAS (PREVENCIÓN DE OVERFLOW)
  void _showStoresFiltersDialog() {
    String selectedCategory = _storesSelectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            // 👇 También protegemos el título aquí
            title: const Row(
              children: [
                Icon(Icons.store, color: Colors.black),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtros de Tiendas',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                    isExpanded: true,
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
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearStoresFilters();
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
                    _storesSelectedCategory = selectedCategory;
                  });
                  _filterStores();
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

  // ✅ MÉTODO: INICIAR CHAT
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
        sellerId: product.userId, buyerName: '', productTitle: '',
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

  // ✅ WIDGETS DE LISTAS (PRODUCTOS) - STACK SAFE
  Widget _buildProductsSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.error != null) {
          return _buildProductsErrorState(productProvider.error!);
        }

        if (_filteredProducts.isEmpty) {
          return _buildEmptyProductsState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: () async {
                await productProvider.fetchProducts();
                _filterProducts();
              },
              child: Scrollbar(
                controller: _productsScrollController,
                child: _isProductsGridView
                    ? GridView.builder(
                        controller: _productsScrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
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
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
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
      },
    );
  }

  // ✅ WIDGETS DE LISTAS (TIENDAS) - STACK SAFE
  Widget _buildStoresSection() {
    final storeProvider = Provider.of<StoreProvider>(context);
    
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

    if (_filteredStores.isEmpty) {
      return _buildEmptyStoresState(storeProvider);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () async {
            await _loadAllStoresAutomatically();
            _filterStores();
          },
          child: Scrollbar(
            controller: _storesScrollController,
            child: _isStoresGridView
                ? GridView.builder(
                    controller: _storesScrollController,
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
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
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
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
      },
    );
  }

  // ✅ WIDGETS DE ESTADOS VACÍOS
  Widget _buildEmptyProductsState() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _productsSearchController.text.isNotEmpty
                    ? 'No se encontraron productos'
                    : 'No hay productos disponibles',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_productsSearchController.text.isNotEmpty)
                OutlinedButton(
                  onPressed: _clearProductsSearch,
                  child: const Text('Limpiar búsqueda'),
                ),
              if (_showProductsFilters)
                OutlinedButton(
                  onPressed: _clearProductsFilters,
                  child: const Text('Limpiar filtros'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStoresState(StoreProvider storeProvider) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              
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
              else if (_storesSearchController.text.isNotEmpty)
                Column(
                  children: [
                    const Text(
                      'No se encontraron tiendas',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _clearStoresSearch,
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
                      'Tiendas cargadas: ${storeProvider.stores.length}',
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
      ),
    );
  }

  Widget _buildProductsErrorState(String error) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Container(
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
      ),
    );
  }

  // ✅ BARRAS FLOTANTES
  Widget _buildProductsSearchBar() {
    return Container(
      color: Colors.white, 
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _productsSearchController,
            focusNode: _productsSearchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar productos, categorías...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
              suffixIcon: _productsSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearProductsSearch,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) => _filterProducts(),
            onSubmitted: (value) {
              _productsSearchFocusNode.unfocus();
              setState(() {
                _showProductsRealTimeSuggestions = false;
              });
              _filterProducts();
            },
          ),
          
          if (_showProductsRealTimeSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: RealTimeSearchSuggestions(
                query: _productsSearchController.text,
                onSuggestionTap: (suggestion) {
                  _productsSearchController.text = suggestion;
                  _productsSearchFocusNode.unfocus();
                  setState(() {
                    _showProductsRealTimeSuggestions = false;
                  });
                  _filterProducts();
                },
                onProductTap: (product) {
                  _productsSearchFocusNode.unfocus();
                  setState(() {
                    _showProductsRealTimeSuggestions = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                onCategoryTap: (category) {
                  _productsSearchController.text = category;
                  _productsSearchFocusNode.unfocus();
                  setState(() {
                    _showProductsRealTimeSuggestions = false;
                    _productsSelectedCategory = category;
                  });
                  _filterProducts();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoresSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _storesSearchController,
            focusNode: _storesSearchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar tiendas por nombre...',
              prefixIcon: const Icon(Icons.store, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
              suffixIcon: _storesSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearStoresSearch,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) => _filterStores(),
            onSubmitted: (value) {
              _storesSearchFocusNode.unfocus();
              setState(() {
                _showStoresRealTimeSuggestions = false;
              });
              _filterStores();
            },
          ),
        ],
      ),
    );
  }

  // ✅ MAIN BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                _showProductsFiltersDialog();
              } else {
                _showStoresFiltersDialog();
              }
            },
            tooltip: 'Filtros',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {},
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
        child: Stack(
          children: [
            // 1. CONTENIDO ABAJO
            Padding(
              padding: EdgeInsets.only(top: _searchBarHeight), 
              child: TabBarView(
                controller: _tabController,
                children: [
                  // PESTAÑA PRODUCTOS
                  Column(
                    children: [
                      if (_productsSearchController.text.isNotEmpty || _productsSelectedCategory != 'Todos')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              Text(
                                '${_filteredProducts.length} productos encontrados',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
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
                            ],
                          ),
                        ),
                      
                      Expanded(
                        child: _productsSearchController.text.isEmpty && _productsSelectedCategory == 'Todos'
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: DiscoveryHub(
                                        onSearch: (query) {
                                          _productsSearchController.text = query;
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
                                      ),
                                    ),
                                  );
                                },
                              )
                            : _buildProductsSection(),
                      ),
                    ],
                  ),

                  // PESTAÑA TIENDAS
                  Column(
                    children: [
                      if (_storesSearchController.text.isNotEmpty || _storesSelectedCategory != 'Todos')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              Text(
                                '${_filteredStores.length} tiendas encontradas',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
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
                      
                      Expanded(
                        child: _buildStoresSection(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. BARRA SUPERIOR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _tabController?.index == 0 
                  ? _buildProductsSearchBar()
                  : _buildStoresSearchBar(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productsSearchController.dispose();
    _storesSearchController.dispose();
    _productsSearchFocusNode.dispose();
    _storesSearchFocusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _tabController?.dispose();
    _productsScrollController.dispose();
    _storesScrollController.dispose();
    super.dispose();
  }
}