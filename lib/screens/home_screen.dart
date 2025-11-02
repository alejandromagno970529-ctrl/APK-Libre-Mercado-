import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/screens/product/add_product_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_list_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final__app/screens/profile/profile_screen.dart';
import 'package:libre_mercado_final__app/screens/catalog_screen.dart';
import 'package:libre_mercado_final__app/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const SearchScreen(),
    const AddProductPlaceholder(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Publicar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _scrollController = ScrollController();
  String _selectedCategory = 'Todos';
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
    _applyFilter();
  }

  void _applyFilter() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (_selectedCategory == 'Todos') {
      setState(() {
        _filteredProducts = productProvider.products;
      });
    } else {
      setState(() {
        _filteredProducts = productProvider.products
            .where((product) => product.categorias == _selectedCategory)
            .toList();
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilter();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(initialQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            floating: true,
            snap: true,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color.alphaBlend(const Color.fromRGBO(0, 0, 0, 178), Colors.black87)
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    onSubmitted: _performSearch,
                  )
                : const Text(
                    'Libre Mercado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              if (!_isSearching)
                const IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: null,
                ),
            ],
          ),

          // HISTORIAS DESTACADAS
          SliverToBoxAdapter(
            child: _buildFeaturedStories(),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Categorías',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != 'Todos')
                        TextButton(
                          onPressed: () => _onCategorySelected('Todos'),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Todos'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Tecnología'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Ropa'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Hogar'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Electro'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Deportes'),
                        const SizedBox(width: 6),
                        _buildCategoryChip('Otros'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedCategory == 'Todos' 
                            ? 'Productos Disponibles'
                            : 'Productos en $_selectedCategory',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          return Text(
                            '${_filteredProducts.length} productos',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_selectedCategory != 'Todos')
                    Text(
                      'Filtrado por: $_selectedCategory',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),

          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                  ),
                );
              }

              if (productProvider.error != null) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      height: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error al cargar productos',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => productProvider.fetchProducts(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (_filteredProducts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      height: 280,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedCategory == 'Todos' 
                                ? Icons.shopping_bag_outlined
                                : Icons.filter_alt_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == 'Todos'
                                ? 'No hay productos disponibles'
                                : 'No hay productos en $_selectedCategory',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory == 'Todos'
                                ? 'Sé el primero en publicar un producto\ny comienza a vender en tu comunidad'
                                : 'No encontramos productos en esta categoría\nPrueba con otra categoría',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddProductScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'PUBLICAR PRODUCTO',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_selectedCategory != 'Todos')
                            TextButton(
                              onPressed: () => _onCategorySelected('Todos'),
                              child: const Text(
                                'Ver todos los productos',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.68, // ✅ AJUSTADO: Más bajo para evitar overflow
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(product: product);
                  },
                  childCount: _filteredProducts.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStories() {
    final stories = [
      {'title': 'Ofertas', 'icon': Icons.local_offer, 'color': Colors.blue},
      {'title': 'Nuevo', 'icon': Icons.fiber_new, 'color': Colors.green},
      {'title': 'Popular', 'icon': Icons.trending_up, 'color': Colors.orange},
      {'title': 'Cerca', 'icon': Icons.location_on, 'color': Colors.red},
      {'title': 'Destacado', 'icon': Icons.star, 'color': Colors.purple},
      {'title': 'Ver Todo', 'icon': Icons.apps, 'color': Colors.amber},
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: stories.map((story) {
          return _buildStoryItem(
            story['title'] as String,
            story['icon'] as IconData,
            story['color'] as Color,
          );
        }).toList(),
      )
    );
  }

  Widget _buildStoryItem(String title, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color.alphaBlend(color.withAlpha(25), Colors.white),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color.alphaBlend(color.withAlpha(51), Colors.transparent),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _contactSeller(BuildContext context, Product product) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para contactar al vendedor')),
      );
      return;
    }

    if (authProvider.currentUser!.id == product.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes contactarte a ti mismo')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutureBuilder<String>(
          future: chatProvider.getOrCreateChat(
            productId: product.id,
            buyerId: authProvider.currentUser!.id,
            sellerId: product.userId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            
            return ChatScreen(
              chatId: snapshot.data!,
              productId: product.id,
              otherUserId: product.userId,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: SizedBox(
          height: 220, // ✅ ALTURA REDUCIDA (antes 240px)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGEN - ALTURA MÁS PEQUEÑA
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Container(
                  height: 110, // ✅ REDUCIDO (antes 120px)
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        product.imagenUrl ?? 
                        'https://picsum.photos/200/200?random=${product.id}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: product.disponible == false
                      ? Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Text(
                              'VENDIDO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10, // ✅ TEXTO MÁS PEQUEÑO
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),

              // CONTENIDO - ESPACIOS REDUCIDOS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6.0), // ✅ PADDING REDUCIDO
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // TÍTULO Y PRECIO - CONTENIDO MÍNIMO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // ✅ TEXTO MÁS PEQUEÑO
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1), // ✅ ESPACIO REDUCIDO
                          Text(
                            '\$${product.precio.toStringAsFixed(0)} ${product.moneda}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 11, // ✅ TEXTO MÁS PEQUEÑO
                            ),
                          ),
                        ],
                      ),

                      // METADATOS - MÁS COMPACTO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FECHA - UNA SOLA LÍNEA
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 7, // ✅ ICONO MÁS PEQUEÑO
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 1), // ✅ ESPACIO REDUCIDO
                              Text(
                                _formatDate(product.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 7, // ✅ TEXTO MÁS PEQUEÑO
                                ),
                              ),
                            ],
                          ),
                          
                          // CATEGORÍA - UNA SOLA LÍNEA
                          Text(
                            product.categorias,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 8, // ✅ TEXTO MÁS PEQUEÑO
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // CIUDAD - SOLO SI EXISTE, MÁS COMPACTO
                          if (product.city != null && product.city!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 0), // ✅ SIN ESPACIO
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 6, // ✅ ICONO MÁS PEQUEÑO
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 1), // ✅ ESPACIO MÍNIMO
                                  Expanded(
                                    child: Text(
                                      product.city!,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 6, // ✅ TEXTO MÁS PEQUEÑO
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // BOTÓN CONTACTAR - MÁS COMPACTO
                      SizedBox(
                        width: double.infinity,
                        height: 24, // ✅ ALTURA REDUCIDA (antes 28px)
                        child: ElevatedButton(
                          onPressed: () {
                            _contactSeller(context, product);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            textStyle: const TextStyle(
                              fontSize: 9, // ✅ TEXTO MÁS PEQUEÑO
                              fontWeight: FontWeight.w600,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Contactar'),
                        ),
                      ),
                    ],
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

class AddProductPlaceholder extends StatelessWidget {
  const AddProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate, size: 50, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              '¿Qué quieres publicar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, size: 20),
                    SizedBox(width: 8),
                    Text('Producto'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add-story');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories, size: 20),
                    SizedBox(width: 8),
                    Text('Historia (24h)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PANTALLA PARA PUBLICAR HISTORIAS
class AddStoryScreen extends StatelessWidget {
  const AddStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Historia'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historia publicada por 24 horas'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crea una historia que desaparecerá en 24 horas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Placeholder(
              fallbackHeight: 200,
              color: Colors.purple,
            ),
            SizedBox(height: 20),
            Text(
              'Características de las historias:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('• Duración: 24 horas'),
            Text('• Visibilidad: Todos los usuarios'),
            Text('• Contenido: Imágenes o texto'),
            Text('• Automáticamente se eliminan'),
          ],
        ),
      ),
    );
  }
}