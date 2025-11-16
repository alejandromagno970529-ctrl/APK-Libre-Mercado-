// lib/widgets/store_card.dart - VERSIÓN ACTUALIZADA PARA STOREMODEL
import 'package:flutter/material.dart';
import '../models/store_model.dart';
import '../constants/app_dimens.dart';

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
    return isGrid ? _buildGridCard() : _buildHorizontalCard();
  }

  Widget _buildGridCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de tienda
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[100],
                    image: store.hasCoverImage
                        ? DecorationImage(
                            image: NetworkImage(store.coverImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !store.hasCoverImage
                      ? Center(
                          child: Icon(
                            Icons.storefront,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                
                // Logo overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white,
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
                            size: 20,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),

                // Badge de productos
                if (store.productCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${store.productCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Badge de verificación
                if (store.isVerified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Información de la tienda
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la tienda
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Categoría
                        Text(
                          store.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Estadísticas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating y productos
                        Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.shopping_bag, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${store.productCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Tipo de tienda
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: store.isProfessionalStore ? Colors.green[50] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: store.isProfessionalStore ? Colors.green : Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                store.isProfessionalStore ? '🏪 Profesional' : '🏪 Básica',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (store.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.verified, size: 10, color: Colors.blue),
                              ]
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
    );
  }

  // Tarjeta horizontal con diseño similar al perfil
  Widget _buildHorizontalCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.borderRadiusL),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.borderRadiusL),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Banner de tienda (similar al perfil)
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.borderRadiusL),
                        topRight: Radius.circular(AppDimens.borderRadiusL),
                      ),
                      color: Colors.grey[100],
                      image: store.hasCoverImage
                          ? DecorationImage(
                              image: NetworkImage(store.coverImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !store.hasCoverImage
                        ? Center(
                            child: Icon(
                              Icons.storefront,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          )
                        : null,
                  ),
                  
                  // Logo posicionado similar al perfil
                  Positioned(
                    bottom: -20,
                    left: 16,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadiusL),
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                              size: 40,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),

                  // Badge de productos
                  if (store.productCount > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${store.productCount} productos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Badge de verificación
                  if (store.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Verificada',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // Información de la tienda (similar al perfil)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Estadísticas
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${store.productCount} productos',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.attach_money, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${store.totalSales} ventas',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Descripción
                    if (store.description.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                        ),
                        child: Text(
                          store.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Badge de tipo de tienda
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: store.isProfessionalStore ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
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
                            size: 16,
                            color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            store.isProfessionalStore ? 'Tienda Profesional' : 'Tienda Básica',
                            style: TextStyle(
                              fontSize: 14,
                              color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (store.isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Verificada',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]
                        ],
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
}