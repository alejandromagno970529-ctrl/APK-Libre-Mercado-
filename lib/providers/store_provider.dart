// lib/providers/store_provider.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_model.dart';
// ignore: unused_import
import '../models/user_model.dart';
import '../utils/logger.dart';

class StoreProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<StoreModel> _stores = [];
  List<StoreModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  StoreProvider(this._supabase);

  List<StoreModel> get stores => _stores;
  List<StoreModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // ✅ NUEVO: MÉTODO DE INICIALIZACIÓN AUTOMÁTICA
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      AppLogger.d('🔄 StoreProvider: Inicializando y cargando tiendas...');
      await fetchAllStores();
      _isInitialized = true;
      AppLogger.d('✅ StoreProvider: Inicialización completada con ${_stores.length} tiendas');
    } catch (e) {
      AppLogger.e('❌ Error inicializando StoreProvider: $e');
      _error = 'Error cargando tiendas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODO MEJORADO: Cargar todas las tiendas automáticamente
  Future<void> fetchAllStores() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('🏪 Cargando todas las tiendas automáticamente...');

      // Primero intentar cargar desde la tabla 'stores' si existe
      try {
        final response = await _supabase
            .from('stores')
            .select()
            .eq('is_active', true)
            .order('created_at', ascending: false);

        // ignore: unnecessary_type_check
        if (response.isNotEmpty && response is List) {
          _stores = (response as List)
              .map((data) => StoreModel.fromMap(Map<String, dynamic>.from(data)))
              .toList();
          
          AppLogger.d('✅ Tiendas cargadas desde tabla stores: ${_stores.length}');
          _isInitialized = true;
          notifyListeners();
          return;
        }
      } catch (e) {
        AppLogger.d('ℹ️ Tabla stores no disponible, cargando desde profiles...');
      }

      // ✅ CORREGIDO: Cargar desde profiles con store habilitado - CONSULTA SIMPLIFICADA
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            username,
            store_name,
            store_description,
            store_logo_url,
            store_banner_url,
            store_category,
            store_address,
            store_phone,
            store_email,
            is_store_enabled,
            store_created_at,
            store_stats,
            is_verified
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null)
          .order('store_created_at', ascending: false);

      AppLogger.d('📊 Respuesta de profiles: ${response.length} registros');

      _stores = (response as List)
          .map((data) {
            try {
              final map = Map<String, dynamic>.from(data);
              
              // ✅ CORREGIDO: Crear StoreModel directamente sin pasar por AppUser
              final store = StoreModel(
                id: map['id']?.toString() ?? '',
                name: map['store_name']?.toString() ?? 'Tienda sin nombre',
                description: map['store_description']?.toString() ?? 'Descripción no disponible',
                ownerId: map['id']?.toString() ?? '',
                imageUrl: map['store_logo_url']?.toString(),
                coverImageUrl: map['store_banner_url']?.toString(),
                category: map['store_category']?.toString() ?? 'General',
                address: map['store_address']?.toString(),
                rating: _parseStoreRating(map['store_stats']),
                ratingCount: _parseStoreRatingCount(map['store_stats']),
                createdAt: _parseStoreCreatedAt(map['store_created_at']),
                isActive: map['is_store_enabled'] == true,
                isProfessionalStore: _isProfessionalStore(map),
                phone: map['store_phone']?.toString(),
                email: map['store_email']?.toString(),
                productCount: _parseProductCount(map['store_stats']),
                totalSales: _parseTotalSales(map['store_stats']),
                isVerified: map['is_verified'] == true,
              );

              AppLogger.d('✅ Tienda creada: ${store.name} - Productos: ${store.productCount}');
              return store;
            } catch (e) {
              AppLogger.e('❌ Error convirtiendo datos a tienda: $e - Data: $data');
              return null;
            }
          })
          .where((store) => store != null)
          .cast<StoreModel>()
          .toList();

      _isInitialized = true;
      AppLogger.d('✅ Tiendas cargadas automáticamente: ${_stores.length}');
      
    } catch (e) {
      _error = 'Error cargando tiendas: $e';
      AppLogger.e('❌ Error fetchAllStores', e);
      _stores = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MÉTODOS AUXILIARES PARA PARSEAR DATOS
  double _parseStoreRating(dynamic storeStats) {
    try {
      if (storeStats is Map) {
        final stats = Map<String, dynamic>.from(storeStats);
        return (stats['store_rating'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  int _parseStoreRatingCount(dynamic storeStats) {
    try {
      if (storeStats is Map) {
        final stats = Map<String, dynamic>.from(storeStats);
        return (stats['total_ratings'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  DateTime _parseStoreCreatedAt(dynamic createdAt) {
    try {
      if (createdAt != null) {
        return DateTime.parse(createdAt.toString()).toLocal();
      }
      return DateTime.now().toLocal();
    } catch (e) {
      return DateTime.now().toLocal();
    }
  }

  int _parseProductCount(dynamic storeStats) {
    try {
      if (storeStats is Map) {
        final stats = Map<String, dynamic>.from(storeStats);
        return (stats['total_products'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _parseTotalSales(dynamic storeStats) {
    try {
      if (storeStats is Map) {
        final stats = Map<String, dynamic>.from(storeStats);
        return (stats['total_sales'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  bool _isProfessionalStore(Map<String, dynamic> map) {
    try {
      final storeStats = map['store_stats'];
      if (storeStats is Map) {
        final stats = Map<String, dynamic>.from(storeStats);
        final productCount = (stats['total_products'] as int?) ?? 0;
        final rating = (stats['store_rating'] as num?)?.toDouble() ?? 0.0;
        return productCount >= 5 && rating >= 4.0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ BUSCAR TIENDAS - CORREGIDO
  Future<List<StoreModel>> searchStores(String query) async {
    try {
      AppLogger.d('🔍 Buscando tiendas: $query');

      if (query.isEmpty) {
        return _stores;
      }

      // Buscar en tiendas existentes primero
      final localResults = _stores.where((store) {
        final searchLower = query.toLowerCase();
        return store.name.toLowerCase().contains(searchLower) ||
            store.description.toLowerCase().contains(searchLower) ||
            store.category.toLowerCase().contains(searchLower);
      }).toList();

      if (localResults.isNotEmpty) {
        return localResults;
      }

      // Si no hay resultados locales, buscar en la base de datos
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            username,
            store_name,
            store_description,
            store_logo_url,
            store_banner_url,
            store_category,
            store_address,
            store_phone,
            store_email,
            is_store_enabled,
            store_created_at,
            store_stats,
            is_verified
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null)
          .or('store_name.ilike.%$query%,store_category.ilike.%$query%,store_description.ilike.%$query%')
          .order('store_created_at', ascending: false);

      final stores = (response as List)
          .map((data) {
            try {
              final map = Map<String, dynamic>.from(data);
              
              return StoreModel(
                id: map['id']?.toString() ?? '',
                name: map['store_name']?.toString() ?? 'Tienda sin nombre',
                description: map['store_description']?.toString() ?? 'Descripción no disponible',
                ownerId: map['id']?.toString() ?? '',
                imageUrl: map['store_logo_url']?.toString(),
                coverImageUrl: map['store_banner_url']?.toString(),
                category: map['store_category']?.toString() ?? 'General',
                address: map['store_address']?.toString(),
                rating: _parseStoreRating(map['store_stats']),
                ratingCount: _parseStoreRatingCount(map['store_stats']),
                createdAt: _parseStoreCreatedAt(map['store_created_at']),
                isActive: map['is_store_enabled'] == true,
                isProfessionalStore: _isProfessionalStore(map),
                phone: map['store_phone']?.toString(),
                email: map['store_email']?.toString(),
                productCount: _parseProductCount(map['store_stats']),
                totalSales: _parseTotalSales(map['store_stats']),
                isVerified: map['is_verified'] == true,
              );
            } catch (e) {
              AppLogger.e('❌ Error mapeando tienda en búsqueda: $e');
              return null;
            }
          })
          .where((store) => store != null)
          .cast<StoreModel>()
          .toList();

      AppLogger.d('✅ Tiendas encontradas: ${stores.length}');
      return stores;
      
    } catch (e) {
      AppLogger.e('❌ Error searchStores', e);
      return [];
    }
  }

  // ✅ OBTENER TIENDA POR ID - CORREGIDO
  Future<StoreModel?> getStoreById(String storeId) async {
    try {
      // Buscar primero en caché local
      final localStore = _stores.firstWhere(
        (store) => store.id == storeId,
        orElse: () => StoreModel(
          id: '',
          name: '',
          description: '',
          ownerId: '',
          category: 'General',
          createdAt: DateTime.now(),
        ),
      );

      if (localStore.id.isNotEmpty) {
        return localStore;
      }

      // Si no está en caché, buscar en la base de datos
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            username,
            store_name,
            store_description,
            store_logo_url,
            store_banner_url,
            store_category,
            store_address,
            store_phone,
            store_email,
            is_store_enabled,
            store_created_at,
            store_stats,
            is_verified
          ''')
          .eq('id', storeId)
          .single();

      final map = Map<String, dynamic>.from(response);
      
      return StoreModel(
        id: map['id']?.toString() ?? '',
        name: map['store_name']?.toString() ?? 'Tienda sin nombre',
        description: map['store_description']?.toString() ?? 'Descripción no disponible',
        ownerId: map['id']?.toString() ?? '',
        imageUrl: map['store_logo_url']?.toString(),
        coverImageUrl: map['store_banner_url']?.toString(),
        category: map['store_category']?.toString() ?? 'General',
        address: map['store_address']?.toString(),
        rating: _parseStoreRating(map['store_stats']),
        ratingCount: _parseStoreRatingCount(map['store_stats']),
        createdAt: _parseStoreCreatedAt(map['store_created_at']),
        isActive: map['is_store_enabled'] == true,
        isProfessionalStore: _isProfessionalStore(map),
        phone: map['store_phone']?.toString(),
        email: map['store_email']?.toString(),
        productCount: _parseProductCount(map['store_stats']),
        totalSales: _parseTotalSales(map['store_stats']),
        isVerified: map['is_verified'] == true,
      );
      
    } catch (e) {
      AppLogger.e('❌ Error getStoreById', e);
      return null;
    }
  }

  // ✅ OBTENER TIENDAS POR CATEGORÍA - CORREGIDO
  Future<List<StoreModel>> getStoresByCategory(String category) async {
    try {
      AppLogger.d('📂 Obteniendo tiendas por categoría: $category');
      
      if (category == 'Todos') {
        return _stores;
      }

      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            username,
            store_name,
            store_description,
            store_logo_url,
            store_banner_url,
            store_category,
            store_address,
            store_phone,
            store_email,
            is_store_enabled,
            store_created_at,
            store_stats,
            is_verified
          ''')
          .eq('is_store_enabled', true)
          .eq('store_category', category)
          .order('store_created_at', ascending: false);

      final stores = (response as List)
          .map((data) {
            try {
              final map = Map<String, dynamic>.from(data);
              
              return StoreModel(
                id: map['id']?.toString() ?? '',
                name: map['store_name']?.toString() ?? 'Tienda sin nombre',
                description: map['store_description']?.toString() ?? 'Descripción no disponible',
                ownerId: map['id']?.toString() ?? '',
                imageUrl: map['store_logo_url']?.toString(),
                coverImageUrl: map['store_banner_url']?.toString(),
                category: map['store_category']?.toString() ?? 'General',
                address: map['store_address']?.toString(),
                rating: _parseStoreRating(map['store_stats']),
                ratingCount: _parseStoreRatingCount(map['store_stats']),
                createdAt: _parseStoreCreatedAt(map['store_created_at']),
                isActive: map['is_store_enabled'] == true,
                isProfessionalStore: _isProfessionalStore(map),
                phone: map['store_phone']?.toString(),
                email: map['store_email']?.toString(),
                productCount: _parseProductCount(map['store_stats']),
                totalSales: _parseTotalSales(map['store_stats']),
                isVerified: map['is_verified'] == true,
              );
            } catch (e) {
              AppLogger.e('❌ Error mapeando tienda por categoría: $e');
              return null;
            }
          })
          .where((store) => store != null)
          .cast<StoreModel>()
          .toList();

      AppLogger.d('✅ Tiendas por categoría obtenidas: ${stores.length}');
      return stores;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo tiendas por categoría: $e');
      return [];
    }
  }

  // ✅ OBTENER TIENDAS POPULARES - CORREGIDO
  Future<List<StoreModel>> getPopularStores({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            username,
            store_name,
            store_description,
            store_logo_url,
            store_banner_url,
            store_category,
            store_address,
            store_phone,
            store_email,
            is_store_enabled,
            store_created_at,
            store_stats,
            is_verified
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null)
          .order('store_rating', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) {
            try {
              final map = Map<String, dynamic>.from(data);
              
              return StoreModel(
                id: map['id']?.toString() ?? '',
                name: map['store_name']?.toString() ?? 'Tienda sin nombre',
                description: map['store_description']?.toString() ?? 'Descripción no disponible',
                ownerId: map['id']?.toString() ?? '',
                imageUrl: map['store_logo_url']?.toString(),
                coverImageUrl: map['store_banner_url']?.toString(),
                category: map['store_category']?.toString() ?? 'General',
                address: map['store_address']?.toString(),
                rating: _parseStoreRating(map['store_stats']),
                ratingCount: _parseStoreRatingCount(map['store_stats']),
                createdAt: _parseStoreCreatedAt(map['store_created_at']),
                isActive: map['is_store_enabled'] == true,
                isProfessionalStore: _isProfessionalStore(map),
                phone: map['store_phone']?.toString(),
                email: map['store_email']?.toString(),
                productCount: _parseProductCount(map['store_stats']),
                totalSales: _parseTotalSales(map['store_stats']),
                isVerified: map['is_verified'] == true,
              );
            } catch (e) {
              AppLogger.e('❌ Error mapeando tienda popular: $e');
              return null;
            }
          })
          .where((store) => store != null)
          .cast<StoreModel>()
          .toList();
    } catch (e) {
      AppLogger.e('❌ Error obteniendo tiendas populares: $e');
      return [];
    }
  }

  // ✅ ACTUALIZAR CONTADOR DE PRODUCTOS DE UNA TIENDA
  Future<void> updateStoreProductCount(String storeId, int newCount) async {
    try {
      final index = _stores.indexWhere((store) => store.id == storeId);
      if (index != -1) {
        _stores[index] = _stores[index].copyWith(productCount: newCount);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.e('❌ Error actualizando contador de productos: $e');
    }
  }

  // ✅ VERIFICAR SI HAY TIENDAS
  bool get hasStores => _stores.isNotEmpty;

  // ✅ LIMPIAR ERRORES
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ LIMPIAR TIENDAS
  void clearStores() {
    _stores = [];
    notifyListeners();
  }

  // ✅ OBTENER ESTADÍSTICAS
  Map<String, dynamic> get storeStats {
    final totalStores = _stores.length;
    final activeStores = _stores.where((store) => store.isActive).length;
    final professionalStores = _stores.where((store) => store.isProfessionalStore).length;
    final verifiedStores = _stores.where((store) => store.isVerified).length;
    final totalProducts = _stores.fold(0, (sum, store) => sum + store.productCount);
    final totalSales = _stores.fold(0, (sum, store) => sum + store.totalSales);

    return {
      'totalStores': totalStores,
      'activeStores': activeStores,
      'professionalStores': professionalStores,
      'verifiedStores': verifiedStores,
      'totalProducts': totalProducts,
      'totalSales': totalSales,
    };
  }

  // ✅ OBTENER CATEGORÍAS DE TIENDAS DISPONIBLES
  List<String> get availableCategories {
    final categories = _stores.map((store) => store.category).toSet().toList();
    categories.sort();
    return ['Todos', ...categories];
  }

  // ✅ NUEVO: FORZAR RECARGA DE TIENDAS
  Future<void> refreshStores() async {
    await fetchAllStores();
  }

  // ✅ NUEVO: DIAGNÓSTICO DE TIENDAS
  void debugStores() {
    AppLogger.d('''
🔍 DIAGNÓSTICO STOREPROVIDER:
   - Tiendas cargadas: ${_stores.length}
   - Inicializado: $_isInitialized
   - Cargando: $_isLoading
   - Error: $_error
   - Tiendas: ${_stores.map((s) => '${s.name} (${s.productCount} productos)').join(', ')}
''');
  }
}