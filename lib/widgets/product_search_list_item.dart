// lib/widgets/product_search_list_item.dart - VERSIÓN SIN OVERFLOW
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import '../constants/app_colors.dart';

class ProductSearchListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onContactTap;

  const ProductSearchListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 110, // Altura mínima en lugar de fija
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGEN DEL PRODUCTO
              _buildProductImage(),
              
              const SizedBox(width: 12),
              
              // INFORMACIÓN DEL PRODUCTO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TÍTULO Y PRECIO - REDUCIDO PARA EVITAR OVERFLOW
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.titulo,
                          style: const TextStyle(
                            fontSize: 15, // Reducido de 16
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.precioFormateado,
                          style: const TextStyle(
                            fontSize: 16, // Reducido de 18
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8), // Espacio adicional

                    // INFORMACIÓN ADICIONAL - COMPACTADO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // CATEGORÍA
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              product.categorias,
                              style: const TextStyle(
                                fontSize: 10, // Reducido de 11
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ESTADO
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: product.disponible ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.disponible ? 'DISP.' : 'VEND.', // Texto más corto
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9, // Reducido de 10
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // BOTÓN DE CONTACTO - MÁS COMPACTO
              if (product.disponible) ...[
                const SizedBox(width: 8),
                _buildContactButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = product.imagenUrl;
    
    return Container(
      width: 70, // Reducido de 80
      height: 70, // Reducido de 80
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.photo, color: Colors.grey, size: 24), // Reducido
                ),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.photo, color: Colors.grey, size: 24), // Reducido
            ),
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
      width: 36, // Reducido de 40
      height: 36, // Reducido de 40
      child: FloatingActionButton(
        onPressed: onContactTap,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
        mini: true,
        child: const Icon(Icons.chat, size: 16), // Reducido de 18
      ),
    );
  }
}