// lib/providers/product_provider.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../services/image_upload_service.dart';
import '../utils/logger.dart';
import './store_provider.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  final ImageUploadService _imageUploadService;
  // Optional reference to StoreProvider to notify about changes.
  StoreProvider? _storeProvider;
  List<Product> _products = [];
  List<Product> _userProducts = [];
  bool _isLoading = false;
  bool _isInitialized = false; // ✅ NUEVO: Control de inicialización
  String? _error;
  
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  // Cache para búsquedas
  final Map<String, List<Product>> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  ProductProvider(this._supabase, this._imageUploadService);

  /// Register a [StoreProvider] instance so this provider can notify it
  /// about store counter changes. This avoids using a BuildContext inside
  /// the provider.
  void registerStoreProvider(StoreProvider storeProvider) {
    _storeProvider = storeProvider;
  }

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isInitialized => _isInitialized; // ✅ NUEVO: Para saber si está listo

  // ✅ NUEVO: Método de inicialización automática
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      AppLogger.d('🔄 ProductProvider: Inicializando y cargando productos...');
      await fetchProducts();
      _isInitialized = true;
      AppLogger.d('✅ ProductProvider: Inicialización completada con ${_products.length} productos');
    } catch (e) {
      AppLogger.e('❌ Error inicializando ProductProvider: $e');
      _error = 'Error cargando productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO MODIFICADO: Eliminar dependencia de AuthProvider
  Future<void> _refreshUserProductCount() async {
    try {
      // Simplemente recargamos los productos del usuario para mantener consistencia
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await fetchUserProducts(currentUser.id);
        AppLogger.d('✅ Contador de productos actualizado localmente');
      }
    } catch (e) {
      AppLogger.e('Error actualizando contador de productos: $e');
    }
  }

  // ✅ MÉTODO MODIFICADO: Eliminar producto con sus imágenes
  Future<String?> deleteProduct(String productId) async {
    try {
      AppLogger.d('🗑️ INICIANDO ELIMINACIÓN DE PRODUCTO: $productId');
      
      // 1. Obtener el producto para tener las URLs de las imágenes y user_id
      final product = await getProductById(productId);
      if (product == null) {
        return 'Producto no encontrado';
      }

      final userId = product.userId;

      // 2. Eliminar las imágenes del almacenamiento si existen
      if (product.imagenUrls != null && product.imagenUrls!.isNotEmpty) {
        AppLogger.d('🖼️ Eliminando ${product.imagenUrls!.length} imágenes del producto...');
        
        try {
          await _imageUploadService.deleteMultipleImages(product.imagenUrls!);
          AppLogger.d('✅ Imágenes eliminadas correctamente');
        } catch (e) {
          AppLogger.e('⚠️ Algunas imágenes no pudieron ser eliminadas: $e');
          // Continuar con la eliminación del producto aunque falle la eliminación de imágenes
        }
      }

      // 3. Eliminar el producto de la base de datos
      AppLogger.d('🗃️ Eliminando producto de la base de datos...');
      await _supabase
          .from('products')
          .delete()
          .eq('id', productId);

      AppLogger.d('✅ Producto eliminado completamente: $productId');
      
      // 4. ✅ NUEVO: NOTIFICAR A STORE PROVIDER
      _notifyStoreProvider(userId);
      
      // 5. Actualizar las listas locales
      _products.removeWhere((p) => p.id == productId);
      _userProducts.removeWhere((p) => p.id == productId);
      
      // ✅ MODIFICADO: Actualizar contador localmente
      await _refreshUserProductCount();
      
      // 6. Notificar a los listeners
      notifyListeners();
      
      return null;
    } catch (e) {
      AppLogger.e('❌ ERROR eliminando producto: $e');
      return 'Error al eliminar el producto: $e';
    }
  }

  // ✅ MÉTODO AUXILIAR: Obtener producto por ID (ya existente)
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

      _hasMore = newProducts.length == _pageSize;
      AppLogger.d('✅ Productos cargados: ${_products.length}. ¿Hay más?: $_hasMore');
      
      // Limpiar caché de búsquedas al cargar nuevos productos
      _clearOldCache();
    } catch (e) {
      _error = 'Error al cargar productos: $e';
      AppLogger.e('Error fetchProducts', e);
      if (loadMore) {
        _currentPage--;
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

  // ✅ NUEVO: Notificar cambios al StoreProvider
  void _notifyStoreProvider(String userId) {
    Future.microtask(() {
      try {
        if (_storeProvider != null) {
          _storeProvider!.refreshStoreCounters(storeIds: [userId]);
          AppLogger.d('🔔 Notificando StoreProvider para actualizar tienda: $userId');
        } else {
          AppLogger.w('⚠️ StoreProvider no registrado en ProductProvider; ejecutando fallback');
          _refreshAllStoresAsFallback();
        }
      } catch (e) {
        AppLogger.e('❌ Error notificando a StoreProvider: $e');
        _refreshAllStoresAsFallback();
      }
    });
  }

  // ✅ NUEVO: Fallback para recarga completa
  void _refreshAllStoresAsFallback() {
    Future.microtask(() {
      try {
        if (_storeProvider != null) {
          _storeProvider!.refreshStores();
          AppLogger.d('🔔 Fallback: Recargando todas las tiendas');
        } else {
          AppLogger.w('⚠️ No hay StoreProvider registrado; no se puede recargar tiendas desde ProductProvider');
        }
      } catch (e) {
        AppLogger.e('❌ Error en fallback de StoreProvider: $e');
      }
    });
  }

  Future<String?> createProductWithLocation({
    required String titulo,
    required String descripcion,
    required double? precio,
    required String categorias,
    required String moneda,
    required List<String>? imagenUrls,
    required Map<String, dynamic> locationData,
  }) async {
    try {
      AppLogger.d('🆕 Creando producto con ${imagenUrls?.length ?? 0} imágenes...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'Usuario no autenticado';

      // ✅ CORRECCIÓN: Usar UTC para consistencia con Supabase
      final now = DateTime.now().toUtc();
      AppLogger.d('📅 Timestamp de creación (UTC): $now');

      final productData = <String, dynamic>{
        'titulo': titulo,
        'descripcion': descripcion,
        'categorias': categorias,
        'moneda': moneda,
        'imagen_urls': imagenUrls,
        'imagen_url': imagenUrls?.isNotEmpty == true ? imagenUrls!.first : null,
        'user_id': currentUser.id,
        'created_at': now.toIso8601String(), // ✅ ENVIAR EN UTC
        'latitud': _safeDouble(locationData['latitude'] ?? locationData['latitud'] ?? 0.0),
        'longitud': _safeDouble(locationData['longitude'] ?? locationData['longitud'] ?? 0.0),
        'address': _safeString(locationData['address']),
        'city': _safeString(locationData['city']),
        'disponible': true,
      };

      if (precio != null) {
        productData['precio'] = precio;
      }

      AppLogger.d('📊 Datos del producto a insertar: $productData');

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select();

      if (response.isNotEmpty) {
        AppLogger.d('🎉 Producto creado exitosamente con ${imagenUrls?.length ?? 0} imágenes');
        
        // ✅ NUEVO: NOTIFICAR A STORE PROVIDER PARA ACTUALIZAR CONTADORES
        _notifyStoreProvider(currentUser.id);
        
        // ✅ MODIFICADO: Actualizar contador localmente
        await _refreshUserProductCount();
        
        // ✅ CORRECCIÓN: Recargar productos inmediatamente
        await fetchProducts();
        await fetchUserProducts(currentUser.id);
        
        // Limpiar caché
        clearAllCache();
        
        return null;
      }

      return 'Error al crear el producto';
    } catch (e) {
      AppLogger.e('❌ Error createProductWithLocation', e);
      return 'Error: $e';
    }
  }

  double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _safeString(dynamic value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return 'Ubicación no disponible';
  }

  Future<String?> markProductAsSold(String productId) async {
    try {
      AppLogger.d('🏷️ Marcando producto como vendido: $productId');
      
      await _supabase
          .from('products')
          .update({'disponible': false})
          .eq('id', productId);

      AppLogger.d('✅ Producto marcado como vendido: $productId');
      
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(disponible: false);
      }
      
      final userIndex = _userProducts.indexWhere((p) => p.id == productId);
      if (userIndex != -1) {
        _userProducts[userIndex] = _userProducts[userIndex].copyWith(disponible: false);
      }
      
      // ✅ MODIFICADO: Actualizar contador localmente
      await _refreshUserProductCount();
      
      notifyListeners();
      return null;
    } catch (e) {
      AppLogger.e('Error markProductAsSold', e);
      return 'Error: $e';
    }
  }

  Future<String?> reactivateProduct(String productId) async {
    try {
      AppLogger.d('🔄 Reactivando producto: $productId');
      
      await _supabase
          .from('products')
          .update({'disponible': true})
          .eq('id', productId);

      AppLogger.d('✅ Producto reactivado: $productId');
      
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(disponible: true);
      }
      
      final userIndex = _userProducts.indexWhere((p) => p.id == productId);
      if (userIndex != -1) {
        _userProducts[userIndex] = _userProducts[userIndex].copyWith(disponible: true);
      }
      
      // ✅ MODIFICADO: Actualizar contador localmente
      await _refreshUserProductCount();
      
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
    required double? precio,
    required String categorias,
    required String moneda,
  }) async {
    try {
      AppLogger.d('✏️ Actualizando producto: $productId');
      
      final updateData = <String, dynamic>{
        'titulo': titulo,
        'descripcion': descripcion,
        'categorias': categorias,
        'moneda': moneda,
        'updated_at': DateTime.now().toUtc().toIso8601String(), // ✅ USAR UTC
      };

      updateData['precio'] = precio;

      await _supabase
          .from('products')
          .update(updateData)
          .eq('id', productId);

      AppLogger.d('✅ Producto actualizado: $productId');
      
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
      
      // ✅ MODIFICADO: Actualizar contador localmente
      await _refreshUserProductCount();
      
      notifyListeners();
      return null;
    } catch (e) {
      AppLogger.e('Error updateProduct', e);
      return 'Error: $e';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    // Verificar caché
    final cacheKey = 'search_$query';
    if (_isCacheValid(cacheKey)) {
      AppLogger.d('🔍 Usando búsqueda en caché: $query');
      return _searchCache[cacheKey]!;
    }
    
    final searchTerms = query.toLowerCase().split(' ');
    
    final results = _products.where((product) {
      final title = product.titulo.toLowerCase();
      final description = product.descripcion?.toLowerCase() ?? '';
      final category = product.categorias.toLowerCase();
      
      for (final term in searchTerms) {
        if (title.contains(term) || 
            description.contains(term) || 
            category.contains(term)) {
          return true;
        }
      }
      return false;
    }).toList();

    // Guardar en caché
    _searchCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    AppLogger.d('🔍 Búsqueda completada: $query - ${results.length} resultados');
    
    return results;
  }

  List<Product> filterByCategory(String category) {
    if (category == 'Todos') return _products;
    
    final cacheKey = 'category_$category';
    if (_isCacheValid(cacheKey)) {
      return _searchCache[cacheKey]!;
    }
    
    final results = _products.where((product) => product.categorias == category).toList();
    
    _searchCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return results;
  }

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

  // ✅ MÉTODO CORREGIDO: Removido filtro de disponibilidad para mostrar TODOS los productos
  Future<List<Product>> getProductsByUser(String userId) async {
    try {
      AppLogger.d('👤 Obteniendo productos del usuario: $userId');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
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

  List<Product> searchWithFilters({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool onlyAvailable = true,
  }) {
    try {
      AppLogger.d('🔍 Búsqueda con filtros locales - Productos disponibles: ${_products.length}');
      
      // Si no hay productos, retornar lista vacía
      if (_products.isEmpty) {
        AppLogger.d('⚠️ No hay productos para filtrar');
        return [];
      }

      return _products.where((product) {
        if (onlyAvailable && !product.disponible) return false;
        
        if (category != null && category != 'Todos' && product.categorias != category) {
          return false;
        }
        
        if (minPrice != null && (product.precio == null || product.precio! < minPrice)) return false;
        if (maxPrice != null && (product.precio == null || product.precio! > maxPrice)) return false;
        
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

  Future<String?> updateProductImages(String productId, List<String> newImageUrls) async {
    try {
      await _supabase
          .from('products')
          .update({'imagen_urls': newImageUrls})
          .eq('id', productId);

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(imagenUrls: newImageUrls);
        notifyListeners();
      }
      
      // ✅ MODIFICADO: Actualizar contador localmente
      await _refreshUserProductCount();
      
      return null;
    } catch (e) {
      AppLogger.e('Error updateProductImages', e);
      return 'Error: $e';
    }
  }

  void clearCache() {
    _products = [];
    _userProducts = [];
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

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

  bool isProductOwner(String productId, String userId) {
    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => _userProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: '',
            titulo: '',
            precio: null,
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

  Future<List<Product>> getProductsByLocation(double lat, double lng, double radiusKm) async {
    try {
      AppLogger.d('📍 Buscando productos cerca de: $lat, $lng (radio: ${radiusKm}km)');
      
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

  // Métodos de caché
  bool _isCacheValid(String key) {
    if (!_searchCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    // Cache válido por 2 minutos
    return difference.inMinutes < 2;
  }

  void _clearOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inMinutes > 5) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      AppLogger.d('🗑️ Caché limpiado: ${keysToRemove.length} entradas removidas');
    }
  }

  void clearAllCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    AppLogger.d('🗑️ Todo el caché limpiado');
  }

  // Método para obtener productos con ubicación (optimizado para mapa)
  List<Product> getProductsWithLocation() {
    return _products.where((product) => product.hasLocation).toList();
  }

  // Método para buscar productos con prioridad en título
  List<Product> searchProductsWithPriority(String query) {
    if (query.isEmpty) return _products;
    
    final cacheKey = 'priority_search_$query';
    if (_isCacheValid(cacheKey)) {
      return _searchCache[cacheKey]!;
    }
    
    final searchQuery = query.toLowerCase();
    final results = <Product>[];
    final titleMatches = <Product>[];
    final descriptionMatches = <Product>[];
    final categoryMatches = <Product>[];
    
    for (final product in _products) {
      final title = product.titulo.toLowerCase();
      final description = product.descripcion?.toLowerCase() ?? '';
      final category = product.categorias.toLowerCase();
      
      if (title.contains(searchQuery)) {
        titleMatches.add(product);
      } else if (description.contains(searchQuery)) {
        descriptionMatches.add(product);
      } else if (category.contains(searchQuery)) {
        categoryMatches.add(product);
      }
    }
    
    // Ordenar por prioridad: título > descripción > categoría
    results.addAll(titleMatches);
    results.addAll(descriptionMatches);
    results.addAll(categoryMatches);
    
    _searchCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return results;
  }

  // Método para obtener productos por disponibilidad
  List<Product> getAvailableProducts() {
    return _products.where((product) => product.disponible).toList();
  }

  // Método para obtener productos vendidos
  List<Product> getSoldProducts() {
    return _products.where((product) => !product.disponible).toList();
  }

  // Método para obtener productos del usuario por disponibilidad
  List<Product> getUserAvailableProducts(String userId) {
    return _userProducts.where((product) => 
      product.userId == userId && product.disponible
    ).toList();
  }

  // Método para obtener productos vendidos del usuario
  List<Product> getUserSoldProducts(String userId) {
    return _userProducts.where((product) => 
      product.userId == userId && !product.disponible
    ).toList();
  }

  // Método para verificar si un producto existe
  bool productExists(String productId) {
    return _products.any((product) => product.id == productId) ||
           _userProducts.any((product) => product.id == productId);
  }

  // Método para obtener productos por rango de precios
  List<Product> getProductsByPriceRange(double minPrice, double maxPrice) {
    return _products.where((product) => 
      product.precio != null && 
      product.precio! >= minPrice && 
      product.precio! <= maxPrice
    ).toList();
  }

  // Método para obtener productos ordenados por precio
  List<Product> getProductsSortedByPrice({bool ascending = true}) {
    final sorted = List<Product>.from(_products);
    sorted.sort((a, b) {
      final priceA = a.precio ?? 0.0;
      final priceB = b.precio ?? 0.0;
      return ascending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
    });
    return sorted;
  }

  // Método para obtener productos ordenados por fecha
  List<Product> getProductsSortedByDate({bool ascending = false}) {
    final sorted = List<Product>.from(_products);
    sorted.sort((a, b) {
      return ascending 
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  // Método para obtener estadísticas de categorías
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final product in _products) {
      final category = product.categorias;
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  // Método para obtener productos con imágenes
  List<Product> getProductsWithImages() {
    return _products.where((product) => 
      product.imagenUrls != null && product.imagenUrls!.isNotEmpty
    ).toList();
  }

  // Método para obtener productos sin imágenes
  List<Product> getProductsWithoutImages() {
    return _products.where((product) => 
      product.imagenUrls == null || product.imagenUrls!.isEmpty
    ).toList();
  }

  // Método para obtener productos por moneda
  List<Product> getProductsByCurrency(String currency) {
    return _products.where((product) => product.moneda == currency).toList();
  }

  // Método para obtener productos cercanos (simulación)
  List<Product> getNearbyProducts(double userLat, double userLng, double radiusKm) {
    return _products.where((product) {
      if (!product.hasLocation) return false;
      
      final distance = _calculateDistance(
        userLat, userLng, product.latitud, product.longitud
      );
      return distance <= radiusKm * 1000; // Convertir km a metros
    }).toList();
  }

  // ✅ MÉTODO AUXILIAR CORREGIDO - Ahora usa las funciones de dart:math
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0; // metros
    
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    // ✅ CORREGIDO: Usar funciones de dart:math
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  // ✅ MÉTODO AUXILIAR CORREGIDO
  double _toRadians(double degrees) {
    return degrees * pi / 180; // ✅ CORREGIDO: 'pi' ahora está disponible desde dart:math
  }

  // ✅ CORREGIDO: Búsqueda avanzada con filtros - SINTAXIS COMPLETAMENTE CORREGIDA
  Future<List<Product>> searchProductsWithFilters({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool onlyAvailable = true,
    String? location,
    double? userLat,
    double? userLng,
    double? radiusKm,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      AppLogger.d('🔍 Búsqueda avanzada en Supabase...');
      
      // Primero obtener todos los productos y luego filtrar localmente
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', onlyAvailable)
          .order('created_at', ascending: false);

      List<Product> allProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      // Aplicar filtros localmente
      List<Product> filteredProducts = allProducts.where((product) {
        // Filtro por query
        if (query != null && query.isNotEmpty) {
          final matchesTitle = product.titulo.toLowerCase().contains(query.toLowerCase());
          final matchesDescription = product.descripcion?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final matchesCategory = product.categorias.toLowerCase().contains(query.toLowerCase());
          if (!matchesTitle && !matchesDescription && !matchesCategory) {
            return false;
          }
        }

        // Filtro por categoría
        if (category != null && category != 'Todos' && product.categorias != category) {
          return false;
        }

        // Filtro por precio mínimo
        if (minPrice != null && (product.precio == null || product.precio! < minPrice)) {
          return false;
        }

        // Filtro por precio máximo
        if (maxPrice != null && (product.precio == null || product.precio! > maxPrice)) {
          return false;
        }

        // Filtro por ubicación
        if (userLat != null && userLng != null && radiusKm != null && product.hasLocation) {
          final distance = _calculateDistance(userLat, userLng, product.latitud, product.longitud);
          if (distance > radiusKm * 1000) {
            return false;
          }
        }

        return true;
      }).toList();

      // Aplicar paginación
      final startIndex = offset;
      final endIndex = offset + limit;
      final paginatedProducts = filteredProducts.sublist(
        startIndex.clamp(0, filteredProducts.length),
        endIndex.clamp(0, filteredProducts.length),
      );

      AppLogger.d('✅ Búsqueda avanzada completada: ${paginatedProducts.length} productos');
      return paginatedProducts;
    } catch (e) {
      AppLogger.e('Error en searchProductsWithFilters', e);
      return [];
    }
  }

  // ✅ NUEVO: Obtener productos populares
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
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
      AppLogger.e('Error obteniendo productos populares', e);
      return [];
    }
  }

  // ✅ NUEVO: Obtener categorías populares basadas en productos
  Future<Map<String, int>> getPopularCategories({int limit = 8}) async {
    try {
      final response = await _supabase
          .from('products')
          .select('categorias')
          .eq('disponible', true);

      final categoryCount = <String, int>{};
      
      for (final item in response) {
        final category = item['categorias'] as String;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Ordenar por frecuencia y tomar las más populares
      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final result = <String, int>{};
      for (int i = 0; i < sortedCategories.length && i < limit; i++) {
        result[sortedCategories[i].key] = sortedCategories[i].value;
      }
      
      return result;
    } catch (e) {
      AppLogger.e('Error obteniendo categorías populares', e);
      return {};
    }
  }

  // ✅ NUEVO: Búsqueda por similitud (para sugerencias)
  Future<List<Product>> getSimilarProductsByTitle(String title, {int limit = 5}) async {
    try {
      // Implementación simplificada - buscar productos con títulos similares
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', true)
          .order('created_at', ascending: false)
          .limit(limit);

      final allProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      // Filtrar localmente por similitud en el título
      final similarProducts = allProducts.where((product) {
        return product.titulo.toLowerCase().contains(title.toLowerCase());
      }).toList();

      return similarProducts.take(limit).toList();
    } catch (e) {
      AppLogger.e('Error en getSimilarProductsByTitle', e);
      return [];
    }
  }

  // ✅ CORREGIDO: Búsqueda por múltiples criterios - IMPLEMENTACIÓN SIMPLIFICADA
  Future<List<Product>> searchByMultipleCriteria({
    required List<String> queries,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    bool onlyAvailable = true,
  }) async {
    try {
      AppLogger.d('🎯 Búsqueda por múltiples criterios: $queries');
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', onlyAvailable)
          .order('created_at', ascending: false);

      List<Product> allProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      // Aplicar filtros localmente
      final filteredProducts = allProducts.where((product) {
        // Filtro por múltiples queries
        if (queries.isNotEmpty) {
          bool matchesAnyQuery = false;
          for (final query in queries) {
            if (product.titulo.toLowerCase().contains(query.toLowerCase()) ||
                product.descripcion?.toLowerCase().contains(query.toLowerCase()) == true ||
                product.categorias.toLowerCase().contains(query.toLowerCase())) {
              matchesAnyQuery = true;
              break;
            }
          }
          if (!matchesAnyQuery) return false;
        }

        // Filtro por categorías
        if (categories != null && categories.isNotEmpty) {
          if (!categories.contains(product.categorias)) {
            return false;
          }
        }

        // Filtro por precio
        if (minPrice != null && (product.precio == null || product.precio! < minPrice)) {
          return false;
        }
        if (maxPrice != null && (product.precio == null || product.precio! > maxPrice)) {
          return false;
        }

        return true;
      }).toList();

      AppLogger.d('✅ Búsqueda múltiple completada: ${filteredProducts.length} productos');
      return filteredProducts;
    } catch (e) {
      AppLogger.e('Error en searchByMultipleCriteria', e);
      return [];
    }
  }

  // ✅ NUEVO: Obtener productos recientemente vistos (simulado)
  Future<List<Product>> getRecentlyViewedProducts(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      // Obtener productos por IDs en orden
      final List<Product> products = [];
      for (final id in productIds) {
        try {
          final product = await getProductById(id);
          if (product != null && product.disponible) {
            products.add(product);
          }
        } catch (e) {
          // Continuar con el siguiente producto si hay error
          continue;
        }
      }

      return products;
    } catch (e) {
      AppLogger.e('Error obteniendo productos recientemente vistos', e);
      return [];
    }
  }

  // ✅ NUEVO: Búsqueda por ubicación exacta
  Future<List<Product>> searchProductsByExactLocation(double lat, double lng, {double tolerance = 0.01}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('disponible', true);

      final allProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      // Filtrar localmente por ubicación
      return allProducts.where((product) {
        if (!product.hasLocation) return false;
        final latDiff = (product.latitud - lat).abs();
        final lngDiff = (product.longitud - lng).abs();
        return latDiff <= tolerance && lngDiff <= tolerance;
      }).toList();
    } catch (e) {
      AppLogger.e('Error en searchProductsByExactLocation', e);
      return [];
    }
  }

  // ✅ CORREGIDO: Obtener estadísticas de búsqueda - SINTAXIS SIMPLIFICADA
  Future<Map<String, dynamic>> getSearchStats() async {
    try {
      // Obtener todos los productos para calcular estadísticas
      final response = await _supabase
          .from('products')
          .select();

      final allProducts = (response as List)
          .map((data) => Product.fromMap(Map<String, dynamic>.from(data)))
          .toList();

      final totalProducts = allProducts.length;
      final availableProducts = allProducts.where((p) => p.disponible).length;
      
      final categoryStats = <String, int>{};
      for (final product in allProducts) {
        if (product.disponible) {
          categoryStats[product.categorias] = (categoryStats[product.categorias] ?? 0) + 1;
        }
      }

      return {
        'totalProducts': totalProducts,
        'availableProducts': availableProducts,
        'totalCategories': categoryStats.length,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo estadísticas de búsqueda', e);
      return {
        'totalProducts': 0,
        'availableProducts': 0,
        'totalCategories': 0,
        'categoryStats': {},
      };
    }
  }

  // ✅ NUEVO: Método para verificar si hay productos
  bool get hasProducts => _products.isNotEmpty;

  // ✅ NUEVO: Método para obtener estadísticas rápidas
  Map<String, dynamic> get debugInfo {
    return {
      'initialized': _isInitialized,
      'total_products': _products.length,
      'user_products': _userProducts.length,
      'loading': _isLoading,
      'error': _error,
      'has_more': _hasMore,
    };
  }
}