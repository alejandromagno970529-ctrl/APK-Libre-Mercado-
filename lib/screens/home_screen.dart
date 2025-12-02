// lib/screens/home_screen.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ CORREGIDO: Importaciones con el nombre correcto del paquete
import 'package:libre_mercado_final_app/providers/product_provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/providers/chat_provider.dart';
import 'package:libre_mercado_final_app/providers/story_provider.dart';

import 'package:libre_mercado_final_app/models/product_model.dart';
import 'package:libre_mercado_final_app/models/story_model.dart';

import 'package:libre_mercado_final_app/screens/product/add_product_screen.dart';
import 'package:libre_mercado_final_app/screens/chat/chat_list_screen.dart';
import 'package:libre_mercado_final_app/screens/profile/profile_screen.dart';

// ✅ CORREGIDO: Importación desde la carpeta correcta
import 'package:libre_mercado_final_app/screens/product/product_search_screen.dart';

import 'package:libre_mercado_final_app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final_app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final_app/screens/stories/story_view_screen.dart';
import 'package:libre_mercado_final_app/screens/stories/create_story_screen.dart';
import 'package:libre_mercado_final_app/widgets/product_card.dart';

// Importamos las constantes para tener acceso a AppStrings
import 'package:libre_mercado_final_app/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const ProductSearchScreen(), // ✅ CORREGIDO: Pantalla de búsqueda
    const AddProductPlaceholder(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _scrollController = ScrollController();

  String _selectedCategory = 'Todos';
  List<Product> _filteredProducts = [];
  List<Product> _displayedProducts = [];
  final int _productsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;
    
    setState(() => _isLoadingMore = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final startIndex = _displayedProducts.length;
    final endIndex = startIndex + _productsPerPage;
    
    if (endIndex >= _filteredProducts.length) {
      setState(() {
        _displayedProducts = _filteredProducts;
        _hasMoreProducts = false;
      });
    } else {
      setState(() {
        _displayedProducts = _filteredProducts.sublist(0, endIndex);
      });
    }
    
    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      await productProvider.fetchProducts();
      await storyProvider.fetchStories();
      if (mounted) _applyFilter();
    } catch (e) {
      // Manejar error silenciosamente
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (!mounted) return;
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      if (_selectedCategory == 'Todos') {
        _filteredProducts = productProvider.products;
      } else {
        _filteredProducts = productProvider.products
            .where((product) => product.categorias == _selectedCategory)
            .toList();
      }
      
      _hasMoreProducts = _filteredProducts.length > _productsPerPage;
      _displayedProducts = _filteredProducts.length > _productsPerPage
          ? _filteredProducts.sublist(0, _productsPerPage)
          : _filteredProducts;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoadingMore = false;
      _hasMoreProducts = true;
    });
    _applyFilter();
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      // ✅ CORREGIDO: Usar Navigator.pushNamed en lugar de MaterialPageRoute
      Navigator.pushNamed(
        context, 
        '/search',
        arguments: {'initialQuery': query},
      );
    }
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
      // ✅ CORRECCIÓN COMPLETA: Pasar todos los parámetros requeridos
      final chatId = await chatProvider.getOrCreateChat(
        productId: product.id,
        buyerId: currentUser.id,
        sellerId: product.userId,
        buyerName: currentUser.username,    // ✅ PARÁMETRO REQUERIDO
        productTitle: product.titulo,       // ✅ PARÁMETRO REQUERIDO
      );

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            productId: product.id,
            otherUserId: product.userId,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar productos...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onSubmitted: _performSearch,
              )
            : const Text(
                'Libre Mercado',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
        actions: [
          // ✅ ELIMINADO: UserProfileHeader y botón de perfil
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildStoriesSection(),
                  SliverToBoxAdapter(
                    child: _buildCategorySection(),
                  ),
                  _buildProductGrid(),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStoriesSection() {
    final authProvider = context.watch<AuthProvider>();
    final storyProvider = context.watch<StoryProvider>();
    final stories = storyProvider.stories;
    final hasStories = stories.isNotEmpty || authProvider.currentUser != null;
    
    if (!hasStories) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Historias Destacadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (authProvider.currentUser != null ? 1 : 0) + stories.length,
                itemBuilder: (context, index) {
                  if (authProvider.currentUser != null && index == 0) {
                    return _buildCreateStoryButton();
                  }
                  final storyIndex = authProvider.currentUser != null ? index - 1 : index;
                  return _buildStoryCircle(stories[storyIndex]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateStoryButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateStoryScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.grey[600], size: 28),
                  const SizedBox(height: 2),
                  Text(
                    'Crear',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ignore: prefer_const_constructors
            Text(
              'Tu historia',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(Story story) {
    final authProvider = context.read<AuthProvider>();
    final storyProvider = context.watch<StoryProvider>();
    final currentUserId = authProvider.currentUser?.id;
    final isOwner = currentUserId == story.userId;
    final stories = storyProvider.stories;
    
    return GestureDetector(
      onTap: () {
        final initialIndex = stories.indexWhere((s) => s.id == story.id);
        if (initialIndex != -1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewScreen(
                stories: stories,
                initialIndex: initialIndex,
                isOwner: isOwner,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: story.isAboutToExpire 
                    ? const LinearGradient(
                        colors: [Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image: story.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(story.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: story.imageUrl.isEmpty
                    ? Icon(Icons.person, color: Colors.grey[400], size: 24)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.username,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    // Usar todas las categorías definidas en constants.dart
    final categories = ['Todos', ...AppStrings.productCategories];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryChip(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700),
        backgroundColor: Colors.white,
        selectedColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildProductGrid() {
    final productProvider = context.watch<ProductProvider>();

    if (productProvider.error != null) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                productProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => productProvider.fetchProducts(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayedProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                _selectedCategory == 'Todos'
                    ? Icons.shopping_bag_outlined
                    : Icons.filter_alt_outlined,
                size: 50,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedCategory == 'Todos'
                    ? 'No hay productos disponibles'
                    : 'No hay productos en $_selectedCategory',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ));
                },
                child: const Text('PUBLICAR PRODUCTO', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65, // ✅ ACTUALIZADO: 0.68 → 0.65
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _displayedProducts[index];
            return ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
              onContactTap: () => _startChatWithSeller(product),
            );
          },
          childCount: _displayedProducts.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class AddProductPlaceholder extends StatelessWidget {
  const AddProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '¿Qué quieres publicar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('PUBLICAR PRODUCTO'),
            ),
          ],
        ),
      ),
    );
  }
}