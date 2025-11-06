import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/services/location_service.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

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

  @override
  void initState() {
    super.initState();
    _calculateDistance();
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

  // ✅ MÉTODO _showContactOptions AGREGADO
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildContactBottomSheet(),
    );
  }

  Widget _buildContactBottomSheet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.currentUser?.id == widget.product.userId;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOwner ? 'Opciones del producto' : 'Contactar al vendedor',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (!isOwner) ...[
            _buildContactOption(
              icon: Icons.chat,
              title: 'Enviar mensaje',
              subtitle: 'Chatear con el vendedor',
              onTap: _startChat,
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.phone,
              title: 'Llamar',
              subtitle: 'Contactar por teléfono',
              onTap: () => _showPhoneNotAvailable(),
            ),
            const SizedBox(height: 12),
          ],
          
          if (isOwner) ...[
            _buildContactOption(
              icon: Icons.edit,
              title: 'Editar producto',
              subtitle: 'Modificar información',
              onTap: _editProduct,
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: widget.product.disponible ? Icons.sell : Icons.inventory,
              title: widget.product.disponible ? 'Marcar como vendido' : 'Marcar como disponible',
              subtitle: widget.product.disponible ? 'Producto vendido' : 'Volver a publicar',
              onTap: _toggleProductStatus,
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.delete,
              title: 'Eliminar producto',
              subtitle: 'Eliminar permanentemente',
              onTap: _deleteProduct,
              isDestructive: true,
            ),
          ],
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

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
        color: isDestructive ? Colors.red : Colors.amber,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _startChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para chatear')),
      );
      return;
    }

    if (authProvider.currentUser!.id == widget.product.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes chatear contigo mismo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Por implementar: lógica para crear/iniciar chat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidad de chat en desarrollo')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar chat: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPhoneNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de llamadas en desarrollo')),
    );
  }

  Future<void> _editProduct() async {
    // Navegar a pantalla de edición (por implementar)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de edición en desarrollo')),
    );
  }

  Future<void> _toggleProductStatus() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.product.disponible) {
        await productProvider.markProductAsSold(widget.product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto marcado como vendido')),
        );
      } else {
        // Por implementar: función para reactivar producto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidad en desarrollo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  Future<void> _deleteProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await productProvider.deleteProduct(widget.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error eliminando producto: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = widget.product.imagenUrl;
    
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Error al cargar imagen'),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Sin imagen'),
                ],
              ),
            ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRECIO Y MONEDA
          Row(
            children: [
              Text(
                '\$${widget.product.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.product.moneda,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.product.disponible ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.product.disponible ? 'DISPONIBLE' : 'VENDIDO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TÍTULO
          Text(
            widget.product.titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // CATEGORÍA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 193, 7, 25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromRGBO(255, 193, 7, 76),
              ),
            ),
            child: Text(
              widget.product.categorias,
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DESCRIPCIÓN - COMPLETAMENTE SEGURO
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.descripcion ?? 'Este producto no tiene descripción',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // UBICACIÓN - COMPLETAMENTE SEGURO
          const Text(
            'Ubicación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFFA000)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSafeAddress(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_distanceInKm != null)
                      Text(
                        'A ${_distanceInKm!.toStringAsFixed(1)} km de tu ubicación',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // INFORMACIÓN DE PUBLICACIÓN
          const Text(
            'Información de la publicación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Publicado ${_formatDate(widget.product.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO SEGURO PARA DIRECCIÓN
  String _getSafeAddress() {
    final address = widget.product.address;
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
    final isOwner = authProvider.currentUser?.id == widget.product.userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSection(),
            ),
            pinned: true,
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildProductInfo(),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _showContactOptions, // ✅ AHORA ESTÁ DEFINIDO
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          icon: Icon(isOwner ? Icons.more_vert : Icons.chat),
          label: Text(isOwner ? 'Opciones' : 'Contactar'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}