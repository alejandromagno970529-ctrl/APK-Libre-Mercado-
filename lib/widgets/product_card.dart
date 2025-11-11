// lib/widgets/product_card.dart - VERSIÓN FINAL CORREGIDA
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import '../constants/app_colors.dart';

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
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 255, // REDUCIDO PARA ELIMINAR OVERFLOW
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEN DEL PRODUCTO
              Stack(
                children: [
                  Container(
                    height: 118, // REDUCIDO PARA COMPENSAR
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

                  // BADGE DE MONEDA
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
                ],
              ),
              
              // CONTENIDO - OPTIMIZADO
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PRECIO
                    Text(
                      '${_getCurrencySymbol(product.moneda)}${product.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // TÍTULO - MÁS COMPACTO PERO TEXTO COMPLETO
                    SizedBox(
                      height: 30, // ALTURA FIJA PARA TÍTULO
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

                    const SizedBox(height: 6),

                    // CATEGORÍA - TEXTO COMPLETO
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
                        product.categorias, // TEXTO COMPLETO
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

                    // INFORMACIÓN ADICIONAL - COMPACTA PERO TEXTO COMPLETO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // FECHA
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 9, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _formatDate(product.createdAt),
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
                        
                        // UBICACIÓN - TEXTO COMPLETO
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 9, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  product.city ?? 'Ubicación', // TEXTO COMPLETO
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

  // MÉTODOS AUXILIARES - SIN ABREVIATURAS
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

  // MÉTODOS DE IMAGEN (sin cambios)
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
          Icon(Icons.photo, size: 24, color: Colors.grey),
          SizedBox(height: 2),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 7, color: Colors.grey),
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
          Icon(Icons.broken_image, size: 24, color: Colors.grey),
          SizedBox(height: 2),
          Text(
            'Error',
            style: TextStyle(fontSize: 7, color: Colors.grey),
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
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 2),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(height: 8),
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
                      Spacer(),
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
                  SizedBox(height: 8),
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