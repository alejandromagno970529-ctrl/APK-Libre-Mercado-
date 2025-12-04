// lib/widgets/store_card.dart - VERSIÓN COMPLETA CON DIAGNÓSTICO
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

  // Tarjeta en grid (para cuando isGrid es true)
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
            // Imagen/banner
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

  // ✅ TARJETA HORIZONTAL EXACTAMENTE IGUAL A _buildStorePreview EN PROFILE_SCREEN
  Widget _buildHorizontalCard() {
    // ✅ DIAGNÓSTICO EN TIEMPO REAL CON DATOS ACTUALES
    // ignore: avoid_print
    print('''
🎨 RENDERIZANDO STORECARD CON DATOS REALES:
   - Nombre: ${store.name}
   - Productos REALES: ${store.productCount}
   - Ventas REALES: ${store.totalSales}
   - Rating: ${store.rating}
   - Tiene banner: ${store.hasCoverImage}
   - Tiene logo: ${store.hasLogoImage}
   - Descripción: ${store.description}
''');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ BANNER SUPERIOR (EXACTO AL PROFILE_SCREEN)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.borderRadiusM),
                  topRight: Radius.circular(AppDimens.borderRadiusM),
                ),
                image: store.hasCoverImage
                    ? DecorationImage(
                        image: NetworkImage(store.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[100],
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
            
            // ✅ CONTENIDO PRINCIPAL (EXACTO AL PROFILE_SCREEN)
            Padding(
              padding: AppDimens.paddingAllM,
              child: Row(
                children: [
                  // ✅ LOGO DE LA TIENDA (50x50 EXACTO)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadiusM),
                      border: Border.all(color: Colors.grey[300]!),
                      image: store.hasLogoImage
                          ? DecorationImage(
                              image: NetworkImage(store.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.white,
                    ),
                    child: !store.hasLogoImage
                        ? Icon(
                            Icons.store,
                            size: 24,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // ✅ INFORMACIÓN DE LA TIENDA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOMBRE DE LA TIENDA (EXACTO)
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // ✅ DESCRIPCIÓN (NUEVO - como en la imagen)
                        Text(
                          store.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // ✅ ESTADÍSTICAS (EXACTO AL PROFILE_SCREEN)
                        Text(
                          '${store.productCount} productos • ${store.totalSales} ventas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // ✅ RATING (EXACTO AL PROFILE_SCREEN)
                        Row(
                          children: [
                            Icon(
                              Icons.star, 
                              size: 14, 
                              color: Colors.amber[700]
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // ✅ FLECHA DE NAVEGACIÓN (EXACTA AL PROFILE_SCREEN)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
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