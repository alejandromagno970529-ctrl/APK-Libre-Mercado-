import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onContactTap;
  final bool isLoading;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onContactTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading ? _buildSkeletonCard() : _buildProductCard();
  }

  Widget _buildProductCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // ✅ SIN ALTURA FIJA - SE ADAPTA COMPLETAMENTE
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN CON ALTURA FIJA PERO MÁS PEQUEÑA
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Container(
                      height: 120, // ✅ ALTURA MÁS PEQUEÑA
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: _buildOptimizedProductImage(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: product.disponible ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        product.disponible ? 'Disponible' : 'Vendido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8, // ✅ TEXTO MÁS PEQUEÑO
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // CONTENIDO CON PADDING MÍNIMO
              Padding(
                padding: const EdgeInsets.all(6), // ✅ PADDING MÍNIMO
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PRECIO
                    Text(
                      '\$${product.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12, // ✅ TEXTO MÁS PEQUEÑO
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // TÍTULO
                    Text(
                      product.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10, // ✅ TEXTO MÁS PEQUEÑO
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // CATEGORÍA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        product.categorias,
                        style: const TextStyle(
                          fontSize: 8, // ✅ TEXTO MÁS PEQUEÑO
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // FECHA Y UBICACIÓN EN UNA SOLA LÍNEA
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 8, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          _formatDate(product.createdAt),
                          style: TextStyle(
                            fontSize: 7, // ✅ TEXTO MÁS PEQUEÑO
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on, size: 8, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.city ?? 'Ubicación',
                            style: TextStyle(
                              fontSize: 7, // ✅ TEXTO MÁS PEQUEÑO
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // BOTÓN CONTACTAR
                    if (onContactTap != null && product.disponible)
                      SizedBox(
                        width: double.infinity,
                        height: 20, // ✅ BOTÓN MÁS PEQUEÑO
                        child: OutlinedButton(
                          onPressed: onContactTap,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: Colors.black, width: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Contactar',
                            style: TextStyle(
                              fontSize: 9, // ✅ TEXTO MÁS PEQUEÑO
                              fontWeight: FontWeight.w500,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo, size: 24, color: Colors.grey.shade400),
        const SizedBox(height: 2),
        Text(
          'Sin imagen',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 24, color: Colors.grey.shade400),
        const SizedBox(height: 2),
        Text(
          'Error',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 25,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 35,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 20,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return 'Ahora';
    }
  }
}