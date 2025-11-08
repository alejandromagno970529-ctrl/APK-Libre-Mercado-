import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Product> _products = [];
  List<Product> _userProducts = []; // ✅ INICIALIZADO COMO LISTA VACÍA
  bool _isLoading = false;
  String? _error;

  ProductProvider(this._supabase);

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts; // ✅ RETORNA LISTA VACÍA, NO NULL
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📦 Cargando productos...');
      
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      _products = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos cargados: ${_products.length}');
    } catch (e) {
      _error = 'Error al cargar productos: $e';
      AppLogger.e('Error fetchProducts', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProducts(String userId) async {
    try {
      AppLogger.d('📦 Cargando productos del usuario: $userId');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _userProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos del usuario cargados: ${_userProducts.length}');
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error fetchUserProducts', e);
      // ✅ EN CASO DE ERROR, MANTENER LISTA VACÍA
      _userProducts = [];
      notifyListeners();
    }
  }

  Future<String?> createProductWithLocation({
    required String titulo,
    required String descripcion,
    required double precio,
    required String categorias,
    required String moneda,
    required String? imagenUrl,
    required Map<String, dynamic> locationData,
  }) async {
    try {
      AppLogger.d('🆕 Creando producto con ubicación...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'Usuario no autenticado';

      final productData = {
        'titulo': titulo,
        'descripcion': descripcion,
        'precio': precio,
        'categorias': categorias,
        'moneda': moneda,
        'imagen_url': imagenUrl,
        'user_id': currentUser.id,
        'created_at': DateTime.now().toIso8601String(),
        'latitud': locationData['latitude'] ?? locationData['latitud'] ?? 0.0,
        'longitud': locationData['longitude'] ?? locationData['longitud'] ?? 0.0,
        'address': locationData['address'],
        'city': locationData['city'],
        'disponible': true,
      };

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select();

      if (response.isNotEmpty) {
        AppLogger.d('🎉 Producto creado exitosamente');
        await fetchProducts();
        await fetchUserProducts(currentUser.id);
        return null;
      }

      return 'Error al crear el producto';
    } catch (e) {
      AppLogger.e('Error createProductWithLocation', e);
      return 'Error: $e';
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      return Product.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      AppLogger.e('Error getProductById', e);
      return null;
    }
  }

  Future<String?> markProductAsSold(String productId) async {
    try {
      await _supabase
          .from('products')
          .update({'disponible': false})
          .eq('id', productId);

      AppLogger.d('✅ Producto marcado como vendido: $productId');
      await fetchProducts();
      return null;
    } catch (e) {
      AppLogger.e('Error markProductAsSold', e);
      return 'Error: $e';
    }
  }

  Future<String?> updateProduct({
    required String productId,
    required String titulo,
    required String descripcion,
    required double precio,
    required String categorias,
    required String moneda,
  }) async {
    try {
      await _supabase
          .from('products')
          .update({
            'titulo': titulo,
            'descripcion': descripcion,
            'precio': precio,
            'categorias': categorias,
            'moneda': moneda,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);

      AppLogger.d('✅ Producto actualizado: $productId');
      await fetchProducts();
      return null;
    } catch (e) {
      AppLogger.e('Error updateProduct', e);
      return 'Error: $e';
    }
  }

  Future<String?> deleteProduct(String productId) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);

      AppLogger.d('🗑️ Producto eliminado: $productId');
      await fetchProducts();
      return null;
    } catch (e) {
      AppLogger.e('Error deleteProduct', e);
      return 'Error: $e';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ NUEVO MÉTODO: Búsqueda eficiente de productos
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    final searchTerms = query.toLowerCase().split(' ');
    
    return _products.where((product) {
      final title = product.titulo.toLowerCase();
      final description = product.descripcion?.toLowerCase() ?? '';
      final category = product.categorias.toLowerCase();
      
      // Búsqueda por múltiples términos
      for (final term in searchTerms) {
        if (title.contains(term) || 
            description.contains(term) || 
            category.contains(term)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  // ✅ NUEVO MÉTODO: Filtrar por categoría
  List<Product> filterByCategory(String category) {
    if (category == 'Todos') return _products;
    return _products.where((product) => product.categorias == category).toList();
  }
}