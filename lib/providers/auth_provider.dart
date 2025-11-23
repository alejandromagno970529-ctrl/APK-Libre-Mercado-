// lib/providers/auth_provider.dart - VERSIÓN COMPLETA ACTUALIZADA
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  String? _error;
  AppUser? _currentUser;
  String? _pendingVerificationEmail;

  // ✅ NUEVO: Servicio de notificaciones
  // ignore: unused_field
  final NotificationService _notificationService = NotificationService();

  AuthProvider(this._supabase);

  bool get isLoading => _isLoading;
  String? get error => _error;
  AppUser? get currentUser => _currentUser;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool get isLoggedIn {
    try {
      final session = _supabase.auth.currentSession;
      return session != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ NUEVO: Actualizar presencia en línea
  Future<void> updateUserPresence(bool isOnline) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }

      print('✅ Presencia actualizada: $isOnline');
    } catch (e) {
      print('❌ Error actualizando presencia: $e');
    }
  }

  // ✅ NUEVO: MÉTODO DE DIAGNÓSTICO COMPLETO
  Future<void> debugStoresQuery() async {
    try {
      print('🔍 DEBUG STORES QUERY - INICIANDO...');
      
      // 1. Consulta directa a Supabase
      final directQuery = await _supabase
          .from('profiles')
          .select('id, email, store_name, is_store_enabled, store_category, store_stats')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null);
      
      print('📊 RESULTADO CONSULTA DIRECTA: ${directQuery.length} registros');
      
      for (final store in directQuery) {
        print('🏪 TIENDA ENCONTRADA:');
        print('   - ID: ${store['id']}');
        print('   - Email: ${store['email']}');
        print('   - Store Name: ${store['store_name']}');
        print('   - Category: ${store['store_category']}');
        print('   - Enabled: ${store['is_store_enabled']}');
        print('   - Stats: ${store['store_stats']}');
      }
      
      // 2. Probar método getAllStores
      final allStores = await getAllStores();
      print('📊 RESULTADO getAllStores(): ${allStores.length} tiendas');
      
      for (final store in allStores) {
        print('🛍️  TIENDA PROCESADA:');
        print('   - ID: ${store.id}');
        print('   - Store Name: ${store.storeName}');
        print('   - Product Count: ${store.actualProductCount}');
        print('   - Category: ${store.storeCategory}');
        print('   - Enabled: ${store.isStoreEnabled}');
      }
      
    } catch (e) {
      print('❌ ERROR EN DEBUG STORES QUERY: $e');
    }
  }

  Future<void> refreshUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await loadUserProfile(user.id);
        print('✅ Perfil de usuario actualizado - Productos: ${_currentUser?.actualProductCount}');
      }
    } catch (e) {
      print('❌ Error refrescando perfil de usuario: $e');
    }
  }

  // ✅ MÉTODO MEJORADO: Obtener TODAS las tiendas (con diagnóstico)
  Future<List<AppUser>> getAllStores({String? searchQuery, String? category}) async {
    try {
      print('🏪 BUSCANDO TODAS LAS TIENDAS...');
      print('   - Search Query: $searchQuery');
      print('   - Category: $category');
      
      // Construir consulta base
      var query = _supabase
          .from('profiles')
          .select()
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null);

      // Aplicar filtros si existen
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('store_name', '%$searchQuery%');
        print('   - Aplicando filtro search: $searchQuery');
      }
      
      if (category != null && category.isNotEmpty && category != 'Todos') {
        query = query.eq('store_category', category);
        print('   - Aplicando filtro category: $category');
      }

      print('   - Ejecutando consulta...');
      final response = await query;
      print('   - Consulta completada: ${response.length} resultados');

      final stores = <AppUser>[];
      
      for (final data in response) {
        final userData = Map<String, dynamic>.from(data);
        
        print('   - Procesando tienda: ${userData['store_name']}');
        
        // ✅ Obtener conteo REAL de productos para cada tienda
        final productCountResponse = await _supabase
            .from('products')
            .select('id')
            .eq('user_id', userData['id']);
        
        final actualProductCount = productCountResponse.length;
        print('     - Productos encontrados: $actualProductCount');

        final store = AppUser(
          id: userData['id']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          username: userData['username']?.toString() ?? 'Usuario',
          rating: (userData['rating'] as num?)?.toDouble(),
          totalRatings: userData['total_ratings'] as int?,
          joinedAt: userData['joined_at'] != null 
              ? DateTime.parse(userData['joined_at']) 
              : DateTime.now(),
          bio: userData['bio'] as String?,
          phone: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
          isVerified: userData['is_verified'] as bool? ?? false,
          successfulTransactions: userData['successful_transactions'] as int? ?? 0,
          lastActive: userData['last_active'] != null
              ? DateTime.parse(userData['last_active'])
              : DateTime.now(),
          transactionStats: userData['transaction_stats'] != null
              ? Map<String, dynamic>.from(userData['transaction_stats'])
              : {'total': 0, 'as_buyer': 0, 'as_seller': 0},
          storeName: userData['store_name'] as String?,
          storeDescription: userData['store_description'] as String?,
          storeLogoUrl: userData['store_logo_url'] as String?,
          storeBannerUrl: userData['store_banner_url'] as String?,
          storeCategory: userData['store_category'] as String?,
          storeAddress: userData['store_address'] as String?,
          storePhone: userData['store_phone'] as String?,
          storeEmail: userData['store_email'] as String?,
          storeWebsite: userData['store_website'] as String?,
          storePolicy: userData['store_policy'] as String?,
          isStoreEnabled: userData['is_store_enabled'] as bool? ?? false,
          storeCreatedAt: userData['store_created_at'] != null
              ? DateTime.parse(userData['store_created_at'])
              : null,
          storeStats: userData['store_stats'] != null
              ? Map<String, dynamic>.from(userData['store_stats'])
              : {
                  'total_products': actualProductCount, 
                  'total_sales': 0, 
                  'store_rating': 0.0
                },
          actualProductCount: actualProductCount,
          // ✅ NUEVO: Presencia en línea
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
        
        stores.add(store);
      }

      print('✅ TIENDAS ENCONTRADAS: ${stores.length}');
      return stores;
    } catch (e) {
      print('❌ ERROR OBTENIENDO TIENDAS: $e');
      return [];
    }
  }

  // ✅ NUEVO: Método para obtener categorías de tiendas únicas
  Future<List<String>> getStoreCategories() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('store_category')
          .eq('is_store_enabled', true)
          .not('store_category', 'is', null);

      final categories = <String>{}; // Usar Set para valores únicos
      
      for (final item in response) {
        final category = item['store_category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error obteniendo categorías de tiendas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> debugAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'has_session': session != null,
        'has_user': user != null,
        'user_email': user?.email,
        'user_id': user?.id,
        'email_confirmed': user?.emailConfirmedAt != null,
        'auth_provider_logged_in': isLoggedIn,
        'auth_provider_current_user': _currentUser?.email,
        'auth_provider_loading': _isLoading,
        'auth_provider_error': _error,
        'pending_verification_email': _pendingVerificationEmail,
        'message': 'Diagnóstico completado - Información de sesión disponible'
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyCredentials(String email, String password) async {
    try {
      print('🔐 Verificando credenciales para: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null && response.session != null) {
        await _supabase.auth.signOut();
        
        return {
          'valid': true,
          'email_confirmed': response.user?.emailConfirmedAt != null,
          'user_id': response.user?.id,
          'message': 'Credenciales válidas'
        };
      } else {
        return {
          'valid': false,
          'message': 'Credenciales inválidas'
        };
      }
    } catch (e) {
      print('❌ Error verificando credenciales: $e');
      
      final errorString = e.toString();
      Map<String, dynamic> result = {
        'valid': false,
        'error': errorString,
      };

      if (errorString.contains('Invalid login credentials')) {
        result['message'] = 'Email o contraseña incorrectos';
        result['type'] = 'invalid_credentials';
      } else if (errorString.contains('Email not confirmed')) {
        result['message'] = 'Email no confirmado. Verifica tu bandeja de entrada.';
        result['type'] = 'email_not_confirmed';
      } else if (errorString.contains('rate limit')) {
        result['message'] = 'Demasiados intentos. Espera unos minutos.';
        result['type'] = 'rate_limit';
      } else if (errorString.contains('network') || errorString.contains('socket')) {
        result['message'] = 'Error de conexión. Verifica tu internet.';
        result['type'] = 'network_error';
      } else {
        result['message'] = 'Error del servidor. Contacta con soporte.';
        result['type'] = 'server_error';
      }

      return result;
    }
  }

  Future<String?> resendEmailVerification(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      print('📧 Email de verificación reenviado a: $email');
      return null;
    } catch (e) {
      print('❌ Error reenviando email de verificación: $e');
      
      final errorString = e.toString();
      if (errorString.contains('rate limit') || errorString.contains('too many requests')) {
        return 'Demasiados intentos. Espera unos minutos.';
      } else if (errorString.contains('network') || errorString.contains('socket')) {
        return 'Error de conexión. Verifica tu internet.';
      } else {
        return 'No se pudo reenviar el email. Contacta con soporte.';
      }
    }
  }

  Future<void> clearAuthState() async {
    try {
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
      _isLoading = false;
      
      await _supabase.auth.signOut();
      
      print('✅ Estado de autenticación limpiado completamente');
    } catch (e) {
      print('❌ Error limpiando estado auth: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 AuthProvider: Inicializando...');
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      print('🔍 Sesión: ${session != null}');
      print('👤 Usuario: ${user?.email}');
      
      if (session != null && user != null) {
        print('✅ Usuario autenticado encontrado');
        await loadUserProfile(user.id);
        // ✅ NUEVO: Actualizar presencia al inicializar
        await updateUserPresence(true);
      } else {
        print('🔐 No hay usuario autenticado');
        _currentUser = null;
      }
      
      _error = null;
    } catch (e) {
      print('❌ Error en initialize: $e');
      _error = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser?> loadUserProfile(String userId) async {
    try {
      print('📋 Cargando perfil para usuario: $userId');
      
      // ✅ CORRECCIÓN: Usar CountOption correctamente
      final productCountResponse = await _supabase
          .from('products')
          .select('id')
          .eq('user_id', userId);
      
      final actualProductCount = productCountResponse.length;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final userData = Map<String, dynamic>.from(response);
        final authUser = _supabase.auth.currentUser;
        
        _currentUser = AppUser(
          id: userId,
          email: authUser?.email ?? userData['email'] ?? '',
          username: userData['username']?.toString() ?? 
                   authUser?.email?.split('@').first ?? 'Usuario',
          rating: (userData['rating'] as num?)?.toDouble(),
          totalRatings: userData['total_ratings'] as int?,
          joinedAt: userData['joined_at'] != null 
              ? DateTime.parse(userData['joined_at']) 
              : DateTime.now(),
          bio: userData['bio'] as String?,
          phone: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
          isVerified: userData['is_verified'] as bool? ?? false,
          successfulTransactions: userData['successful_transactions'] as int? ?? 0,
          lastActive: userData['last_active'] != null
              ? DateTime.parse(userData['last_active'])
              : DateTime.now(),
          transactionStats: userData['transaction_stats'] != null
              ? Map<String, dynamic>.from(userData['transaction_stats'])
              : {'total': 0, 'as_buyer': 0, 'as_seller': 0},
          storeName: userData['store_name'] as String?,
          storeDescription: userData['store_description'] as String?,
          storeLogoUrl: userData['store_logo_url'] as String?,
          storeBannerUrl: userData['store_banner_url'] as String?,
          storeCategory: userData['store_category'] as String?,
          storeAddress: userData['store_address'] as String?,
          storePhone: userData['store_phone'] as String?,
          storeEmail: userData['store_email'] as String?,
          storeWebsite: userData['store_website'] as String?,
          storePolicy: userData['store_policy'] as String?,
          isStoreEnabled: userData['is_store_enabled'] as bool? ?? false,
          storeCreatedAt: userData['store_created_at'] != null
              ? DateTime.parse(userData['store_created_at'])
              : null,
          storeStats: userData['store_stats'] != null
              ? Map<String, dynamic>.from(userData['store_stats'])
              : {'total_products': 0, 'total_sales': 0, 'store_rating': 0.0},
          actualProductCount: actualProductCount,
          // ✅ NUEVO: Presencia en línea
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
        
        print('✅ Perfil cargado: ${_currentUser!.username} - Productos: $actualProductCount');
        notifyListeners();
        return _currentUser;
      } else {
        await _createInitialProfile(userId);
        return await loadUserProfile(userId);
      }
    } catch (e) {
      print('❌ Error cargando perfil: $e');
      return null;
    }
  }

  Future<void> _createInitialProfile(String userId) async {
    try {
      final authUser = _supabase.auth.currentUser;
      
      await _supabase
          .from('profiles')
          .insert({
            'id': userId,
            'email': authUser?.email ?? '',
            'username': authUser?.email?.split('@').first ?? 'Usuario',
            'rating': 0.0,
            'total_ratings': 0,
            'joined_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'is_verified': false,
            'successful_transactions': 0,
            'last_active': DateTime.now().toIso8601String(),
            'transaction_stats': {
              'total': 0,
              'as_buyer': 0,
              'as_seller': 0
            },
            'is_store_enabled': false,
            'store_stats': {
              'total_products': 0,
              'total_sales': 0,
              'store_rating': 0.0
            },
            // ✅ NUEVO: Presencia en línea inicial
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
          });
      
      print('✅ Perfil inicial creado para: $userId');
    } catch (e) {
      print('❌ Error creando perfil inicial: $e');
    }
  }

  Future<String?> updateUserProfile({
    required String username,
    required String? bio,
    required String? phone,
    required String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'Usuario no autenticado';

      if (username.isEmpty) return 'El nombre de usuario es requerido';
      if (username.length < 3) return 'Mínimo 3 caracteres para el username';
      if (username.length > 30) return 'Máximo 30 caracteres para el username';

      final updateData = {
        'username': username,
        'bio': bio,
        'phone': phone,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      updateData.removeWhere((key, value) => value == null || value == '');

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      await loadUserProfile(user.id);
      print('✅ Perfil actualizado exitosamente');
      return null;
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      return 'Error actualizando perfil: $e';
    }
  }

  Future<String?> updateStoreProfile({
    required String storeName,
    required String? storeDescription,
    required String? storeCategory,
    required String? storeAddress,
    required String? storePhone,
    required String? storeEmail,
    required String? storeWebsite,
    required String? storePolicy,
    required String? storeLogoUrl,
    required String? storeBannerUrl,
    required bool isStoreEnabled,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'Usuario no autenticado';

      if (isStoreEnabled && storeName.isEmpty) {
        return 'El nombre de la tienda es requerido cuando está habilitada';
      }

      final updateData = {
        'store_name': storeName,
        'store_description': storeDescription,
        'store_category': storeCategory,
        'store_address': storeAddress,
        'store_phone': storePhone,
        'store_email': storeEmail,
        'store_website': storeWebsite,
        'store_policy': storePolicy,
        'store_logo_url': storeLogoUrl,
        'store_banner_url': storeBannerUrl,
        'is_store_enabled': isStoreEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isStoreEnabled && _currentUser?.storeCreatedAt == null) {
        updateData['store_created_at'] = DateTime.now().toIso8601String();
      }

      updateData.removeWhere((key, value) => value == null || value == '');

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      await loadUserProfile(user.id);
      print('✅ Perfil de tienda actualizado exitosamente');
      return null;
    } catch (e) {
      print('❌ Error actualizando perfil de tienda: $e');
      return 'Error actualizando perfil de tienda: $e';
    }
  }

  Future<void> updateLastActive() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({
            'last_active': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          lastActive: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error actualizando última actividad: $e');
    }
  }

  Future<void> incrementSuccessfulTransaction({bool asBuyer = false, bool asSeller = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('profiles')
          .select('successful_transactions, transaction_stats')
          .eq('id', user.id)
          .single();

      final currentTransactions = response['successful_transactions'] as int? ?? 0;
      final currentStats = response['transaction_stats'] != null
          ? Map<String, dynamic>.from(response['transaction_stats'])
          : {'total': 0, 'as_buyer': 0, 'as_seller': 0};

      final newStats = {
        'total': (currentStats['total'] as int? ?? 0) + 1,
        'as_buyer': (currentStats['as_buyer'] as int? ?? 0) + (asBuyer ? 1 : 0),
        'as_seller': (currentStats['as_seller'] as int? ?? 0) + (asSeller ? 1 : 0),
      };

      await _supabase
          .from('profiles')
          .update({
            'successful_transactions': currentTransactions + 1,
            'transaction_stats': newStats,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          successfulTransactions: currentTransactions + 1,
          transactionStats: newStats,
        );
        notifyListeners();
      }

      print('✅ Transacción exitosa registrada para: ${user.email}');
    } catch (e) {
      print('❌ Error incrementando transacciones exitosas: $e');
    }
  }

  Future<void> incrementStoreStats({bool isSale = false, bool isProductAdded = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || _currentUser?.hasStore != true) return;

      final response = await _supabase
          .from('profiles')
          .select('store_stats')
          .eq('id', user.id)
          .single();

      final currentStats = response['store_stats'] != null
          ? Map<String, dynamic>.from(response['store_stats'])
          : {'total_products': 0, 'total_sales': 0, 'store_rating': 0.0};

      final newStats = {
        'total_products': (currentStats['total_products'] as int? ?? 0) + (isProductAdded ? 1 : 0),
        'total_sales': (currentStats['total_sales'] as int? ?? 0) + (isSale ? 1 : 0),
        'store_rating': currentStats['store_rating'] ?? 0.0,
      };

      await _supabase
          .from('profiles')
          .update({
            'store_stats': newStats,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(storeStats: newStats);
        notifyListeners();
      }

      print('✅ Estadísticas de tienda actualizadas');
    } catch (e) {
      print('❌ Error incrementando estadísticas de tienda: $e');
    }
  }

  Future<String?> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Email y contraseña son requeridos';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Email inválido. Ejemplo: usuario@dominio.com';
    }
    
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 REGISTRANDO: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      print('✅ Respuesta registro - User: ${response.user != null}');
      print('✅ Session: ${response.session != null}');

      final user = response.user;
      if (user == null) {
        return 'No se pudo crear el usuario';
      }

      try {
        await _createInitialProfile(user.id);
        print('✅ Perfil inicial creado para: ${user.id}');
      } catch (profileError) {
        print('⚠️ Error creando perfil: $profileError');
      }

      if (response.session == null) {
        print('⚠️ Usuario creado pero email no enviado - ID: ${user.id}');
        _pendingVerificationEmail = email;
        
        print('🎉 Usuario registrado exitosamente (email pendiente)');
        return null;
      }

      print('🎉 Usuario registrado exitosamente - Email enviado');
      return null;

    } catch (e) {
      print('❌ ERROR EN REGISTRO: $e');
      
      final errorString = e.toString();
      
      if (errorString.contains('already registered') || 
          errorString.contains('user already exists')) {
        return 'Este email ya está registrado';
      } else if (errorString.contains('invalid email')) {
        return 'Email inválido. Usa un formato válido.';
      } else if (errorString.contains('weak password')) {
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      } else if (errorString.contains('rate limit') || 
                 errorString.contains('too many requests')) {
        return 'Demasiados intentos. Espera unos minutos.';
      } else if (errorString.contains('network') || 
                 errorString.contains('socket') || 
                 errorString.contains('timeout')) {
        return 'Error de conexión. Verifica tu internet.';
      } else if (errorString.contains('Error sending confirmation email') ||
                 errorString.contains('AuthRetryableFetchException') ||
                 errorString.contains('unexpected_failure')) {
        print('⚠️ Usuario creado pero falló el email - Continuando...');
        return null;
      } else {
        return 'Error del servidor. Intenta nuevamente.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email y contraseña son requeridos';
      notifyListeners();
      return _error;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Intentando login: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      print('📨 Respuesta login - User: ${response.user != null}');
      print('📨 Respuesta login - Session: ${response.session != null}');

      final user = response.user;
      if (user == null) {
        _error = 'No se pudo obtener información del usuario';
        notifyListeners();
        return _error;
      }

      if (response.session == null) {
        print('📧 Email no confirmado - Usuario necesita confirmar');
        _pendingVerificationEmail = email;
        notifyListeners();
        return 'email_not_confirmed';
      }

      print('✅ LOGIN EXITOSO: ${user.email}');
      
      await loadUserProfile(user.id);
      await updateLastActive();
      // ✅ NUEVO: Actualizar presencia al iniciar sesión
      await updateUserPresence(true);
      
      _error = null;
      
      print('🎯 Notificando a todos los listeners del login exitoso');
      notifyListeners();
      
      return null;

    } catch (e) {
      print('❌ ERROR EN LOGIN: $e');
      
      final errorString = e.toString();
      String errorMessage;

      if (errorString.contains('Invalid login credentials')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (errorString.contains('Email not confirmed') || 
                 errorString.contains('email_not_confirmed')) {
        print('📧 Email no confirmado detectado en catch');
        _pendingVerificationEmail = email;
        notifyListeners();
        return 'email_not_confirmed';
      } else if (errorString.contains('Invalid email')) {
        errorMessage = 'Email inválido';
      } else if (errorString.contains('network') || errorString.contains('socket')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else {
        errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
      }

      _error = errorMessage;
      notifyListeners();
      return errorMessage;

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerificationStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      final updatedUser = _supabase.auth.currentUser;
      return updatedUser?.emailConfirmedAt != null;
    } catch (e) {
      print('❌ Error verificando estado de email: $e');
      return false;
    }
  }

  Future<String?> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      print('📧 Email de confirmación reenviado a: $email');
      return null;
    } catch (e) {
      print('❌ Error reenviando email: $e');
      return 'Error reenviando email: $e';
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      print('📧 Email de recuperación enviado a: $email');
      return null;
    } catch (e) {
      print('❌ Error enviando email de recuperación: $e');
      return 'Error enviando email de recuperación: $e';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'Usuario no autenticado';

      if (newPassword.length < 6) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('✅ Contraseña actualizada exitosamente');
      return null;
    } catch (e) {
      print('❌ Error actualizando contraseña: $e');
      return 'Error actualizando contraseña: $e';
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('🚪 Cerrando sesión...');
      
      // ✅ NUEVO: Actualizar presencia al cerrar sesión
      await updateUserPresence(false);
      
      await _supabase.auth.signOut();
      
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
      
      print('✅ Sesión cerrada completamente');
      
    } catch (e) {
      print('❌ Error en logout: $e');
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    try {
      // ✅ CORRECCIÓN: Usar CountOption correctamente
      final productCountResponse = await _supabase
          .from('products')
          .select('id')
          .eq('user_id', userId);
      
      final actualProductCount = productCountResponse.length;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final userData = Map<String, dynamic>.from(response);
        
        return AppUser(
          id: userId,
          email: userData['email']?.toString() ?? '',
          username: userData['username']?.toString() ?? 'Usuario',
          rating: (userData['rating'] as num?)?.toDouble(),
          totalRatings: userData['total_ratings'] as int?,
          joinedAt: userData['joined_at'] != null 
              ? DateTime.parse(userData['joined_at']) 
              : DateTime.now(),
          bio: userData['bio'] as String?,
          phone: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
          isVerified: userData['is_verified'] as bool? ?? false,
          successfulTransactions: userData['successful_transactions'] as int? ?? 0,
          lastActive: userData['last_active'] != null
              ? DateTime.parse(userData['last_active'])
              : DateTime.now(),
          transactionStats: userData['transaction_stats'] != null
              ? Map<String, dynamic>.from(userData['transaction_stats'])
              : {'total': 0, 'as_buyer': 0, 'as_seller': 0},
          storeName: userData['store_name'] as String?,
          storeDescription: userData['store_description'] as String?,
          storeLogoUrl: userData['store_logo_url'] as String?,
          storeBannerUrl: userData['store_banner_url'] as String?,
          storeCategory: userData['store_category'] as String?,
          storeAddress: userData['store_address'] as String?,
          storePhone: userData['store_phone'] as String?,
          storeEmail: userData['store_email'] as String?,
          storeWebsite: userData['store_website'] as String?,
          storePolicy: userData['store_policy'] as String?,
          isStoreEnabled: userData['is_store_enabled'] as bool? ?? false,
          storeCreatedAt: userData['store_created_at'] != null
              ? DateTime.parse(userData['store_created_at'])
              : null,
          storeStats: userData['store_stats'] != null
              ? Map<String, dynamic>.from(userData['store_stats'])
              : {'total_products': 0, 'total_sales': 0, 'store_rating': 0.0},
          actualProductCount: actualProductCount,
          // ✅ NUEVO: Presencia en línea
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo perfil de usuario $userId: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPendingEmail() {
    _pendingVerificationEmail = null;
  }

  void debugState() {
    print('''
🔍 AUTH PROVIDER STATE:
   - isLoading: $isLoading
   - isLoggedIn: $isLoggedIn
   - currentUser: ${currentUser?.email ?? 'null'}
   - username: ${currentUser?.username ?? 'null'}
   - rating: ${currentUser?.rating ?? 'null'}
   - totalRatings: ${currentUser?.totalRatings ?? 'null'}
   - transactions: ${currentUser?.successfulTransactions ?? 'null'}
   - hasStore: ${currentUser?.hasStore ?? 'null'}
   - storeName: ${currentUser?.storeName ?? 'null'}
   - actualProductCount: ${currentUser?.actualProductCount ?? 'null'}
   - isOnline: ${currentUser?.isOnline ?? 'null'}
   - lastSeen: ${currentUser?.lastSeen ?? 'null'}
   - pendingEmail: $_pendingVerificationEmail
   - error: $error
''');
  }

  String? get userId {
    return _supabase.auth.currentUser?.id;
  }

  String? get accessToken {
    try {
      return _supabase.auth.currentSession?.accessToken;
    } catch (e) {
      return null;
    }
  }

  bool get isEmailConfirmed {
    try {
      return _supabase.auth.currentUser?.emailConfirmedAt != null;
    } catch (e) {
      return false;
    }
  }

  bool isOwnerOf(String resourceUserId) {
    return _supabase.auth.currentUser?.id == resourceUserId;
  }

  Future<void> updateUserRating(double newRating, int newTotalRatings) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({
            'rating': newRating,
            'total_ratings': newTotalRatings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          rating: newRating,
          totalRatings: newTotalRatings,
        );
        notifyListeners();
      }

      print('✅ Rating actualizado: $newRating ($newTotalRatings valoraciones)');
    } catch (e) {
      print('❌ Error actualizando rating: $e');
    }
  }

  // ✅ MÉTODO ORIGINAL: Obtener tiendas con productos
  Future<List<AppUser>> getStoresWithProducts() async {
    try {
      // Obtener usuarios que tienen tienda habilitada
      final response = await _supabase
          .from('profiles')
          .select('''
            *,
            products:products(count)
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null);

      final stores = <AppUser>[];
      
      for (final data in response) {
        final userData = Map<String, dynamic>.from(data);
        
        // Obtener el conteo de productos
        int productsCount = 0;
        if (userData['products'] is List && (userData['products'] as List).isNotEmpty) {
          final productsData = userData['products'][0] as Map<String, dynamic>;
          productsCount = (productsData['count'] as int?) ?? 0;
        }

        // Solo incluir tiendas que tienen productos
        if (productsCount > 0) {
          final store = AppUser(
            id: userData['id']?.toString() ?? '',
            email: userData['email']?.toString() ?? '',
            username: userData['username']?.toString() ?? 'Usuario',
            rating: (userData['rating'] as num?)?.toDouble(),
            totalRatings: userData['total_ratings'] as int?,
            joinedAt: userData['joined_at'] != null 
                ? DateTime.parse(userData['joined_at']) 
                : DateTime.now(),
            bio: userData['bio'] as String?,
            phone: userData['phone'] as String?,
            avatarUrl: userData['avatar_url'] as String?,
            isVerified: userData['is_verified'] as bool? ?? false,
            successfulTransactions: userData['successful_transactions'] as int? ?? 0,
            lastActive: userData['last_active'] != null
                ? DateTime.parse(userData['last_active'])
                : DateTime.now(),
            transactionStats: userData['transaction_stats'] != null
                ? Map<String, dynamic>.from(userData['transaction_stats'])
                : {'total': 0, 'as_buyer': 0, 'as_seller': 0},
            storeName: userData['store_name'] as String?,
            storeDescription: userData['store_description'] as String?,
            storeLogoUrl: userData['store_logo_url'] as String?,
            storeBannerUrl: userData['store_banner_url'] as String?,
            storeCategory: userData['store_category'] as String?,
            storeAddress: userData['store_address'] as String?,
            storePhone: userData['store_phone'] as String?,
            storeEmail: userData['store_email'] as String?,
            storeWebsite: userData['store_website'] as String?,
            storePolicy: userData['store_policy'] as String?,
            isStoreEnabled: userData['is_store_enabled'] as bool? ?? false,
            storeCreatedAt: userData['store_created_at'] != null
                ? DateTime.parse(userData['store_created_at'])
                : null,
            storeStats: userData['store_stats'] != null
                ? Map<String, dynamic>.from(userData['store_stats'])
                : {'total_products': productsCount, 'total_sales': 0, 'store_rating': 0.0},
            actualProductCount: productsCount,
            // ✅ NUEVO: Presencia en línea
            isOnline: userData['is_online'] as bool? ?? false,
            lastSeen: userData['last_seen'] != null
                ? DateTime.parse(userData['last_seen'])
                : null,
          );
          
          stores.add(store);
        }
      }

      print('✅ Tiendas cargadas: ${stores.length}');
      return stores;
    } catch (e) {
      print('❌ Error obteniendo tiendas: $e');
      return [];
    }
  }
}