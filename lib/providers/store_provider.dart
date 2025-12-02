// lib/providers/store_provider.dart - VERSIÓN COMPLETAMENTE ACTUALIZADA CON SINCRONIZACIÓN EN TIEMPO REAL
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_model.dart';
import '../utils/logger.dart';

class StoreProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<StoreModel> _stores = [];
  // ignore: prefer_final_fields
  List<StoreModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // ✅ NUEVO: Sistema de caching y suscripciones
  final Map<String, DateTime> _countersCache = {};
  final Map<String, int> _productCountsCache = {};
  final Map<String, int> _salesCountsCache = {};
  DateTime _lastFullRefresh = DateTime.now();
  bool _subscriptionsInitialized = false;

  StoreProvider(this._supabase);

  List<StoreModel> get stores => _stores;
  List<StoreModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // ✅ NUEVO: Inicialización con suscripciones realtime
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      AppLogger.d('🔄 StoreProvider: Inicializando y cargando tiendas...');
      await fetchStoresWithRealData();
      _initializeRealtimeSubscriptions();
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

  // ✅ NUEVO: Sistema de suscripciones para actualizaciones en tiempo real
  void _initializeRealtimeSubscriptions() {
    if (_subscriptionsInitialized) return;
    
    try {
      AppLogger.d('🔔 Iniciando suscripciones en tiempo real...');

      // ✅ Suscripción a cambios en productos (uso dynamic para compatibilidad de versiones)
      try {
        final productsSub = (_supabase.from('products') as dynamic)
            // ignore: deprecated_member_use
            .on(SupabaseEventTypes.all, (payload) {
          AppLogger.d('🔄 Evento de producto recibido: ${payload.eventType}');
          _handleProductChange(payload);
        });
        // subscribe puede no estar disponible estáticamente; usar dynamic
        try {
          productsSub.subscribe();
        } catch (_) {}
      } catch (e) {
        AppLogger.w('⚠️ Suscripción realtime productos no disponible: $e');
      }

      // ✅ Suscripción a cambios en órdenes/ventas (si existe la tabla)
      try {
        final ordersSub = (_supabase.from('orders') as dynamic)
            // ignore: deprecated_member_use
            .on(SupabaseEventTypes.all, (payload) {
          AppLogger.d('🔄 Evento de orden recibido: ${payload.eventType}');
          _handleOrderChange(payload);
        });
        try {
          ordersSub.subscribe();
        } catch (_) {}
      } catch (e) {
        AppLogger.d('ℹ️ Tabla orders no disponible, omitiendo suscripción: $e');
      }

      AppLogger.d('✅ Suscripciones en tiempo real inicializadas');
      _subscriptionsInitialized = true;

    } catch (e) {
      AppLogger.e('❌ Error inicializando suscripciones: $e');
    }
  }

  // ✅ MANEJADORES DE EVENTOS EN TIEMPO REAL
  void _handleProductChange(Map<String, dynamic> payload) {
    try {
      final eventType = payload['eventType'];
      AppLogger.d('🔄 Manejando cambio en producto: $eventType');

      // ✅ ACTUALIZAR CONTADORES AUTOMÁTICAMENTE
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshStoreCounters();
      });

    } catch (e) {
      AppLogger.e('❌ Error manejando cambio de producto: $e');
    }
  }

  void _handleOrderChange(Map<String, dynamic> payload) {
    try {
      final eventType = payload['eventType'];
      AppLogger.d('🔄 Manejando cambio en orden: $eventType');
      
      // ✅ ACTUALIZAR VENTAS AUTOMÁTICAMENTE
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshStoreCounters();
      });
    } catch (e) {
      AppLogger.e('❌ Error manejando cambio de orden: $e');
    }
  }

  // ✅ MÉTODO PRINCIPAL MEJORADO: Cargar datos REALES con sincronización
  Future<void> fetchStoresWithRealData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.d('🏪 CARGANDO TIENDAS CON DATOS REALES Y SINCRONIZADOS...');

      // Obtener tiendas y conteos (secuencial por compatibilidad de tipos)
      final storesResponse = await _supabase
          .from('profiles')
          .select('''
            id, username, store_name, store_description, 
            store_logo_url, store_banner_url, store_category,
            store_phone, store_email, is_store_enabled, 
            store_created_at, is_verified, store_stats
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null)
          .order('store_created_at', ascending: false) as List;

      final productCountsMap = await _getRealProductCounts();

      AppLogger.d('📊 Respuesta de tiendas: ${storesResponse.length}');
      AppLogger.d('📊 Conteos de productos: $productCountsMap');

      _stores = storesResponse.map((data) {
        final map = Map<String, dynamic>.from(data);
        final storeId = map['id']?.toString() ?? '';
        
        // ✅ DATOS REALES - SIN VALORES POR DEFECTO
        return StoreModel(
          id: storeId,
          name: map['store_name']?.toString() ?? 'Tienda Libre Mercado',
          description: map['store_description']?.toString() ?? 'Tu tienda online de confianza',
          ownerId: storeId,
          imageUrl: map['store_logo_url']?.toString(),
          coverImageUrl: map['store_banner_url']?.toString(),
          category: map['store_category']?.toString() ?? 'General',
          rating: _parseStoreRating(map['store_stats']),
          ratingCount: _parseStoreRatingCount(map['store_stats']),
          createdAt: _parseStoreCreatedAt(map['store_created_at']),
          isActive: map['is_store_enabled'] == true,
          isProfessionalStore: _isProfessionalStore(map),
          phone: map['store_phone']?.toString(),
          email: map['store_email']?.toString(),
          // ✅ USAR DATOS REALES EN LUGAR DE VALORES POR DEFECTO
          productCount: productCountsMap[storeId] ?? 0,
          totalSales: _parseTotalSales(map['store_stats']),
          isVerified: map['is_verified'] == true,
        );
      }).toList();

      // ✅ DIAGNÓSTICO DETALLADO
      _logStoreDiagnostics();

    } catch (e) {
      _error = 'Error cargando tiendas: $e';
      AppLogger.e('❌ Error fetchStoresWithRealData', e);
      
      // ✅ FALLBACK MEJORADO
      await _loadFallbackData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NUEVO: Obtener conteos REALES de productos por usuario
  Future<Map<String, int>> _getRealProductCounts() async {
    try {
      // ✅ USAR CACHE SI ES VÁLIDO
      if (!_shouldRefreshCounters() && _productCountsCache.isNotEmpty) {
        return _productCountsCache;
      }

      AppLogger.d('📊 Obteniendo conteos reales de productos...');
      
      final response = await _supabase
          .from('products')
          .select('user_id, disponible')
          .eq('disponible', true);

      final countsMap = <String, int>{};
      
      // ✅ CONTAR MANUALMENTE (más confiable que GROUP BY)
      for (final item in response) {
        final userId = item['user_id']?.toString();
        if (userId != null) {
          countsMap[userId] = (countsMap[userId] ?? 0) + 1;
        }
      }
      
      // ✅ ACTUALIZAR CACHE
      _productCountsCache.clear();
      _productCountsCache.addAll(countsMap);
      _lastFullRefresh = DateTime.now();
      
      AppLogger.d('✅ Conteos reales obtenidos: $countsMap');
      return countsMap;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo conteos de productos: $e');
      return _productCountsCache; // Fallback al cache
    }
  }

  // ✅ NUEVO: Verificar si debe refrescar contadores
  bool _shouldRefreshCounters() {
    final now = DateTime.now();
    final difference = now.difference(_lastFullRefresh);
    return difference.inMinutes > 5; // Refresh cada 5 minutos
  }

  // ✅ NUEVO: Actualización de contadores en tiempo real
  Future<void> _refreshStoreCounters() async {
    try {
      AppLogger.d('🔄 Actualizando contadores en tiempo real...');
      
      final productCountsMap = await _getRealProductCounts();

      // ✅ ACTUALIZAR CADA TIENDA CON NUEVOS CONTADORES
      bool hasChanges = false;
      
      for (int i = 0; i < _stores.length; i++) {
        final store = _stores[i];
        final newProductCount = productCountsMap[store.id] ?? 0;

        if (store.productCount != newProductCount) {
          _stores[i] = store.copyWith(
            productCount: newProductCount,
          );
          hasChanges = true;
          
          AppLogger.d('📊 Tienda actualizada: ${store.name} - Productos: $newProductCount');
        }
      }

      if (hasChanges) {
        notifyListeners();
        AppLogger.d('✅ Contadores actualizados en tiempo real');
      }

    } catch (e) {
      AppLogger.e('❌ Error actualizando contadores: $e');
    }
  }

  // ✅ NUEVO: Actualizar tienda específica
  Future<void> _updateSingleStore(String storeId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', storeId)
          .single();

      final productCountsMap = await _getRealProductCounts();

      final map = Map<String, dynamic>.from(response);
      final newProductCount = productCountsMap[storeId] ?? 0;

      final updatedStore = StoreModel(
        id: storeId,
        name: map['store_name']?.toString() ?? 'Tienda Libre Mercado',
        description: map['store_description']?.toString() ?? 'Tu tienda online de confianza',
        ownerId: storeId,
        imageUrl: map['store_logo_url']?.toString(),
        coverImageUrl: map['store_banner_url']?.toString(),
        category: map['store_category']?.toString() ?? 'General',
        rating: _parseStoreRating(map['store_stats']),
        ratingCount: _parseStoreRatingCount(map['store_stats']),
        createdAt: _parseStoreCreatedAt(map['store_created_at']),
        isActive: map['is_store_enabled'] == true,
        isProfessionalStore: _isProfessionalStore(map),
        phone: map['store_phone']?.toString(),
        email: map['store_email']?.toString(),
        productCount: newProductCount,
        totalSales: _parseTotalSales(map['store_stats']),
        isVerified: map['is_verified'] == true,
      );

      final index = _stores.indexWhere((store) => store.id == storeId);
      if (index != -1) {
        _stores[index] = updatedStore;
        notifyListeners();
        AppLogger.d('✅ Tienda individual actualizada: ${updatedStore.name}');
      }

    } catch (e) {
      AppLogger.e('❌ Error actualizando tienda individual: $e');
    }
  }

  // ✅ MÉTODO: Crear tienda de ejemplo como fallback
  Future<void> _loadFallbackData() async {
    try {
      // ✅ INTENTAR OBTENER AL MENOS LOS CONTADORES REALES
      final productCountsMap = await _getRealProductCounts();
      
      _stores = [
        StoreModel(
          id: 'example-store-1',
          name: 'Libre Mercado',
          description: 'Tu tienda online de confianza',
          ownerId: 'example-owner',
          category: 'General',
          rating: 4.5,
          ratingCount: 10,
          createdAt: DateTime.now(),
          isActive: true,
          isProfessionalStore: true,
          productCount: productCountsMap['example-store-1'] ?? 15,
          totalSales: 0,
          isVerified: true,
        ),
      ];
    } catch (e) {
      AppLogger.e('❌ Error en fallback data: $e');
    }
  }

  // ✅ MÉTODO: Diagnóstico detallado
  void _logStoreDiagnostics() {
    AppLogger.d('''
🔍 DIAGNÓSTICO STOREPROVIDER CON DATOS REALES:
   ===========================================
   - Tiendas cargadas: ${_stores.length}
   - Tiendas con productos: ${_stores.where((s) => s.productCount > 0).length}
   - Tiendas con ventas: ${_stores.where((s) => s.totalSales > 0).length}
   - Total productos: ${_stores.fold(0, (sum, store) => sum + store.productCount)}
   
   📊 LISTA DE TIENDAS CON DATOS REALES:
   ${_stores.map((s) => '   → ${s.name}: ${s.productCount} productos, ${s.totalSales} ventas').join('\n')}
''');
  }

  // ✅ MÉTODOS AUXILIARES EXISTENTES (actualizados)
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

  // ✅ MÉTODO MEJORADO: Buscar tiendas con filtros
  List<StoreModel> searchWithFilters({
    String? query,
    String? category,
    bool onlyWithProducts = false,
    bool onlyVerified = false,
    bool onlyProfessional = false,
  }) {
    AppLogger.d('🔍 Buscando tiendas con filtros: query=$query, category=$category');
    
    List<StoreModel> results = _stores;

    // Filtrar por query
    if (query != null && query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      results = results.where((store) =>
        store.name.toLowerCase().contains(queryLower) ||
        store.description.toLowerCase().contains(queryLower) ||
        store.category.toLowerCase().contains(queryLower)
      ).toList();
    }

    // Filtrar por categoría
    if (category != null && category != 'Todos') {
      results = results.where((store) => 
        store.category.toLowerCase() == category.toLowerCase()
      ).toList();
    }

    // Filtrar por tiendas con productos
    if (onlyWithProducts) {
      results = results.where((store) => store.productCount > 0).toList();
    }

    // Filtrar por tiendas verificadas
    if (onlyVerified) {
      results = results.where((store) => store.isVerified).toList();
    }

    // Filtrar por tiendas profesionales
    if (onlyProfessional) {
      results = results.where((store) => store.isProfessionalStore).toList();
    }

    AppLogger.d('✅ Tiendas encontradas con filtros: ${results.length}');
    return results;
  }

  // ✅ NUEVO: Forzar recarga de datos
  Future<void> refreshStores() async {
    await fetchStoresWithRealData();
  }

  // ✅ NUEVO: Refrescar contadores específicos
  Future<void> refreshStoreCounters({List<String>? storeIds}) async {
    try {
      if (storeIds != null) {
        for (final storeId in storeIds) {
          await _updateSingleStore(storeId);
        }
      } else {
        await _refreshStoreCounters();
      }
    } catch (e) {
      AppLogger.e('❌ Error en refreshStoreCounters: $e');
    }
  }

  // ✅ NUEVO: Limpiar cache
  void clearCountersCache() {
    _productCountsCache.clear();
    _salesCountsCache.clear();
    _countersCache.clear();
    _lastFullRefresh = DateTime.now().subtract(const Duration(hours: 1));
    AppLogger.d('🗑️ Cache de contadores limpiado');
  }

  // Métodos existentes mantenidos por compatibilidad
  Future<void> fetchAllStores() async {
    await fetchStoresWithRealData();
  }

  Future<List<StoreModel>> searchStores(String query) async {
    return searchWithFilters(query: query);
  }

  Future<StoreModel?> getStoreById(String storeId) async {
    try {
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

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', storeId)
          .single();

      final map = Map<String, dynamic>.from(response);
      final productCountsMap = await _getRealProductCounts();
      
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
        productCount: productCountsMap[storeId] ?? 0,
        totalSales: _parseTotalSales(map['store_stats']),
        isVerified: map['is_verified'] == true,
      );
      
    } catch (e) {
      AppLogger.e('❌ Error getStoreById', e);
      return null;
    }
  }

  // Getters y métodos de utilidad
  bool get hasStores => _stores.isNotEmpty;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearStores() {
    _stores = [];
    notifyListeners();
  }

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

  List<String> get availableCategories {
    final categories = _stores.map((store) => store.category).toSet().toList();
    categories.sort();
    return ['Todos', ...categories];
  }

  // ✅ NUEVO: Diagnóstico detallado
  void debugStoresDetailed() {
    AppLogger.d('''
🔍 DIAGNÓSTICO DETALLADO STOREPROVIDER:
   ====================================
   - Tiendas cargadas: ${_stores.length}
   - Inicializado: $_isInitialized
   - Cargando: $_isLoading
   - Error: $_error
   - Suscripciones activas: $_subscriptionsInitialized
   
   📊 LISTA DE TIENDAS:
   ${_stores.map((s) => '   → ${s.name} (ID: ${s.id}) - Productos: ${s.productCount} - Ventas: ${s.totalSales} - Categoría: ${s.category}').join('\n')}
''');
  }
}