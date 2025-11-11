// lib/providers/product_provider.dart - VERSIÓN CORREGIDA Y FUNCIONAL
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Product> _products = [];
  List<Product> _userProducts = [];
  bool _isLoading = false;
  String? _error;
  
  // ✅ PAGINACIÓN
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  ProductProvider(this._supabase);

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (!loadMore) {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    } else {
      if (!_hasMore || _isLoading) return;
      _currentPage++;
    }
    
    notifyListeners();

    try {
      AppLogger.d('📦 Cargando productos... Página: $_currentPage');
      
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final newProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      if (loadMore) {
        _products.addAll(newProducts);
      } else {
        _products = newProducts;
      }

      // ✅ VERIFICAR SI HAY MÁS PRODUCTOS
      _hasMore = newProducts.length == _pageSize;

      AppLogger.d('✅ Productos cargados: ${_products.length}. ¿Hay más?: $_hasMore');
    } catch (e) {
      _error = 'Error al cargar productos: $e';
      AppLogger.e('Error fetchProducts', e);
      if (loadMore) {
        _currentPage--; // Revertir página en caso de error
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProducts(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

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
    } catch (e) {
      _error = 'Error cargando productos del usuario: $e';
      AppLogger.e('Error fetchUserProducts', e);
      _userProducts = [];
    } finally {
      _isLoading = false;
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
        await fetchProducts(); // Recargar lista completa
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
      AppLogger.d('🔍 Obteniendo producto por ID: $productId');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final product = Product.fromMap(Map<String, dynamic>.from(response));
      AppLogger.d('✅ Producto obtenido: ${product.titulo}');
      return product;
    } catch (e) {
      AppLogger.e('Error getProductById', e);
      return null;
    }
  }

  Future<String?> markProductAsSold(String productId) async {
    try {
      AppLogger.d('🏷️ Marcando producto como vendido: $productId');
      
      await _supabase
          .from('products')
          .update({'disponible': false})
          .eq('id', productId);

      AppLogger.d('✅ Producto marcado como vendido: $productId');
      
      // ✅ ACTUALIZACIÓN LOCAL SIN RECARGAR COMPLETA
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(disponible: false);
      }
      
      // Actualizar también en userProducts
      final userIndex = _userProducts.indexWhere((p) => p.id == productId);
      if (userIndex != -1) {
        _userProducts[userIndex] = _userProducts[userIndex].copyWith(disponible: false);
      }
      
      notifyListeners();
      return null;
    } catch (e) {
      AppLogger.e('Error markProductAsSold', e);
      return 'Error: $e';
    }
  }

  // ✅ NUEVO MÉTODO: Reactivar producto
  Future<String?> reactivateProduct(String productId) async {
    try {
      AppLogger.d('🔄 Reactivando producto: $productId');
      
      await _supabase
          .from('products')
          .update({'disponible': true})
          .eq('id', productId);

      AppLogger.d('✅ Producto reactivado: $productId');
      
      // ✅ ACTUALIZACIÓN LOCAL
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(disponible: true);
      }
      
      // Actualizar también en userProducts
      final userIndex = _userProducts.indexWhere((p) => p.id == productId);
      if (userIndex != -1) {
        _userProducts[userIndex] = _userProducts[userIndex].copyWith(disponible: true);
      }
      
      notifyListeners();
      return null;
    } catch (e) {
      AppLogger.e('Error reactivateProduct', e);
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
      AppLogger.d('✏️ Actualizando producto: $productId');
      
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
      
      // ✅ ACTUALIZACIÓN LOCAL
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          titulo: titulo,
          descripcion: descripcion,
          precio: precio,
          categorias: categorias,
          moneda: moneda,
        );
      }
      
      final userIndex = _userProducts.indexWhere((p) => p.id == productId);
      if (userIndex != -1) {
        _userProducts[userIndex] = _userProducts[userIndex].copyWith(
          titulo: titulo,
          descripcion: descripcion,
          precio: precio,
          categorias: categorias,
          moneda: moneda,
        );
      }
      
      notifyListeners();
      return null;
    } catch (e) {
      AppLogger.e('Error updateProduct', e);
      return 'Error: $e';
    }
  }

  Future<String?> deleteProduct(String productId) async {
    try {
      AppLogger.d('🗑️ Eliminando producto: $productId');
      
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);

      AppLogger.d('✅ Producto eliminado: $productId');
      
      // ✅ ELIMINACIÓN LOCAL
      _products.removeWhere((p) => p.id == productId);
      _userProducts.removeWhere((p) => p.id == productId);
      notifyListeners();
      
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

  // ✅ MÉTODO: Búsqueda eficiente de productos (LOCAL)
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

  // ✅ MÉTODO: Filtrar por categoría (LOCAL)
  List<Product> filterByCategory(String category) {
    if (category == 'Todos') return _products;
    return _products.where((product) => product.categorias == category).toList();
  }

  // ✅ MÉTODO: Obtener productos por categoría (REMOTO)
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      AppLogger.d('📂 Obteniendo productos por categoría: $category');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('categorias', category)
          .eq('disponible', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos por categoría cargados: ${products.length}');
      return products;
    } catch (e) {
      AppLogger.e('Error getProductsByCategory', e);
      return [];
    }
  }

  // ✅ MÉTODO: Obtener productos similares (REMOTO)
  Future<List<Product>> getSimilarProducts(Product product, {int limit = 4}) async {
    try {
      AppLogger.d('🔍 Buscando productos similares a: ${product.titulo}');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('categorias', product.categorias)
          .neq('id', product.id)
          .eq('disponible', true)
          .order('created_at', ascending: false)
          .limit(limit);

      final similarProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos similares encontrados: ${similarProducts.length}');
      return similarProducts;
    } catch (e) {
      AppLogger.e('Error getSimilarProducts', e);
      return [];
    }
  }

  // ✅ MÉTODO: Obtener productos por usuario específico (REMOTO)
  Future<List<Product>> getProductsByUser(String userId) async {
    try {
      AppLogger.d('👤 Obteniendo productos del usuario: $userId');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .eq('disponible', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos del usuario cargados: ${products.length}');
      return products;
    } catch (e) {
      AppLogger.e('Error getProductsByUser', e);
      return [];
    }
  }

  // ✅ MÉTODO SIMPLIFICADO: Búsqueda con filtros (LOCAL)
  List<Product> searchWithFilters({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool onlyAvailable = true,
  }) {
    try {
      AppLogger.d('🔍 Búsqueda con filtros locales');
      
      return _products.where((product) {
        // Filtro por disponibilidad
        if (onlyAvailable && !product.disponible) return false;
        
        // Filtro por categoría
        if (category != null && category != 'Todos' && product.categorias != category) {
          return false;
        }
        
        // Filtro por precio
        if (minPrice != null && product.precio < minPrice) return false;
        if (maxPrice != null && product.precio > maxPrice) return false;
        
        // Filtro por texto de búsqueda
        if (query != null && query.isNotEmpty) {
          final searchQuery = query.toLowerCase();
          final matchesTitle = product.titulo.toLowerCase().contains(searchQuery);
          final matchesDescription = product.descripcion?.toLowerCase().contains(searchQuery) ?? false;
          final matchesCategory = product.categorias.toLowerCase().contains(searchQuery);
          
          if (!matchesTitle && !matchesDescription && !matchesCategory) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      AppLogger.e('Error en searchWithFilters', e);
      return [];
    }
  }

  // ✅ MÉTODO: Obtener productos más recientes (REMOTO)
  Future<List<Product>> getRecentProducts({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      AppLogger.e('Error getRecentProducts', e);
      return [];
    }
  }

  // ✅ MÉTODO: Actualizar imagen del producto
  Future<String?> updateProductImage(String productId, String newImageUrl) async {
    try {
      await _supabase
          .from('products')
          .update({'imagen_url': newImageUrl})
          .eq('id', productId);

      // Actualización local
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(imagenUrl: newImageUrl);
        notifyListeners();
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error updateProductImage', e);
      return 'Error: $e';
    }
  }

  // ✅ MÉTODO: Limpiar cache
  void clearCache() {
    _products = [];
    _userProducts = [];
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  // ✅ MÉTODO: Obtener estadísticas de productos
  Map<String, int> getProductStats() {
    final total = _products.length;
    final available = _products.where((p) => p.disponible).length;
    final sold = total - available;
    final userTotal = _userProducts.length;
    final userAvailable = _userProducts.where((p) => p.disponible).length;
    final userSold = userTotal - userAvailable;

    return {
      'total': total,
      'available': available,
      'sold': sold,
      'userTotal': userTotal,
      'userAvailable': userAvailable,
      'userSold': userSold,
    };
  }

  // ✅ MÉTODO: Verificar si el usuario es dueño del producto
  bool isProductOwner(String productId, String userId) {
    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => _userProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: '',
            titulo: '',
            precio: 0,
            categorias: '',
            userId: '',
            createdAt: DateTime.now(),
            latitud: 0,
            longitud: 0,
            moneda: 'CUP',
            disponible: true,
          ),
        ),
      );
      return product.userId == userId;
    } catch (e) {
      return false;
    }
  }

  // ✅ MÉTODO: Obtener productos por ubicación (REMOTO)
  Future<List<Product>> getProductsByLocation(double lat, double lng, double radiusKm) async {
    try {
      AppLogger.d('📍 Buscando productos cerca de: $lat, $lng (radio: ${radiusKm}km)');
      
      // Esta es una implementación básica - en una app real usarías PostGIS o cálculo de distancia
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', true)
          .order('created_at', ascending: false);

      final products = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      AppLogger.d('✅ Productos por ubicación cargados: ${products.length}');
      return products;
    } catch (e) {
      AppLogger.e('Error getProductsByLocation', e);
      return [];
    }
  }

  // ✅ MÉTODO: Obtener productos destacados (REMOTO)
  Future<List<Product>> getFeaturedProducts({int limit = 8}) async {
    try {
      AppLogger.d('🌟 Obteniendo productos destacados');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      AppLogger.e('Error getFeaturedProducts', e);
      return [];
    }
  }
}