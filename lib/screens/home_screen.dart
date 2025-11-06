import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/providers/story_provider.dart';

import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/models/story_model.dart';

import 'package:libre_mercado_final__app/screens/product/add_product_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_list_screen.dart';
import 'package:libre_mercado_final__app/screens/profile/profile_screen.dart';
import 'package:libre_mercado_final__app/screens/search_screen.dart';
import 'package:libre_mercado_final__app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final__app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final__app/screens/stories/story_view_screen.dart';
import 'package:libre_mercado_final__app/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
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

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    });
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
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
                  // Sección de historias - CORREGIDO DEFINITIVAMENTE
                  SliverToBoxAdapter(
                    child: _buildStoriesSection(),
                  ),
                  // Categorías
                  SliverToBoxAdapter(
                    child: _buildCategorySection(),
                  ),
                  // Productos
                  _buildProductGrid(),
                ],
              ),
            ),
    );
  }

  // CORREGIDO DEFINITIVAMENTE: Sección de historias sin overflow
  Widget _buildStoriesSection() {
    final authProvider = context.watch<AuthProvider>();
    final storyProvider = context.watch<StoryProvider>();
    final stories = storyProvider.stories;
    final hasStories = stories.isNotEmpty || authProvider.currentUser != null;
    
    if (!hasStories) {
      return const SizedBox.shrink();
    }

    // SOLUCIÓN FINAL: Ajuste preciso de alturas - 2px menos
    return Container(
      height: 154, // Ajustado de 156 a 154 (2px menos para eliminar el overflow final)
      padding: const EdgeInsets.symmetric(vertical: 6), // Reducido de 8 a 6
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
          const SizedBox(height: 8), // Reducido de 10 a 8
          // CORREGIDO: Altura ajustada para el ListView
          SizedBox(
            height: 104, // Ajustado de 106 a 104 (2px menos)
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (authProvider.currentUser != null) _buildCreateStoryButton(),
                ...stories.map((story) => _buildStoryCircle(story)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CORREGIDO: Widget de crear historia - ajustes finales
  Widget _buildCreateStoryButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddProductScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Círculo
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.grey[600], size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'Crear',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Texto - CORREGIDO: Altura ajustada
            SizedBox(
              height: 24, // Reducido de 26 a 24 (2px menos)
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tu historia',
                    style: const TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CORREGIDO: Widget de círculo de historia - ajustes finales
  Widget _buildStoryCircle(Story story) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewScreen(story: story),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Círculo con gradiente
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2.5),
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
                    ? Icon(Icons.person, color: Colors.grey[400], size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // Texto - CORREGIDO: Altura ajustada
            SizedBox(
              height: 24, // Reducido de 26 a 24 (2px menos)
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story.username,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (!story.isExpired) ...[
                    const SizedBox(height: 1),
                    Text(
                      story.timeRemaining,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Tecnología', 'Ropa', 'Hogar', 'Electro', 'Deportes', 'Otros']
                    .map((category) => _buildCategoryChip(category))
                    .toList(),
              ),
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

    if (_filteredProducts.isEmpty) {
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
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
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
          childCount: _filteredProducts.length,
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