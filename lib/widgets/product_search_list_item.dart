import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libre_mercado_final_app/models/product_model.dart';
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
            minHeight: 110,
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGEN DEL PRODUCTO
              _buildProductImage(),
              
              const SizedBox(width: 10),
              
              // INFORMACIÓN DEL PRODUCTO - CON FLEXIBLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TÍTULO Y PRECIO - CON CONSTRAINTS MEJORADAS
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 32,
                            maxWidth: MediaQuery.of(context).size.width - 160,
                          ),
                          child: Text(
                            product.titulo,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (product.precio != null)
                          Text(
                            '${product.precio!.toStringAsFixed(0)} ${product.moneda}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // INFORMACIÓN ADICIONAL - CON FLEXIBLE EN CATEGORÍA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // CATEGORÍA - FLEXIBLE
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              product.categorias,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // ESTADO - FIXED WIDTH
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.disponible ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            product.disponible ? 'DISP.' : 'VEND.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // BOTÓN DE CONTACTO - SOLO SI HAY ESPACIO
              if (product.disponible) ...[
                const SizedBox(width: 6),
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
      width: 75,
      height: 75,
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
                  child: const Icon(Icons.photo, color: Colors.grey, size: 24),
                ),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.photo, color: Colors.grey, size: 24),
            ),
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
      width: 32,
      height: 32,
      child: FloatingActionButton(
        onPressed: onContactTap,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
        mini: true,
        child: const Icon(Icons.chat, size: 14),
      ),
    );
  }
}