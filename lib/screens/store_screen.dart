import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart'; // ✅ AGREGAR IMPORTACIÓN DE AppUser
import '../widgets/product_card.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../utils/logger.dart';

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
  bool _isLoading = true;
  String? _error;
  AppUser? _storeUser;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      AppLogger.d('🏪 Cargando datos de tienda...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        _storeUser = currentUser;
      }

      if (_storeUser == null || !_storeUser!.hasStore) {
        throw Exception('Usuario no tiene tienda habilitada');
      }

      // Cargar productos de la tienda
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      _storeProducts = await productProvider.getProductsByUser(targetUserId);

      setState(() {
        _isLoading = false;
      });

      AppLogger.d('✅ Tienda cargada: ${_storeUser!.storeName} - ${_storeProducts.length} productos');
    } catch (e) {
      AppLogger.e('Error cargando tienda', e);
      setState(() {
        _error = 'Error al cargar tienda: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildStoreHeader() {
    if (_storeUser == null) return const SizedBox();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Banner de tienda
          if (_storeUser!.storeBannerUrl != null && _storeUser!.storeBannerUrl!.isNotEmpty)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
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
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AppColors.primary.withOpacity(0.8),
              ),
              child: Icon(
                Icons.storefront,
                size: 60,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.7),
              ),
            ),

          // Información de la tienda
          Padding(
            padding: AppDimens.paddingAllL,
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
                              color: AppColors.textSecondary,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_storeUser!.storeCategory != null)
                            Text(
                              _storeUser!.storeCategory!,
                              style: TextStyle(
                                fontSize: 14,
                                // ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _storeUser!.storeRatingText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.shopping_bag, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _storeUser!.storeStatsText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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
                    padding: AppDimens.paddingAllM,
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                    ),
                    child: Text(
                      _storeUser!.storeDescription!,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Información de contacto
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_storeUser!.storePhone != null && _storeUser!.storePhone!.isNotEmpty)
                      _buildContactChip(Icons.phone, _storeUser!.storePhone!),
                    if (_storeUser!.storeEmail != null && _storeUser!.storeEmail!.isNotEmpty)
                      _buildContactChip(Icons.email, _storeUser!.storeEmail!),
                    if (_storeUser!.storeAddress != null && _storeUser!.storeAddress!.isNotEmpty)
                      _buildContactChip(Icons.location_on, _storeUser!.storeAddress!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_storeProducts.isEmpty) {
      return Padding(
        padding: AppDimens.paddingAllXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en esta tienda',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando el vendedor agregue productos, aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: AppDimens.paddingAllL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo de Productos (${_storeProducts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: _storeProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: _storeProducts[index],
                onTap: () { // ✅ AGREGAR PARÁMETRO onTap REQUERIDO
                  Navigator.pushNamed(
                    context,
                    '/product-detail',
                    arguments: {'product': _storeProducts[index]},
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStoreData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStoreData,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildStoreHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildProductsGrid(),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: widget.isCurrentUser
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-store');
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }
}