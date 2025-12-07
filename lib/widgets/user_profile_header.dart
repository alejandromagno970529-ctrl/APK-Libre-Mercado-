// lib/widgets/user_profile_header.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart'; // ✅ NUEVA IMPORTACIÓN
import '../models/user_model.dart';

class UserProfileHeader extends StatelessWidget {
  final VoidCallback? onTap;
  
  const UserProfileHeader({super.key, this.onTap, required bool showRating, required String userId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProductProvider>( // ✅ CAMBIADO A Consumer2
      builder: (context, authProvider, productProvider, child) {
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) {
          return _buildGuestHeader();
        }
        
        return _buildUserHeader(currentUser, context, productProvider); // ✅ AGREGADO productProvider
      },
    );
  }

  Widget _buildUserHeader(AppUser user, BuildContext context, ProductProvider productProvider) {
    // ✅ CALCULAR CONTADOR EN TIEMPO REAL
    final userProductsCount = _getUserProductsCount(user, productProvider); // ✅ PASAR user COMPLETO
    
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.pushNamed(context, '/profile');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[100],
              backgroundImage: user.avatarUrl != null 
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(width: 8),
            
            // Información del usuario - ✅ CONTADOR ACTUALIZADO
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  // ✅ USAR CONTADOR EN TIEMPO REAL
                  '$userProductsCount productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Badge de tienda si está habilitada
            if (user.hasStore) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO CORREGIDO: Recibir AppUser completo como parámetro
  int _getUserProductsCount(AppUser user, ProductProvider productProvider) { // ✅ CAMBIADO: Recibir AppUser
    try {
      // 1. Intentar obtener de los productos cargados del usuario
      if (productProvider.userProducts.isNotEmpty) {
        final userProducts = productProvider.userProducts
            .where((product) => product.userId == user.id) // ✅ USAR user.id
            .toList();
        if (userProducts.isNotEmpty) {
          return userProducts.length;
        }
      }
      
      // 2. Intentar obtener de todos los productos
      final allUserProducts = productProvider.products
          .where((product) => product.userId == user.id) // ✅ USAR user.id
          .toList();
      if (allUserProducts.isNotEmpty) {
        return allUserProducts.length;
      }
      
      // 3. Usar el valor del perfil como fallback
      return user.actualProductCount ?? 0; // ✅ AHORA user ESTÁ DEFINIDO
    } catch (e) {
      // 4. Fallback final
      return user.actualProductCount ?? 0; // ✅ AHORA user ESTÁ DEFINIDO
    }
  }

  Widget _buildGuestHeader() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}