import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import '../constants/app_colors.dart';
import '../utils/time_utils.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onContactTap;
  final bool isLoading;
  final bool showStatusBadge;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onContactTap,
    this.isLoading = false,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    TimeUtils.debugTimestamp(product.createdAt, 'ProductCard - ${product.titulo}');
    
    return isLoading ? _buildSkeletonCard() : _buildProductCard();
  }

  Widget _buildProductCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 255,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN DEL PRODUCTO
              Stack(
                children: [
                  Container(
                    height: 118,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: _buildOptimizedProductImage(),
                  ),
                  
                  // BADGE DE ESTADO
                  if (showStatusBadge)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.disponible ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          product.disponible ? 'DISPONIBLE' : 'VENDIDO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  // BADGE DE MONEDA - SOLO MOSTRAR SI HAY PRECIO
                  if (product.precio != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          product.moneda,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // INDICADOR DE MÚLTIPLES IMÁGENES
                  if (_hasMultipleImages)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library, size: 8, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              '${_imageCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // CONTENIDO
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TÍTULO - PRIMERO
                    SizedBox(
                      height: 30,
                      child: Text(
                        product.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                    
                    // PRECIO - SEGUNDO, SOLO SI HAY PRECIO (CON SÍMBOLO $ DELANTE)
                    if (product.precio != null)
                      Text(
                        '\$${product.precio!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    
                    const SizedBox(height: 6),

                    // CATEGORÍA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(product.categorias),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: _getCategoryBorderColor(product.categorias),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        product.categorias,
                        style: TextStyle(
                          fontSize: 8,
                          color: _getCategoryTextColor(product.categorias),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // INFORMACIÓN ADICIONAL - SOLO TIEMPO RELATIVO Y UBICACIÓN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // TIEMPO RELATIVO (Hace X tiempo)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 9, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  TimeUtils.formatTimeAgo(product.createdAt),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // UBICACIÓN
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 9, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  product.city ?? 'Ubicación',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
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

                    const SizedBox(height: 8),

                    // BOTÓN CONTACTAR
                    if (onContactTap != null && product.disponible)
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: ElevatedButton(
                          onPressed: onContactTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CONTACTAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos para manejar múltiples imágenes
  bool get _hasMultipleImages {
    return _imageCount > 1;
  }

  int get _imageCount {
    return product.imagenUrls?.length ?? 0;
  }

  // MÉTODOS DE IMAGEN
  Widget _buildOptimizedProductImage() {
    final imageUrl = product.imagenUrl;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildImagePlaceholder(),
      errorWidget: (context, url, error) => _buildErrorImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 24, color: Colors.grey.shade400),
          const SizedBox(height: 2),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 7, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 24, color: Colors.grey.shade400),
          const SizedBox(height: 2),
          Text(
            'Error',
            style: TextStyle(fontSize: 7, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // COLORES POR CATEGORÍA
  Color _getCategoryColor(String category) {
    return Colors.grey.shade100;
  }

  Color _getCategoryBorderColor(String category) {
    return Colors.grey.shade400;
  }

  Color _getCategoryTextColor(String category) {
    return Colors.grey.shade800;
  }

  // SKELETON CARD
  Widget _buildSkeletonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      child: Container(
        height: 255,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 118,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 35,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}