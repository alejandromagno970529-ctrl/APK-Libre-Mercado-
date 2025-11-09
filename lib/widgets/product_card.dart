// lib/widgets/product_card.dart - VERSIÓN COMPLETA
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';

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
    return isLoading ? _buildSkeletonCard() : _buildProductCard();
  }

  Widget _buildProductCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN DEL PRODUCTO
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: _buildOptimizedProductImage(),
                    ),
                  ),
                  
                  // BADGE DE ESTADO (Disponible/Vendido)
                  if (showStatusBadge)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.disponible ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          product.disponible ? 'DISPONIBLE' : 'VENDIDO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // BADGE DE MONEDA
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.moneda,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // CONTENIDO DE LA TARJETA
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PRECIO
                    Text(
                      '${_getCurrencySymbol(product.moneda)}${product.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // TÍTULO
                    Text(
                      product.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // CATEGORÍA CON COLOR
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(product.categorias),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getCategoryBorderColor(product.categorias),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.categorias.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: _getCategoryTextColor(product.categorias),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // INFORMACIÓN ADICIONAL
                    Row(
                      children: [
                        // FECHA
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(product.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // UBICACIÓN
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                product.city ?? 'Ubicación',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
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

                    const SizedBox(height: 10),

                    // BOTÓN CONTACTAR (solo si está disponible)
                    if (onContactTap != null && product.disponible)
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: onContactTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'CONTACTAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 10, color: Colors.grey),
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
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Error',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SKELETON IMAGE
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            
            // SKELETON CONTENT
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
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

  // MÉTODOS AUXILIARES

  String _getCurrencySymbol(String moneda) {
    return moneda == 'USD' ? '\$' : 'CUP ';
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

  // COLORES POR CATEGORÍA
  Color _getCategoryColor(String category) {
    final colors = {
      'Tecnología': Colors.blue.shade50,
      'Electrodomésticos': Colors.orange.shade50,
      'Ropa y Accesorios': Colors.pink.shade50,
      'Hogar y Jardín': Colors.green.shade50,
      'Deportes': Colors.red.shade50,
      'Videojuegos': Colors.purple.shade50,
      'Libros': Colors.brown.shade50,
      'Música y Películas': Colors.indigo.shade50,
      'Salud y Belleza': Colors.teal.shade50,
      'Juguetes': Colors.cyan.shade50,
      'Herramientas': Colors.deepOrange.shade50,
      'Automóviles': Colors.blueGrey.shade50,
      'Motos': Colors.grey.shade50,
      'Bicicletas': Colors.lightGreen.shade50,
      'Mascotas': Colors.amber.shade50,
      'Arte y Coleccionables': Colors.deepPurple.shade50,
      'Inmuebles': Colors.lightBlue.shade50,
      'Empleos': Colors.lime.shade50,
      'Servicios': Colors.yellow.shade50,
    };
    return colors[category] ?? Colors.grey.shade100;
  }

  Color _getCategoryBorderColor(String category) {
    final colors = {
      'Tecnología': Colors.blue.shade200,
      'Electrodomésticos': Colors.orange.shade200,
      'Ropa y Accesorios': Colors.pink.shade200,
      'Hogar y Jardín': Colors.green.shade200,
      'Deportes': Colors.red.shade200,
      'Videojuegos': Colors.purple.shade200,
      'Libros': Colors.brown.shade200,
      'Música y Películas': Colors.indigo.shade200,
      'Salud y Belleza': Colors.teal.shade200,
      'Juguetes': Colors.cyan.shade200,
      'Herramientas': Colors.deepOrange.shade200,
      'Automóviles': Colors.blueGrey.shade200,
      'Motos': Colors.grey.shade200,
      'Bicicletas': Colors.lightGreen.shade200,
      'Mascotas': Colors.amber.shade200,
      'Arte y Coleccionables': Colors.deepPurple.shade200,
      'Inmuebles': Colors.lightBlue.shade200,
      'Empleos': Colors.lime.shade200,
      'Servicios': Colors.yellow.shade200,
    };
    return colors[category] ?? Colors.grey.shade300;
  }

  Color _getCategoryTextColor(String category) {
    final colors = {
      'Tecnología': Colors.blue.shade800,
      'Electrodomésticos': Colors.orange.shade800,
      'Ropa y Accesorios': Colors.pink.shade800,
      'Hogar y Jardín': Colors.green.shade800,
      'Deportes': Colors.red.shade800,
      'Videojuegos': Colors.purple.shade800,
      'Libros': Colors.brown.shade800,
      'Música y Películas': Colors.indigo.shade800,
      'Salud y Belleza': Colors.teal.shade800,
      'Juguetes': Colors.cyan.shade800,
      'Herramientas': Colors.deepOrange.shade800,
      'Automóviles': Colors.blueGrey.shade800,
      'Motos': Colors.grey.shade800,
      'Bicicletas': Colors.lightGreen.shade800,
      'Mascotas': Colors.amber.shade800,
      'Arte y Coleccionables': Colors.deepPurple.shade800,
      'Inmuebles': Colors.lightBlue.shade800,
      'Empleos': Colors.lime.shade800,
      'Servicios': Colors.yellow.shade800,
    };
    return colors[category] ?? Colors.grey.shade800;
  }
}