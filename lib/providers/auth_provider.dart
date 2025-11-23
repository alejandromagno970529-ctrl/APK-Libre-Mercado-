// lib/providers/auth_provider.dart - VERSIÓN COMPLETA CORREGIDA CON TODOS LOS MÉTODOS
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  String? _error;
  AppUser? _currentUser;
  String? _pendingVerificationEmail;

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

  // ✅ MÉTODOS DE VERIFICACIÓN NUEVOS
  Future<void> submitVerification({
    required String userId,
    required String documentUrl,
    String? fullName,
    String? nationalId,
    String? address,
  }) async {
    try {
      AppLogger.d('📄 Enviando verificación para usuario: $userId');
      
      final updateData = {
        'verification_status': 'pending',
        'verification_document_url': documentUrl,
        'verification_submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Agregar campos adicionales si se proporcionan
      if (fullName != null) updateData['full_name'] = fullName;
      if (nationalId != null) updateData['national_id'] = nationalId;
      if (address != null) updateData['address'] = address;

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // Actualizar usuario local
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          verificationStatus: 'pending',
          verificationDocumentUrl: documentUrl,
          verificationSubmittedAt: DateTime.now(),
        );
        notifyListeners();
      }

      AppLogger.d('✅ Verificación enviada exitosamente');
    } catch (e) {
      AppLogger.e('❌ Error enviando verificación', e);
      rethrow;
    }
  }

  Future<void> updateVerificationStatus({
    required String userId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = {
        'verification_status': status,
        'verification_reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNotes != null) {
        updateData['verification_notes'] = adminNotes;
      }

      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // Actualizar usuario local si es el usuario actual
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(
          verificationStatus: status,
          verificationReviewedAt: DateTime.now(),
        );
        notifyListeners();
      }

      AppLogger.d('✅ Estado de verificación actualizado: $status');
    } catch (e) {
      AppLogger.e('❌ Error actualizando verificación', e);
      rethrow;
    }
  }

  // ✅ PRESENCIA EN LÍNEA
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

      AppLogger.d('✅ Presencia actualizada: $isOnline');
    } catch (e) {
      AppLogger.e('❌ Error actualizando presencia: $e');
    }
  }

  // ✅ MÉTODOS EXISTENTES ACTUALIZADOS
  Future<void> refreshUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await loadUserProfile(user.id);
        AppLogger.d('✅ Perfil de usuario actualizado - Productos: ${_currentUser?.actualProductCount}');
      }
    } catch (e) {
      AppLogger.e('❌ Error refrescando perfil de usuario: $e');
    }
  }

  Future<List<AppUser>> getAllStores({String? searchQuery, String? category}) async {
    try {
      AppLogger.d('🏪 BUSCANDO TODAS LAS TIENDAS...');
      
      var query = _supabase
          .from('profiles')
          .select()
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('store_name', '%$searchQuery%');
      }
      
      if (category != null && category.isNotEmpty && category != 'Todos') {
        query = query.eq('store_category', category);
      }

      final response = await query;
      final stores = <AppUser>[];
      
      for (final data in response) {
        final userData = Map<String, dynamic>.from(data);
        
        // Obtener conteo REAL de productos
        final productCountResponse = await _supabase
            .from('products')
            .select('id')
            .eq('user_id', userData['id']);
        
        final actualProductCount = productCountResponse.length;

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
          
          // ✅ VERIFICACIÓN
          verificationStatus: userData['verification_status'] as String? ?? 'pending',
          verificationDocumentUrl: userData['verification_document_url'] as String?,
          verificationSubmittedAt: userData['verification_submitted_at'] != null 
              ? DateTime.parse(userData['verification_submitted_at']) 
              : null,
          verificationReviewedAt: userData['verification_reviewed_at'] != null
              ? DateTime.parse(userData['verification_reviewed_at'])
              : null,

          // ✅ TIENDA
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
          
          // ✅ PRESENCIA
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
        
        stores.add(store);
      }

      AppLogger.d('✅ TIENDAS ENCONTRADAS: ${stores.length}');
      return stores;
    } catch (e) {
      AppLogger.e('❌ ERROR OBTENIENDO TIENDAS: $e');
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
        'message': 'Diagnóstico completado'
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      AppLogger.d('🔄 AuthProvider: Inicializando...');
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      
      AppLogger.d('🔍 Sesión: ${session != null}');
      AppLogger.d('👤 Usuario: ${user?.email}');
      
      if (session != null && user != null) {
        AppLogger.d('✅ Usuario autenticado encontrado');
        await loadUserProfile(user.id);
        await updateUserPresence(true);
      } else {
        AppLogger.d('🔐 No hay usuario autenticado');
        _currentUser = null;
      }
      
      _error = null;
    } catch (e) {
      AppLogger.e('❌ Error en initialize: $e');
      _error = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser?> loadUserProfile(String userId) async {
    try {
      AppLogger.d('📋 Cargando perfil para usuario: $userId');
      
      // Obtener conteo real de productos
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
          
          // ✅ VERIFICACIÓN
          verificationStatus: userData['verification_status'] as String? ?? 'pending',
          verificationDocumentUrl: userData['verification_document_url'] as String?,
          verificationSubmittedAt: userData['verification_submitted_at'] != null 
              ? DateTime.parse(userData['verification_submitted_at']) 
              : null,
          verificationReviewedAt: userData['verification_reviewed_at'] != null
              ? DateTime.parse(userData['verification_reviewed_at'])
              : null,

          // ✅ TIENDA
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
          
          // ✅ PRESENCIA
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
        
        AppLogger.d('✅ Perfil cargado: ${_currentUser!.username} - Productos: $actualProductCount');
        notifyListeners();
        return _currentUser;
      } else {
        await _createInitialProfile(userId);
        return await loadUserProfile(userId);
      }
    } catch (e) {
      AppLogger.e('❌ Error cargando perfil: $e');
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
            
            // ✅ VERIFICACIÓN INICIAL
            'verification_status': 'pending',
            
            // ✅ TIENDA INICIAL
            'is_store_enabled': false,
            'store_stats': {
              'total_products': 0,
              'total_sales': 0,
              'store_rating': 0.0
            },
            
            // ✅ PRESENCIA INICIAL
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
          });
      
      AppLogger.d('✅ Perfil inicial creado para: $userId');
    } catch (e) {
      AppLogger.e('❌ Error creando perfil inicial: $e');
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
      AppLogger.d('✅ Perfil actualizado exitosamente');
      return null;
    } catch (e) {
      AppLogger.e('❌ Error actualizando perfil: $e');
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
      AppLogger.d('✅ Perfil de tienda actualizado exitosamente');
      return null;
    } catch (e) {
      AppLogger.e('❌ Error actualizando perfil de tienda: $e');
      return 'Error actualizando perfil de tienda: $e';
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
      AppLogger.d('📝 REGISTRANDO: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      AppLogger.d('✅ Respuesta registro - User: ${response.user != null}');
      AppLogger.d('✅ Session: ${response.session != null}');

      final user = response.user;
      if (user == null) {
        return 'No se pudo crear el usuario';
      }

      try {
        await _createInitialProfile(user.id);
        AppLogger.d('✅ Perfil inicial creado para: ${user.id}');
      } catch (profileError) {
        AppLogger.e('⚠️ Error creando perfil: $profileError');
      }

      if (response.session == null) {
        AppLogger.d('⚠️ Usuario creado pero email no enviado - ID: ${user.id}');
        _pendingVerificationEmail = email;
        
        AppLogger.d('🎉 Usuario registrado exitosamente (email pendiente)');
        return null;
      }

      AppLogger.d('🎉 Usuario registrado exitosamente - Email enviado');
      return null;

    } catch (e) {
      AppLogger.e('❌ ERROR EN REGISTRO: $e');
      
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
        AppLogger.d('⚠️ Usuario creado pero falló el email - Continuando...');
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
      AppLogger.d('🔐 Intentando login: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      AppLogger.d('📨 Respuesta login - User: ${response.user != null}');
      AppLogger.d('📨 Respuesta login - Session: ${response.session != null}');

      final user = response.user;
      if (user == null) {
        _error = 'No se pudo obtener información del usuario';
        notifyListeners();
        return _error;
      }

      if (response.session == null) {
        AppLogger.d('📧 Email no confirmado - Usuario necesita confirmar');
        _pendingVerificationEmail = email;
        notifyListeners();
        return 'email_not_confirmed';
      }

      AppLogger.d('✅ LOGIN EXITOSO: ${user.email}');
      
      await loadUserProfile(user.id);
      await updateUserPresence(true);
      
      _error = null;
      
      AppLogger.d('🎯 Notificando a todos los listeners del login exitoso');
      notifyListeners();
      
      return null;

    } catch (e) {
      AppLogger.e('❌ ERROR EN LOGIN: $e');
      
      final errorString = e.toString();
      String errorMessage;

      if (errorString.contains('Invalid login credentials')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (errorString.contains('Email not confirmed') || 
                 errorString.contains('email_not_confirmed')) {
        AppLogger.d('📧 Email no confirmado detectado en catch');
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

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      AppLogger.d('🚪 Cerrando sesión...');
      
      await updateUserPresence(false);
      await _supabase.auth.signOut();
      
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
      
      AppLogger.d('✅ Sesión cerrada completamente');
      
    } catch (e) {
      AppLogger.e('❌ Error en logout: $e');
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
          
          // ✅ VERIFICACIÓN
          verificationStatus: userData['verification_status'] as String? ?? 'pending',
          verificationDocumentUrl: userData['verification_document_url'] as String?,
          verificationSubmittedAt: userData['verification_submitted_at'] != null 
              ? DateTime.parse(userData['verification_submitted_at']) 
              : null,
          verificationReviewedAt: userData['verification_reviewed_at'] != null
              ? DateTime.parse(userData['verification_reviewed_at'])
              : null,

          // ✅ TIENDA
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
          
          // ✅ PRESENCIA
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : null,
        );
      }
      return null;
    } catch (e) {
      AppLogger.e('❌ Error obteniendo perfil de usuario $userId: $e');
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
    AppLogger.d('''
🔍 AUTH PROVIDER STATE:
   - isLoading: $isLoading
   - isLoggedIn: $isLoggedIn
   - currentUser: ${currentUser?.email ?? 'null'}
   - username: ${currentUser?.username ?? 'null'}
   - verificationStatus: ${currentUser?.verificationStatus ?? 'null'}
   - hasStore: ${currentUser?.hasStore ?? 'null'}
   - storeName: ${currentUser?.storeName ?? 'null'}
   - actualProductCount: ${currentUser?.actualProductCount ?? 'null'}
   - isOnline: ${currentUser?.isOnline ?? 'null'}
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

  // ✅ MÉTODOS NUEVOS AGREGADOS PARA CORREGIR ERRORES

  Future<void> clearAuthState() async {
    _currentUser = null;
    _error = null;
    _pendingVerificationEmail = null;
    _isLoading = false;
    notifyListeners();
    
    AppLogger.d('🧹 Estado de autenticación limpiado');
  }

  Future<Map<String, dynamic>> verifyCredentials(String email, String password) async {
    try {
      AppLogger.d('🔐 Verificando credenciales para: $email');
      
      // Verificar formato de email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'valid': false,
          'message': 'Email inválido',
          'type': 'invalid_email'
        };
      }

      // Intentar login para verificar credenciales
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return {
          'valid': false,
          'message': 'Credenciales inválidas',
          'type': 'invalid_credentials'
        };
      }

      // Obtener información del perfil
      final userProfile = await getUserProfile(response.user!.id);
      
      // Cerrar sesión después de verificar
      await _supabase.auth.signOut();

      return {
        'valid': true,
        'message': 'Credenciales válidas',
        'type': 'valid_credentials',
        'email_confirmed': response.user!.emailConfirmedAt != null,
        'user_id': response.user!.id,
        'user_profile': userProfile != null
      };

    } catch (e) {
      AppLogger.e('❌ Error verificando credenciales: $e');
      
      String errorType = 'unknown_error';
      String errorMessage = 'Error verificando credenciales';
      
      if (e.toString().contains('Invalid login credentials')) {
        errorType = 'invalid_credentials';
        errorMessage = 'Email o contraseña incorrectos';
      } else if (e.toString().contains('Email not confirmed')) {
        errorType = 'email_not_confirmed';
        errorMessage = 'Email no confirmado';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorType = 'network_error';
        errorMessage = 'Error de conexión';
      }
      
      return {
        'valid': false,
        'message': errorMessage,
        'type': errorType,
        'error': e.toString()
      };
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return 'El email es requerido';
      }

      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return 'Email inválido';
      }

      AppLogger.d('📧 Solicitando reset de contraseña para: $email');
      
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterdemo://reset-password',
      );

      AppLogger.d('✅ Email de recuperación enviado');
      return null;
    } catch (e) {
      AppLogger.e('❌ Error enviando email de recuperación: $e');
      
      if (e.toString().contains('rate limit') || e.toString().contains('too many requests')) {
        return 'Demasiados intentos. Espera unos minutos.';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        return 'Error de conexión. Verifica tu internet.';
      } else {
        return 'Error enviando email de recuperación: $e';
      }
    }
  }

  Future<String?> resendEmailVerification(String email) async {
    try {
      AppLogger.d('📧 Reenviando email de verificación para: $email');
      
      // CORRECCIÓN: signInWithOtp no devuelve un valor utilizable, solo await
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
      
      AppLogger.d('✅ Email de verificación reenviado');
      return null;
    } catch (e) {
      AppLogger.e('❌ Error reenviando email de verificación: $e');
      
      if (e.toString().contains('rate limit')) {
        return 'Demasiados intentos. Espera unos minutos.';
      } else if (e.toString().contains('user not found')) {
        return 'No existe una cuenta con este email';
      } else {
        return 'Error reenviando email: $e';
      }
    }
  }
}