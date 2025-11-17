// lib/widgets/store_card.dart - VERSIÓN OPTIMIZADA SIN OVERFLOW
import 'package:flutter/material.dart';
import '../models/store_model.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onTap;
  final bool isGrid;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridCard() : _buildCompactHorizontalCard();
  }

  // Simple grid-style card used when `isGrid` is true
  Widget _buildGridCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/banner
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[100],
                image: store.hasCoverImage
                    ? DecorationImage(image: NetworkImage(store.coverImageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: !store.hasCoverImage
                  ? Center(
                      child: Icon(Icons.storefront, size: 36, color: Colors.grey[400]),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                store.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ TARJETA HORIZONTAL COMPACTA - SIN OVERFLOW
  Widget _buildCompactHorizontalCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 200, // ✅ LIMITE MÁXIMO DE ALTURA
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ LOGO DE LA TIENDA (LADO IZQUIERDO)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                  image: store.hasLogoImage
                      ? DecorationImage(
                          image: NetworkImage(store.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !store.hasLogoImage
                    ? Icon(
                        Icons.store,
                        size: 30,
                        color: Colors.grey[400],
                      )
                    : null,
              ),

              // ✅ CONTENIDO PRINCIPAL (LADO DERECHO)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ✅ NOMBRE Y CATEGORÍA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // ✅ ESTADÍSTICAS COMPACTAS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // RATING
                            _buildCompactStat(
                              icon: Icons.star,
                              value: store.rating.toStringAsFixed(1),
                              color: Colors.amber,
                            ),
                            
                            // PRODUCTOS
                            _buildCompactStat(
                              icon: Icons.shopping_bag,
                              value: '${store.productCount}',
                              color: Colors.green,
                            ),
                            
                            // VENTAS
                            _buildCompactStat(
                              icon: Icons.attach_money,
                              value: '${store.totalSales}',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),

                      // ✅ BADGES EN UNA LÍNEA
                      Row(
                        children: [
                          // BADGE TIPO TIENDA
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: store.isProfessionalStore ? Colors.green[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: store.isProfessionalStore ? Colors.green : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 12,
                                  color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  store.isProfessionalStore ? 'Profesional' : 'Básica',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // BADGE VERIFICACIÓN
                          if (store.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verificada',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  // ✅ WIDGET PARA ESTADÍSTICAS COMPACTAS
  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}