import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showStatus;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _buildProductImage(),
                  ),
                ),
                
                // INDICADOR DE DISPONIBILIDAD
                if (showStatus)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.disponible 
                            ? const Color.fromRGBO(76, 175, 80, 230)
                            : const Color.fromRGBO(244, 67, 54, 230),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.disponible ? 'Disponible' : 'Vendido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                      color: const Color.fromRGBO(0, 0, 0, 178),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.moneda,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // INFORMACIÓN DEL PRODUCTO
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRECIO
                  Text(
                    '\$${product.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // TÍTULO
                  Text(
                    product.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // DESCRIPCIÓN (recortada) - ✅ CORREGIDO: Null safety completo
                  if (_hasDescription)
                    Text(
                      product.descripcion!, // Safe porque _hasDescription verifica
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  
                  if (_hasDescription) const SizedBox(height: 4),

                  // CATEGORÍA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 193, 7, 25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color.fromRGBO(255, 193, 7, 76),
                      ),
                    ),
                    child: Text(
                      product.categorias,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // UBICACIÓN Y FECHA
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // ✅ CORREGIDO: Null safety completo para city
                          _cityDisplayText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(product.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ GETTERS PARA NULL SAFETY
  bool get _hasDescription => product.descripcion != null && product.descripcion!.isNotEmpty;
  
  String get _cityDisplayText {
    if (product.city == null || product.city!.isEmpty) {
      return 'Ubicación no disponible';
    }
    return product.city!;
  }

  Widget _buildProductImage() {
    if (product.imagenUrl == null || product.imagenUrl!.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo, size: 40, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Sin imagen',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      );
    }

    return Image.network(
      product.imagenUrl!,
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
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Error carga',
              style: TextStyle(fontSize: 10, color: Colors.grey),
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
      return 'Hace ${months} mes${months > 1 ? 'es' : ''}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }
}

// ✅ WIDGET ADICIONAL: ProductCardHorizontal
class ProductCardHorizontal extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardHorizontal({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // IMAGEN
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: product.imagenUrl != null
                    ? Image.network(
                        product.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.photo, color: Colors.grey);
                        },
                      )
                    : const Icon(Icons.photo, color: Colors.grey),
              ),
            ),
            
            // INFORMACIÓN
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRECIO
                    Text(
                      '\$${product.precio.toStringAsFixed(2)} ${product.moneda}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // TÍTULO
                    Text(
                      product.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // CATEGORÍA
                    Text(
                      product.categorias,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // UBICACIÓN
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            // ✅ CORREGIDO: Null safety completo
                            _getCityText(product.city),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO HELPER PARA NULL SAFETY
  String _getCityText(String? city) {
    if (city == null || city.isEmpty) {
      return 'Ubicación no disponible';
    }
    return city;
  }
}

// ✅ WIDGET ADICIONAL: ProductCardSmall
class ProductCardSmall extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardSmall({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                height: 80,
                width: double.infinity,
                color: Colors.grey[200],
                child: product.imagenUrl != null
                    ? Image.network(
                        product.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.photo, size: 30, color: Colors.grey);
                        },
                      )
                    : const Icon(Icons.photo, size: 30, color: Colors.grey),
              ),
            ),
            
            // INFORMACIÓN COMPACTA
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRECIO
                  Text(
                    '\$${product.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // TÍTULO (1 línea)
                  Text(
                    product.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
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