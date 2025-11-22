import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../widgets/product_card.dart';
import '../constants/app_dimens.dart';
import '../utils/logger.dart';
import '../screens/product/add_product_screen.dart';

class StoreScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const StoreScreen({
    super.key,
    this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<Product> _storeProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  AppUser? _storeUser;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoreData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _filterProducts() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _storeProducts;
      });
    } else {
      setState(() {
        _filteredProducts = _storeProducts.where((product) {
          return product.titulo.toLowerCase().contains(query.toLowerCase()) ||
              product.descripcion?.toLowerCase().contains(query.toLowerCase()) == true ||
              product.categorias.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _loadStoreData() async {
    try {
      AppLogger.d('🏪 Cargando datos de tienda...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      String targetUserId;

      // Determinar qué usuario cargar
      if (widget.userId != null) {
        targetUserId = widget.userId!;
        _storeUser = await authProvider.getUserProfile(targetUserId);
      } else {
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          throw Exception('Usuario no autenticado');
        }
        targetUserId = currentUser.id;
        
        // ✅ ACTUALIZAR: Usar el nuevo método refresh
        await authProvider.refreshUserProfile();
        _storeUser = authProvider.currentUser;
      }

      // ✅ MEJORAR: Validación más específica de tienda
      if (_storeUser == null) {
        throw Exception('Perfil de usuario no encontrado');
      }

      if (!_storeUser!.hasStore) {
        throw Exception('Este usuario no tiene una tienda habilitada');
      }

      // ✅ CORREGIDO: Eliminado el parámetro 'context'
      await productProvider.fetchUserProducts(targetUserId);
      _storeProducts = productProvider.userProducts
          .where((product) => product.userId == targetUserId)
          .toList();
      
      _filteredProducts = _storeProducts;

      setState(() {
        _isLoading = false;
      });

      AppLogger.d('✅ Tienda cargada: ${_storeUser!.storeName}');
      AppLogger.d('📊 Productos cargados: ${_storeProducts.length}');
      
    } catch (e) {
      AppLogger.e('Error cargando tienda', e);
      setState(() {
        _error = 'Error al cargar la tienda: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildStoreHeader() {
    if (_storeUser == null) return const SizedBox();

    // ✅ USAR CONTADOR LOCAL en lugar del del perfil
    final productCount = _storeProducts.length;
    final displayProductCount = productCount > 0 ? productCount : (_storeUser!.actualProductCount ?? 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner de tienda
          if (_storeUser!.storeBannerUrl != null && _storeUser!.storeBannerUrl!.isNotEmpty)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                image: DecorationImage(
                  image: NetworkImage(_storeUser!.storeBannerUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                color: Colors.grey,
              ),
              child: Icon(
                Icons.storefront,
                size: 60,
                color: Colors.grey[300],
              ),
            ),

          // Información de la tienda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Logo de tienda
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadiusL),
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: _storeUser!.storeLogoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_storeUser!.storeLogoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _storeUser!.storeLogoUrl == null
                          ? Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storeUser!.storeDisplayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_storeUser!.storeCategory != null)
                            Text(
                              _storeUser!.storeCategory!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _storeUser!.storeRatingText,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.shopping_bag, size: 16, color: Colors.black),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  // ✅ USAR CONTADOR LOCAL
                                  '$displayProductCount productos • ${_storeUser!.storeTotalSales} ventas',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Descripción de tienda
                if (_storeUser!.storeDescription != null && _storeUser!.storeDescription!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                    ),
                    child: Text(
                      _storeUser!.storeDescription!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Información de contacto - CORREGIDO
                if (_storeUser!.storePhone != null || 
                    _storeUser!.storeEmail != null || 
                    _storeUser!.storeAddress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final chips = <Widget>[];
                        
                        if (_storeUser!.storePhone != null && _storeUser!.storePhone!.isNotEmpty) {
                          chips.add(_buildContactChip(Icons.phone, _storeUser!.storePhone!, availableWidth));
                        }
                        if (_storeUser!.storeEmail != null && _storeUser!.storeEmail!.isNotEmpty) {
                          chips.add(_buildContactChip(Icons.email, _storeUser!.storeEmail!, availableWidth));
                        }
                        if (_storeUser!.storeAddress != null && _storeUser!.storeAddress!.isNotEmpty) {
                          chips.add(_buildContactChip(Icons.location_on, _storeUser!.storeAddress!, availableWidth));
                        }
                        
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          runAlignment: WrapAlignment.start,
                          children: chips,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text, double availableWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableWidth * 0.6);
    
    final textWidth = textPainter.size.width;
    final totalWidth = textWidth + 44; // 44 = icon(14) + spacing(6) + padding(24)
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: totalWidth.clamp(0, availableWidth * 0.8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar productos en la tienda...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay productos en esta tienda',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando el vendedor agregue productos, aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ProductCard(
              product: _filteredProducts[index],
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product-detail',
                  arguments: {'product': _filteredProducts[index]},
                );
              },
            );
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    if (_filteredProducts.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'Catálogo de Productos (${_filteredProducts.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.black),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStoreData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStoreData,
        color: Colors.black,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStoreHeader(),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            _buildProductsHeader(),
            _buildProductsGrid(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_storeUser?.storeDisplayName ?? 'Tienda'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (widget.isCurrentUser) 
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/edit-store');
              },
              tooltip: 'Editar Tienda',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: widget.isCurrentUser
          ? FloatingActionButton(
              onPressed: _navigateToAddProduct,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              tooltip: 'Agregar Producto',
            )
          : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}