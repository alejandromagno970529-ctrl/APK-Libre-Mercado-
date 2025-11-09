// ACTUALIZAR SOLO EL MÉTODO _buildOwnerPopupMenu Y LA SliverAppBar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/services/location_service.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';
import 'package:libre_mercado_final__app/constants/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = false;
  double? _distanceInKm;
  Product? _currentProduct;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _calculateDistance();
    _loadUpdatedProduct();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUpdatedProduct() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final updatedProduct = await productProvider.getProductById(widget.product.id);
      if (updatedProduct != null && mounted) {
        setState(() {
          _currentProduct = updatedProduct;
        });
      }
    } catch (e) {
      AppLogger.w('Error cargando producto actualizado: $e');
    }
  }

  Future<void> _calculateDistance() async {
    try {
      final currentLocation = await LocationService.getCoordinatesOnly();
      if (currentLocation['success'] == true) {
        final distance = LocationService.calculateDistance(
          currentLocation['latitude'] ?? 0.0,
          currentLocation['longitude'] ?? 0.0,
          widget.product.latitud,
          widget.product.longitud,
        );
        
        setState(() {
          _distanceInKm = distance / 1000;
        });
      }
    } catch (e) {
      AppLogger.w('Error calculando distancia: $e');
    }
  }

  // ✅ VISOR DE IMAGEN COMPLETO
  void _openFullScreenImage() {
    final imageUrl = _currentProduct!.imagenUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imagen disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _currentProduct!.titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ SECCIÓN DE IMAGEN EXPANDIDA
  Widget _buildImageSection() {
    final imageUrl = _currentProduct!.imagenUrl;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    return GestureDetector(
      onTap: _openFullScreenImage,
      child: Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
        ),
        child: Hero(
          tag: imageUrl,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImageLoader();
            },
          ),
        ),
      ),
    );
  }

  // ✅ BOTÓN FLOTANTE PARA USUARIOS NO PROPIETARIOS
  Widget _buildBuyerFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showBuyerOptions,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.chat),
      label: const Text('Contactar'),
    );
  }

  // ✅ INDICADOR DE TAP EN LA IMAGEN
  Widget _buildImageWithTapIndicator() {
    final hasImage = _currentProduct!.imagenUrl != null && 
                    _currentProduct!.imagenUrl!.isNotEmpty;

    return Stack(
      children: [
        _buildImageSection(),
        if (hasImage)
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _openFullScreenImage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Toca para ver completa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ✅ BOTÓN DE 3 PUNTOS MEJORADO - SOLO VISUAL
  Widget _buildOwnerPopupMenu() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: Colors.black,
          size: 28, // Tamaño aumentado para mejor visibilidad
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _editProduct();
              break;
            case 'toggle_status':
              _toggleProductStatus();
              break;
            case 'delete':
              _deleteProduct();
              break;
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20, color: Colors.black),
                const SizedBox(width: 8),
                const Text('Editar producto'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'toggle_status',
            child: Row(
              children: [
                Icon(
                  _currentProduct!.disponible ? Icons.sell : Icons.inventory_2,
                  size: 20,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Text(_currentProduct!.disponible ? 'Marcar como vendido' : 'Reactivar producto'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Eliminar producto',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ OPCIONES PARA EL COMPRADOR (BOTÓN FLOTANTE)
  void _showBuyerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildBuyerOptionsBottomSheet(),
    );
  }

  Widget _buildBuyerOptionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Contactar al vendedor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactOption(
            icon: Icons.chat,
            title: 'Enviar mensaje',
            subtitle: 'Chatear con el vendedor',
            onTap: _startChat,
          ),
          const SizedBox(height: 12),
          
          _buildContactOption(
            icon: Icons.person,
            title: 'Ver perfil',
            subtitle: 'Ver perfil del vendedor',
            onTap: _viewSellerProfile,
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET REUTILIZABLE PARA OPCIONES
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin imagen disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoader() {
    return Container(
      height: 400,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando imagen...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 400,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar la imagen',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODOS DE ACCIÓN
  void _viewSellerProfile() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de perfil en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _startChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para chatear'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (authProvider.currentUser!.id == _currentProduct!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes chatear contigo mismo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad de chat en desarrollo'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  Future<void> _editProduct() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de edición en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _toggleProductStatus() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentProduct!.disponible) {
        await productProvider.markProductAsSold(_currentProduct!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto marcado como vendido'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await productProvider.reactivateProduct(_currentProduct!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto reactivado'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadUpdatedProduct();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Eliminar Producto',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${_currentProduct!.titulo}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await productProvider.deleteProduct(_currentProduct!.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Producto eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error eliminando producto: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ✅ SECCIÓN DE INFORMACIÓN DEL PRODUCTO
  Widget _buildProductInfo() {
    if (_currentProduct == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRECIO Y ESTADO
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${_currentProduct!.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentProduct!.moneda,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _currentProduct!.disponible ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentProduct!.disponible ? 'DISPONIBLE' : 'VENDIDO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TÍTULO
            Text(
              _currentProduct!.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // CATEGORÍA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _currentProduct!.categorias,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // DESCRIPCIÓN
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentProduct!.descripcion ?? 'Este producto no tiene descripción',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // UBICACIÓN
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSafeAddress(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_distanceInKm != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'A ${_distanceInKm!.toStringAsFixed(1)} km de tu ubicación',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INFORMACIÓN DE PUBLICACIÓN
            const Text(
              'Información de la publicación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'Publicado ${_formatDate(_currentProduct!.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getSafeAddress() {
    final address = _currentProduct!.address;
    if (address == null || address.isEmpty) {
      return 'Ubicación no disponible';
    }
    return address;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'hace ${months} mes${months > 1 ? 'es' : ''}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'hace unos minutos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.currentUser?.id == _currentProduct?.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageWithTapIndicator(),
            ),
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
              // ✅ BOTÓN DE 3 PUNTOS MEJORADO - SOLO PARA PROPIETARIOS
              if (isOwner) _buildOwnerPopupMenu(),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildProductInfo(),
          ),
        ],
      ),
      // ✅ BOTÓN FLOTANTE SOLO PARA USUARIOS NO PROPIETARIOS
      floatingActionButton: !isOwner ? _buildBuyerFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}