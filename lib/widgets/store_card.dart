// lib/widgets/store_card.dart - NUEVO WIDGET ESPECIALIZADO
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class StoreCard extends StatelessWidget {
  final AppUser store;
  final VoidCallback onTap;
  final bool isGrid;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGridCard() : _buildListCard();
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
            // Banner/Logo de la tienda
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
                    image: store.storeBannerUrl != null
                        ? DecorationImage(
                            image: NetworkImage(store.storeBannerUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: store.storeBannerUrl == null
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
                      image: store.storeLogoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(store.storeLogoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: store.storeLogoUrl == null
                        ? Icon(
                            Icons.store,
                            size: 20,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),

                // Badge de productos
                if ((store.actualProductCount ?? 0) > 0)
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
                        '${store.actualProductCount ?? 0}',
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
                          store.storeDisplayName,
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
                        if (store.storeCategory != null)
                          Text(
                            store.storeCategory!,
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
                              store.storeRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.shopping_bag, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${store.actualProductCount ?? 0}',
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
                              if (store.isVerified == true) ...[
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

  Widget _buildListCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
                image: store.storeLogoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(store.storeLogoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: store.storeLogoUrl == null
                  ? Icon(
                      Icons.store,
                      size: 30,
                      color: Colors.grey[400],
                    )
                  : null,
            ),
            if ((store.actualProductCount ?? 0) > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${store.actualProductCount ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          store.storeDisplayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.storeCategory != null)
              Text(
                store.storeCategory!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  store.storeRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${store.actualProductCount ?? 0} productos',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: store.isProfessionalStore ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: store.isProfessionalStore ? Colors.green : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store.isProfessionalStore ? 'Profesional' : 'Tienda',
                style: TextStyle(
                  fontSize: 10,
                  color: store.isProfessionalStore ? Colors.green[800] : Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (store.isVerified == true) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified, size: 12, color: Colors.blue),
              ]
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}