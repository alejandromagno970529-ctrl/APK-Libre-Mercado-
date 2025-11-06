// REEMPLAZAR el archivo lib/widgets/product_card.dart completo:
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onContactTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 180, // ✅ REDUCIDO de 200
            maxHeight: 200, // ✅ REDUCIDO de 230
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      height: 90, // ✅ REDUCIDO de 100
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: _buildProductImage(),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.disponible ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.disponible ? 'Disponible' : 'Vendido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Información del producto - CONTENIDO MÁS COMPACTO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8), // ✅ REDUCIDO de 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Precio y título - MÁS COMPACTO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.precio.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2), // ✅ REDUCIDO de 3
                          Text(
                            product.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      // Categoría y ubicación - MÁS COMPACTO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // ✅ REDUCIDO
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.categorias,
                              style: const TextStyle(
                                fontSize: 8, // ✅ MANTENIDO
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2), // ✅ REDUCIDO de 4
                          
                          // FECHA Y UBICACIÓN EN UNA SOLA LÍNEA
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 8, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  _formatDate(product.createdAt),
                                  style: TextStyle(
                                    fontSize: 7, // ✅ REDUCIDO de 8
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.location_on, size: 8, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  product.city ?? 'Ubicación',
                                  style: TextStyle(
                                    fontSize: 7, // ✅ REDUCIDO de 8
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Botón Contactar - MÁS COMPACTO
                      if (onContactTap != null && product.disponible)
                        SizedBox(
                          width: double.infinity,
                          height: 20, // ✅ REDUCIDO de 24
                          child: OutlinedButton(
                            onPressed: onContactTap,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4), // ✅ REDUCIDO de 6
                              ),
                            ),
                            child: const Text(
                              'Contactar',
                              style: TextStyle(
                                fontSize: 8, // ✅ REDUCIDO de 9
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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

  Widget _buildProductImage() {
    final imageUrl = product.imagenUrl;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 24, color: Colors.grey.shade400), // ✅ REDUCIDO
          const SizedBox(height: 2),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade400), // ✅ REDUCIDO
          ),
        ],
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
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
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 24, color: Colors.grey.shade400), // ✅ REDUCIDO
            const SizedBox(height: 2),
            Text(
              'Error',
              style: TextStyle(fontSize: 8, color: Colors.grey.shade400), // ✅ REDUCIDO
            ),
          ],
        );
      },
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