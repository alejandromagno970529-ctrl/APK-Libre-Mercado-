import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/product_provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/models/product_model.dart';
import 'package:libre_mercado_final_app/widgets/product_card.dart';
import 'package:libre_mercado_final_app/screens/product/product_detail_screen.dart';
import 'package:libre_mercado_final_app/screens/product/edit_product_screen.dart';
import 'package:libre_mercado_final_app/screens/product/add_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      await productProvider.fetchUserProducts(currentUser.id);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final result = await productProvider.deleteProduct(productId);
    
    if (result != null) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _markAsSold(String productId) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final result = await productProvider.markProductAsSold(productId);
    
    if (result != null) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto marcado como vendido'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Ver Detalles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            },
          ),
          if (product.disponible) ...[
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Producto'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: product),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell, color: Colors.green),
              title: const Text('Marcar como Vendido'),
              onTap: () {
                Navigator.pop(context);
                _markAsSold(product.id);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar Producto'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(product);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ProductProvider>(
        builder: (context, authProvider, productProvider, child) {
          final currentUser = authProvider.currentUser;
          final userProducts = productProvider.userProducts;

          if (currentUser == null) {
            return const Center(
              child: Text('Debes iniciar sesión para ver tus productos'),
            );
          }

          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (userProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes productos publicados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comienza publicando tu primer producto',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('PUBLICAR PRIMER PRODUCTO'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadUserProducts,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemCount: userProducts.length,
              itemBuilder: (context, index) {
                final product = userProducts[index];
                return GestureDetector(
                  onLongPress: () => _showActionSheet(product),
                  child: ProductCard(
                    product: product,
                    onTap: () => _showActionSheet(product),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}