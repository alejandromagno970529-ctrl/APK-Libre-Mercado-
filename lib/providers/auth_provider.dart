// lib/providers/auth_provider.dart - VERSIÓN OPTIMIZADA PARA TU ESQUEMA
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';
import '../utils/auth_validator.dart';

class AuthProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  String? _error;
  AppUser? _currentUser;
  String? _pendingVerificationEmail;
  
  // ✅ Control de intentos fallidos
  final Map<String, LoginAttempt> _loginAttempts = {};
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  
  // ignore: unused_field
  final NotificationService _notificationService;

  AuthProvider(this._supabase) : _notificationService = NotificationService(_supabase);

  bool get isLoading => _isLoading;
  String? get error => _error;
  AppUser? get currentUser => _currentUser;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  // ✅ Verificar si usuario está bloqueado
  bool isUserLockedOut(String email) {
    final attempt = _loginAttempts[email];
    if (attempt == null) return false;
    
    if (attempt.isLockedOut && 
        DateTime.now().difference(attempt.lockoutTime!) < _lockoutDuration) {
      return true;
    }
    
    if (!attempt.isLockedOut && 
        DateTime.now().difference(attempt.lastAttempt) > const Duration(hours: 1)) {
      _loginAttempts.remove(email);
      return false;
    }
    
    return false;
  }

  // ✅ Registrar intento fallido
  void _recordFailedAttempt(String email) {
    final now = DateTime.now();
    
    if (!_loginAttempts.containsKey(email)) {
      _loginAttempts[email] = LoginAttempt(email: email);
    }
    
    final attempt = _loginAttempts[email]!;
    attempt.failedCount++;
    attempt.lastAttempt = now;
    
    if (attempt.failedCount >= _maxAttempts) {
      attempt.isLockedOut = true;
      attempt.lockoutTime = now;
      AppLogger.w('🔒 Usuario bloqueado: $email - Intentos: ${attempt.failedCount}');
    }
    
    _cleanupOldAttempts();
  }

  // ✅ Resetear intentos exitosos
  void _resetFailedAttempts(String email) {
    _loginAttempts.remove(email);
    AppLogger.d('✅ Intentos reseteados para: $email');
  }

  // ✅ Limpiar intentos antiguos
  void _cleanupOldAttempts() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    _loginAttempts.forEach((email, attempt) {
      if (now.difference(attempt.lastAttempt) > const Duration(hours: 24)) {
        toRemove.add(email);
      }
    });
    
    for (final email in toRemove) {
      _loginAttempts.remove(email);
    }
  }

  // ✅ Obtener estado de intentos
  Map<String, dynamic> getLoginAttemptStatus(String email) {
    final attempt = _loginAttempts[email];
    if (attempt == null) {
      return {'is_locked': false, 'remaining_attempts': _maxAttempts};
    }
    
    final remaining = _maxAttempts - attempt.failedCount;
    final isLocked = attempt.isLockedOut && 
        DateTime.now().difference(attempt.lockoutTime!) < _lockoutDuration;
    
    if (isLocked) {
      final unlockIn = _lockoutDuration - 
          DateTime.now().difference(attempt.lockoutTime!);
      return {
        'is_locked': true,
        'unlock_in_minutes': unlockIn.inMinutes,
        'lockout_time': attempt.lockoutTime!.toIso8601String(),
      };
    }
    
    return {
      'is_locked': false,
      'remaining_attempts': remaining > 0 ? remaining : 0,
      'failed_count': attempt.failedCount,
    };
  }

  bool get isLoggedIn {
    try {
      final session = _supabase.auth.currentSession;
      return session != null && _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ submitVerification ajustado a tu esquema
  Future<Map<String, dynamic>> submitVerification({
    required String userId,
    required String documentUrl,
    required String fullName,
    required String nationalId,
    required String address,
  }) async {
    try {
      // Validar datos de entrada
      final validation = AuthValidator.validateVerificationData(
        fullName: fullName,
        nationalId: nationalId,
        address: address,
        documentUrl: documentUrl,
      );
      
      final errors = validation.entries
          .where((entry) => entry.value != null)
          .map((entry) => entry.value!)
          .toList();
      
      if (errors.isNotEmpty) {
        return {
          'success': false,
          'error': errors.first,
          'errors': errors,
        };
      }

      AppLogger.d('📄 Enviando verificación para usuario: $userId');
      
      // ✅ AJUSTADO: Campos de verificación en tu esquema profiles
      final updateData = {
        'verification_status': 'pending',
        'verification_document_url': documentUrl,
        'verification_submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      if (response == null) {
        throw Exception('No se pudo actualizar el perfil');
      }

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
      
      return {
        'success': true,
        'message': 'Documentos enviados para revisión',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('❌ Error enviando verificación', e);
      return {
        'success': false,
        'error': 'Error del servidor: ${e.toString()}',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ clearSensitiveData optimizado
  Future<void> clearSensitiveData() async {
    _error = null;
    _pendingVerificationEmail = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_login_email');
      await prefs.remove('session_backup');
    } catch (e) {
      AppLogger.d('No hay datos sensibles para limpiar');
    }
    
    notifyListeners();
  }

  // ✅ updateStoreProfile ajustado a tu esquema
  Future<Map<String, dynamic>> updateStoreProfile({
    required String storeName,
    String? storeDescription,
    String? storeCategory,
    String? storeAddress,
    String? storePhone,
    String? storeEmail,
    String? storeWebsite,
    String? storePolicy,
    String? storeLogoUrl,
    String? storeBannerUrl,
    bool isStoreEnabled = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
          'code': 'UNAUTHENTICATED'
        };
      }

      // Validar nombre de tienda
      if (isStoreEnabled && (storeName.isEmpty || storeName.length < 3)) {
        return {
          'success': false,
          'error': 'Nombre de tienda requerido (mínimo 3 caracteres)',
          'code': 'INVALID_STORE_NAME'
        };
      }

      // Validar email si se proporciona
      if (storeEmail != null && storeEmail.isNotEmpty) {
        final emailError = AuthValidator.validateEmail(storeEmail);
        if (emailError != null) {
          return {
            'success': false,
            'error': 'Email de tienda inválido',
            'code': 'INVALID_STORE_EMAIL'
          };
        }
      }

      // Validar teléfono si se proporciona
      if (storePhone != null && storePhone.isNotEmpty) {
        final phoneError = AuthValidator.validatePhone(storePhone, isRequired: false);
        if (phoneError != null) {
          return {
            'success': false,
            'error': 'Teléfono de tienda inválido',
            'code': 'INVALID_STORE_PHONE'
          };
        }
      }

      final updateData = {
        'store_name': AuthValidator.sanitizeInput(storeName),
        'is_store_enabled': isStoreEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Agregar campos opcionales sanitizados
      void addIfNotNull(String key, String? value) {
        if (value != null && value.isNotEmpty) {
          updateData[key] = AuthValidator.sanitizeInput(value);
        }
      }

      addIfNotNull('store_description', storeDescription);
      addIfNotNull('store_category', storeCategory);
      addIfNotNull('store_address', storeAddress);
      addIfNotNull('store_phone', storePhone);
      addIfNotNull('store_email', storeEmail);
      addIfNotNull('store_website', storeWebsite);
      addIfNotNull('store_policy', storePolicy);
      if (storeLogoUrl != null) updateData['store_logo_url'] = storeLogoUrl;
      if (storeBannerUrl != null) updateData['store_banner_url'] = storeBannerUrl;

      // Si es la primera vez que habilita la tienda
      if (isStoreEnabled && _currentUser?.storeCreatedAt == null) {
        updateData['store_created_at'] = DateTime.now().toIso8601String();
      }

      AppLogger.d('📊 Datos de tienda a actualizar: $updateData');

      final response = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      if (response == null) {
        throw Exception('No se pudo actualizar la tienda');
      }

      AppLogger.d('✅ Perfil de tienda actualizado exitosamente');
      
      await loadUserProfile(user.id);
      
      return {
        'success': true,
        'message': 'Tienda actualizada correctamente',
        'store_name': storeName,
        'is_store_enabled': isStoreEnabled,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('❌ Error actualizando perfil de tienda: $e');
      return {
        'success': false,
        'error': 'Error del servidor: ${e.toString()}',
        'code': 'SERVER_ERROR',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ clearAuthState optimizado
  Future<void> clearAuthState() async {
    try {
      await clearSensitiveData();
      
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
      _isLoading = false;
      
      _loginAttempts.clear();
      
      notifyListeners();
      
      AppLogger.d('🧹 Estado de autenticación limpiado completamente');
    } catch (e) {
      AppLogger.e('Error limpiando estado de auth: $e');
    }
  }

  // ✅ updateUserPresence optimizado para tu esquema
  Future<void> updateUserPresence(bool isOnline) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final updateData = {
        'is_online': isOnline,
        'last_active': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      // ✅ ACTUALIZAR profiles (usando last_active como last_seen)
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      // ✅ ACTUALIZAR user_presence (tabla separada)
      try {
        await _supabase
            .from('user_presence')
            .upsert({
              'user_id': user.id,
              'is_online': isOnline,
              'last_seen_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            }, onConflict: 'user_id');
      } catch (e) {
        AppLogger.w('⚠️ Error en user_presence: $e');
      }

      // Actualizar usuario local
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          isOnline: isOnline,
          lastActive: now,
        );
        notifyListeners();
      }

      AppLogger.d('✅ Presencia actualizada: $isOnline');
    } catch (e) {
      AppLogger.e('❌ Error actualizando presencia: $e');
    }
  }

  // ✅ refreshUserProfile optimizado
  Future<void> refreshUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await loadUserProfile(user.id);
        AppLogger.d('✅ Perfil de usuario actualizado');
      }
    } catch (e) {
      AppLogger.e('❌ Error refrescando perfil de usuario: $e');
    }
  }

  // ✅ getAllStores optimizado para tu esquema
  Future<List<AppUser>> getAllStores({String? searchQuery, String? category}) async {
    try {
      AppLogger.d('🏪 BUSCANDO TODAS LAS TIENDAS...');
      
      var queryBuilder = _supabase
          .from('profiles')
          .select('''
            id, email, username, rating, total_ratings, joined_at, 
            bio, phone, avatar_url, is_verified, 
            last_active, 
            verification_status, verification_document_url,
            verification_submitted_at, verification_reviewed_at,
            store_name, store_description, store_logo_url, store_banner_url,
            store_category, store_address, store_phone, store_email,
            store_website, store_policy, is_store_enabled, store_created_at,
            store_stats, is_online, last_seen
          ''')
          .eq('is_store_enabled', true)
          .not('store_name', 'is', null);
      
      if (category != null && category.isNotEmpty && category != 'Todos') {
        queryBuilder = queryBuilder.eq('store_category', category);
      }
      
      // ignore: unused_local_variable
      var query = queryBuilder
          .order('store_created_at', ascending: false)
          .limit(100);
      
      var response = await query;
      
      // ✅ FILTRAR POR NOMBRE DE TIENDA EN EL CLIENTE (Supabase no soporta LIKE en el builder)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerSearchQuery = searchQuery.toLowerCase();
        response = response.where((store) {
          final storeName = store['store_name']?.toString().toLowerCase() ?? '';
          return storeName.contains(lowerSearchQuery);
        }).toList();
      }
      final stores = <AppUser>[];
      
      // ✅ OBTENER CONTEO DE PRODUCTOS EN BATCH
      final userIds = response.map((s) => s['id'] as String).toList();
      final productCounts = <String, int>{};
      
      if (userIds.isNotEmpty) {
        try {
          final productCountResponse = await _supabase
              .from('products')
              .select('user_id')
              .filter('user_id', 'in', userIds);
          
          for (final product in productCountResponse) {
            final userId = product['user_id'] as String;
            productCounts[userId] = (productCounts[userId] ?? 0) + 1;
          }
        } catch (e) {
          AppLogger.e('❌ Error contando productos: $e');
        }
      }

      for (final data in response) {
        try {
          final userData = Map<String, dynamic>.from(data);
          final userId = userData['id']?.toString() ?? '';
          final actualProductCount = productCounts[userId] ?? 0;

          // ✅ PARSEAR store_stats como JSON
          Map<String, dynamic> storeStats = {'total_sales': 0, 'store_rating': 0, 'total_products': 0};
          if (userData['store_stats'] != null) {
            if (userData['store_stats'] is String) {
              try {
                storeStats = Map<String, dynamic>.from(jsonDecode(userData['store_stats']));
              } catch (e) {
                AppLogger.e('❌ Error parseando store_stats JSON: $e');
              }
            } else if (userData['store_stats'] is Map) {
              storeStats = Map<String, dynamic>.from(userData['store_stats']);
            }
          }

          final store = AppUser(
            id: userId,
            email: userData['email']?.toString() ?? '',
            username: userData['username']?.toString() ?? 'Usuario',
            rating: (userData['rating'] as num?)?.toDouble(),
            totalRatings: userData['total_ratings'] as int? ?? 0,
            joinedAt: userData['joined_at'] != null 
                ? DateTime.parse(userData['joined_at']) 
                : DateTime.now(),
            bio: userData['bio'] as String?,
            phone: userData['phone'] as String?,
            avatarUrl: userData['avatar_url'] as String?,
            isVerified: userData['is_verified'] as bool? ?? false,
            successfulTransactions: 0, // ✅ No existe en tu esquema
            lastActive: userData['last_active'] != null
                ? DateTime.parse(userData['last_active'])
                : DateTime.now(),
            transactionStats: {'total': 0, 'as_buyer': 0, 'as_seller': 0}, // ✅ No existe
            
            verificationStatus: userData['verification_status'] as String? ?? 'pending',
            verificationDocumentUrl: userData['verification_document_url'] as String?,
            verificationSubmittedAt: userData['verification_submitted_at'] != null 
                ? DateTime.parse(userData['verification_submitted_at']) 
                : null,
            verificationReviewedAt: userData['verification_reviewed_at'] != null
                ? DateTime.parse(userData['verification_reviewed_at'])
                : null,

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
            storeStats: storeStats,
            actualProductCount: actualProductCount,
            
            isOnline: userData['is_online'] as bool? ?? false,
            lastSeen: userData['last_seen'] != null
                ? DateTime.parse(userData['last_seen'])
                : userData['last_active'] != null
                    ? DateTime.parse(userData['last_active'])
                    : DateTime.now(),
          );
          
          stores.add(store);
        } catch (e) {
          AppLogger.e('❌ Error procesando tienda ${data['id']}: $e');
        }
      }

      AppLogger.d('✅ TIENDAS ENCONTRADAS: ${stores.length}');
      return stores;
    } catch (e) {
      AppLogger.e('❌ ERROR OBTENIENDO TIENDAS: $e');
      return [];
    }
  }

  // ✅ debugAuthState para diagnóstico
  Future<Map<String, dynamic>> debugAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      final attemptStatus = _loginAttempts.isNotEmpty 
          ? 'Intentos registrados: ${_loginAttempts.length}' 
          : 'Sin intentos registrados';
      
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
        'login_attempts_status': attemptStatus,
        'session_expires_in': session?.expiresIn,
        'access_token_exists': session?.accessToken != null,
        'refresh_token_exists': session?.refreshToken != null,
        'message': 'Diagnóstico completado'
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ✅ initialize optimizado
  Future<void> initialize() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      AppLogger.d('🔄 AuthProvider: Inicializando...');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      _error = 'Error inicializando autenticación';
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ loadUserProfile OPTIMIZADO para tu esquema EXACTO
  Future<AppUser?> loadUserProfile(String userId) async {
    try {
      AppLogger.d('📋 Cargando perfil para usuario: $userId');
      
      // ✅ CONSULTA ÚNICA optimizada para tu esquema
      final response = await _supabase
          .from('profiles')
          .select('''
            id, email, username, rating, total_ratings, joined_at, 
            bio, phone, avatar_url, is_verified, 
            last_active, 
            verification_status, verification_document_url,
            verification_submitted_at, verification_reviewed_at,
            store_name, store_description, store_logo_url, store_banner_url,
            store_category, store_address, store_phone, store_email,
            store_website, store_policy, is_store_enabled, store_created_at,
            store_stats, is_online, last_seen
          ''')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final userData = Map<String, dynamic>.from(response);
        final authUser = _supabase.auth.currentUser;
        
        // ✅ OBTENER CONTEO REAL DE PRODUCTOS
        int actualProductCount = 0;
        try {
          final productCountResponse = await _supabase
              .from('products')
              .select('id')
              .eq('user_id', userId);
          
          actualProductCount = productCountResponse.length;
        } catch (e) {
          AppLogger.e('❌ Error contando productos: $e');
        }

        // ✅ PARSEAR store_stats
        Map<String, dynamic> storeStats = {'total_sales': 0, 'store_rating': 0, 'total_products': actualProductCount};
        if (userData['store_stats'] != null) {
          if (userData['store_stats'] is String) {
            try {
              final parsed = jsonDecode(userData['store_stats']);
              if (parsed is Map) {
                storeStats = Map<String, dynamic>.from(parsed);
                // Actualizar con conteo real
                storeStats['total_products'] = actualProductCount;
              }
            } catch (e) {
              AppLogger.e('❌ Error parseando store_stats JSON: $e');
            }
          } else if (userData['store_stats'] is Map) {
            storeStats = Map<String, dynamic>.from(userData['store_stats']);
            storeStats['total_products'] = actualProductCount;
          }
        } else {
          storeStats['total_products'] = actualProductCount;
        }

        _currentUser = AppUser(
          id: userId,
          email: authUser?.email ?? userData['email'] ?? '',
          username: userData['username']?.toString() ?? 
                   authUser?.email?.split('@').first ?? 'Usuario',
          rating: (userData['rating'] as num?)?.toDouble(),
          totalRatings: userData['total_ratings'] as int? ?? 0,
          joinedAt: userData['joined_at'] != null 
              ? DateTime.parse(userData['joined_at']) 
              : DateTime.now(),
          bio: userData['bio'] as String?,
          phone: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
          isVerified: userData['is_verified'] as bool? ?? false,
          successfulTransactions: 0, // ✅ No existe en tu esquema
          lastActive: userData['last_active'] != null
              ? DateTime.parse(userData['last_active'])
              : DateTime.now(),
          transactionStats: {'total': 0, 'as_buyer': 0, 'as_seller': 0}, // ✅ No existe
            
          verificationStatus: userData['verification_status'] as String? ?? 'pending',
          verificationDocumentUrl: userData['verification_document_url'] as String?,
          verificationSubmittedAt: userData['verification_submitted_at'] != null 
              ? DateTime.parse(userData['verification_submitted_at']) 
              : null,
          verificationReviewedAt: userData['verification_reviewed_at'] != null
              ? DateTime.parse(userData['verification_reviewed_at'])
              : null,

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
          storeStats: storeStats,
          actualProductCount: actualProductCount,
            
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : userData['last_active'] != null
                  ? DateTime.parse(userData['last_active'])
                  : DateTime.now(),
        );
        
        AppLogger.d('✅ Perfil cargado: ${_currentUser!.username} - Productos: $actualProductCount');
        notifyListeners();
        return _currentUser;
      } else {
        // Si no existe perfil, crear uno inicial
        await _createInitialProfile(userId);
        return await loadUserProfile(userId);
      }
    } catch (e) {
      AppLogger.e('❌ Error cargando perfil: $e');
      return null;
    }
  }

  // ✅ _createInitialProfile ajustado a tu esquema
  Future<void> _createInitialProfile(String userId) async {
    try {
      final authUser = _supabase.auth.currentUser;
      final now = DateTime.now().toIso8601String();
      
      final profileData = {
        'id': userId,
        'email': authUser?.email ?? '',
        'username': authUser?.email?.split('@').first ?? 'Usuario',
        'rating': 0.0,
        'total_ratings': 0,
        'joined_at': now,
        'updated_at': now,
        'is_verified': false,
        'last_active': now,
        
        'verification_status': 'pending',
        
        'is_store_enabled': false,
        'store_stats': jsonEncode({
          'total_sales': 0,
          'store_rating': 0,
          'total_products': 0
        }),
        
        'is_online': true,
        'last_seen': now,
      };
      
      await _supabase
          .from('profiles')
          .insert(profileData);
      
      AppLogger.d('✅ Perfil inicial creado para: $userId');
    } catch (e) {
      AppLogger.e('❌ Error creando perfil inicial: $e');
      rethrow;
    }
  }

  // ✅ updateUserProfile ajustado
  Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    required String? bio,
    required String? phone,
    required String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
          'code': 'UNAUTHENTICATED'
        };
      }

      // Validar username
      final usernameError = AuthValidator.validateUsername(username);
      if (usernameError != null) {
        return {
          'success': false,
          'error': usernameError,
          'code': 'INVALID_USERNAME'
        };
      }

      // Validar bio si existe
      if (bio != null && bio.isNotEmpty) {
        final bioError = AuthValidator.validateBio(bio);
        if (bioError != null) {
          return {
            'success': false,
            'error': bioError,
            'code': 'INVALID_BIO'
          };
        }
      }

      // Validar teléfono si existe
      if (phone != null && phone.isNotEmpty) {
        final phoneError = AuthValidator.validatePhone(phone, isRequired: false);
        if (phoneError != null) {
          return {
            'success': false,
            'error': phoneError,
            'code': 'INVALID_PHONE'
          };
        }
      }

      final updateData = {
        'username': AuthValidator.sanitizeInput(username),
        'bio': bio != null ? AuthValidator.sanitizeInput(bio) : null,
        'phone': phone != null ? AuthValidator.sanitizeInput(phone) : null,
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
      
      return {
        'success': true,
        'message': 'Perfil actualizado correctamente',
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('❌ Error actualizando perfil: $e');
      return {
        'success': false,
        'error': 'Error del servidor: ${e.toString()}',
        'code': 'SERVER_ERROR',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ signUp SEGURO con verificación obligatoria
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    // Validación de entrada
    final emailError = AuthValidator.validateEmail(email);
    if (emailError != null) {
      return {
        'success': false,
        'error': emailError,
        'code': 'INVALID_EMAIL',
        'requires_email_verification': false,
      };
    }

    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) {
      return {
        'success': false,
        'error': passwordError,
        'code': 'INVALID_PASSWORD',
        'requires_email_verification': false,
      };
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.d('📝 REGISTRANDO: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'email_verified': false,
          'signup_timestamp': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.d('✅ Respuesta registro - User: ${response.user != null}');
      AppLogger.d('✅ Session: ${response.session != null}');

      final user = response.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'No se pudo crear el usuario',
          'code': 'USER_CREATION_FAILED',
          'requires_email_verification': false,
        };
      }

      try {
        await _createInitialProfile(user.id);
        AppLogger.d('✅ Perfil inicial creado para: ${user.id}');
      } catch (profileError) {
        AppLogger.e('⚠️ Error creando perfil: $profileError');
      }

      // ✅ CORRECCIÓN CRÍTICA: NUNCA permitir acceso sin verificación
      if (response.session == null) {
        AppLogger.d('⚠️ Usuario creado pero email no enviado - ID: ${user.id}');
        _pendingVerificationEmail = email;
        
        return {
          'success': true,
          'message': 'Cuenta creada. Revisa tu email para verificar tu cuenta.',
          'requires_email_verification': true,
          'user_id': user.id,
          'email_sent': false, // Email no se envió automáticamente
        };
      } else {
        // Si hay sesión (configuración atípica), forzar verificación
        await _supabase.auth.signOut();
        _pendingVerificationEmail = email;
        
        return {
          'success': true,
          'message': 'Cuenta creada. Por favor verifica tu email.',
          'requires_email_verification': true,
          'user_id': user.id,
          'email_sent': true,
        };
      }

    } catch (e) {
      AppLogger.e('❌ ERROR EN REGISTRO: $e');
      
      final errorString = e.toString();
      String errorMessage;
      String errorCode = 'UNKNOWN_ERROR';
      bool requiresVerification = false;
      
      if (errorString.contains('already registered') || 
          errorString.contains('user already exists')) {
        errorMessage = 'Este email ya está registrado';
        errorCode = 'EMAIL_ALREADY_EXISTS';
      } else if (errorString.contains('invalid email')) {
        errorMessage = 'Email inválido. Usa un formato válido.';
        errorCode = 'INVALID_EMAIL';
      } else if (errorString.contains('weak password')) {
        errorMessage = 'La contraseña es muy débil. Usa al menos 8 caracteres con mayúsculas, minúsculas, números y un carácter especial.';
        errorCode = 'WEAK_PASSWORD';
      } else if (errorString.contains('rate limit') || 
                 errorString.contains('too many requests')) {
        errorMessage = 'Demasiados intentos. Espera unos minutos.';
        errorCode = 'RATE_LIMITED';
      } else if (errorString.contains('network') || 
                 errorString.contains('socket') || 
                 errorString.contains('timeout')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
        errorCode = 'NETWORK_ERROR';
      } else if (errorString.contains('Error sending confirmation email') ||
                 errorString.contains('AuthRetryableFetchException') ||
                 errorString.contains('unexpected_failure')) {
        errorMessage = 'Cuenta creada pero no se pudo enviar el email de verificación. Contacta con soporte.';
        errorCode = 'EMAIL_SEND_FAILED';
        requiresVerification = true;
      } else {
        errorMessage = 'Error del servidor. Intenta nuevamente.';
        errorCode = 'SERVER_ERROR';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'code': errorCode,
        'requires_email_verification': requiresVerification,
        'raw_error': kDebugMode ? errorString : null,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ signIn con límite de intentos y validación
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    // Validación de entrada
    final emailError = AuthValidator.validateEmail(email);
    if (emailError != null) {
      return {
        'success': false,
        'error': emailError,
        'code': 'INVALID_EMAIL',
        'locked': false,
      };
    }

    if (password.isEmpty) {
      return {
        'success': false,
        'error': 'La contraseña es requerida',
        'code': 'MISSING_PASSWORD',
        'locked': false,
      };
    }

    // Verificar si el usuario está bloqueado
    if (isUserLockedOut(email)) {
      final status = getLoginAttemptStatus(email);
      return {
        'success': false,
        'error': 'Demasiados intentos fallidos. Intenta nuevamente en ${status['unlock_in_minutes']} minutos.',
        'code': 'ACCOUNT_LOCKED',
        'locked': true,
        'unlock_in_minutes': status['unlock_in_minutes'],
      };
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

      final user = response.user;
      if (user == null) {
        _recordFailedAttempt(email);
        return {
          'success': false,
          'error': 'No se pudo obtener información del usuario',
          'code': 'USER_NOT_FOUND',
          'locked': false,
          'remaining_attempts': getLoginAttemptStatus(email)['remaining_attempts'],
        };
      }

      // ✅ VERIFICACIÓN CRÍTICA: Email debe estar confirmado
      if (response.session == null || user.emailConfirmedAt == null) {
        AppLogger.d('📧 Email no confirmado - Usuario necesita confirmar');
        _pendingVerificationEmail = email;
        
        return {
          'success': false,
          'error': 'Debes verificar tu email antes de iniciar sesión',
          'code': 'EMAIL_NOT_CONFIRMED',
          'locked': false,
          'requires_verification': true,
          'user_id': user.id,
        };
      }

      // ✅ Login exitoso: resetear intentos fallidos
      _resetFailedAttempts(email);

      AppLogger.d('✅ LOGIN EXITOSO: ${user.email}');
      
      await loadUserProfile(user.id);
      await updateUserPresence(true);
      
      _error = null;
      
      AppLogger.d('🎯 Notificando a todos los listeners del login exitoso');
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Login exitoso',
        'user_id': user.id,
        'email': user.email,
        'session': response.session != null,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      AppLogger.e('❌ ERROR EN LOGIN: $e');
      
      final errorString = e.toString();
      String errorMessage;
      String errorCode = 'UNKNOWN_ERROR';
      bool locked = false;
      
      _recordFailedAttempt(email);
      final attemptStatus = getLoginAttemptStatus(email);

      if (errorString.contains('Invalid login credentials')) {
        errorMessage = 'Email o contraseña incorrectos';
        errorCode = 'INVALID_CREDENTIALS';
      } else if (errorString.contains('Email not confirmed') || 
                 errorString.contains('email_not_confirmed')) {
        errorMessage = 'Email no confirmado. Revisa tu bandeja de entrada.';
        errorCode = 'EMAIL_NOT_CONFIRMED';
      } else if (errorString.contains('Invalid email')) {
        errorMessage = 'Email inválido';
        errorCode = 'INVALID_EMAIL';
      } else if (errorString.contains('network') || errorString.contains('socket')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
        errorCode = 'NETWORK_ERROR';
      } else if (errorString.contains('rate limit')) {
        errorMessage = 'Demasiados intentos. Espera unos minutos.';
        errorCode = 'RATE_LIMITED';
        locked = true;
      } else if (attemptStatus['is_locked'] == true) {
        errorMessage = 'Cuenta bloqueada temporalmente. Intenta en ${attemptStatus['unlock_in_minutes']} minutos.';
        errorCode = 'ACCOUNT_LOCKED';
        locked = true;
      } else {
        errorMessage = 'Error al iniciar sesión. Intenta nuevamente.';
        errorCode = 'LOGIN_FAILED';
      }
      
      _error = errorMessage;
      notifyListeners();
      
      return {
        'success': false,
        'error': errorMessage,
        'code': errorCode,
        'locked': locked,
        'remaining_attempts': attemptStatus['remaining_attempts'],
        'failed_count': attemptStatus['failed_count'],
        'raw_error': kDebugMode ? errorString : null,
      };

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ signOut con limpieza completa
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      AppLogger.d('🚪 Cerrando sesión...');
      
      await updateUserPresence(false);
      await _supabase.auth.signOut();
      await clearAuthState();
      
      AppLogger.d('✅ Sesión cerrada completamente');
      
    } catch (e) {
      AppLogger.e('❌ Error en logout: $e');
      await clearAuthState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ getUserProfile optimizado
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
            id, email, username, rating, total_ratings, joined_at, 
            bio, phone, avatar_url, is_verified, 
            last_active, 
            verification_status, verification_document_url,
            verification_submitted_at, verification_reviewed_at,
            store_name, store_description, store_logo_url, store_banner_url,
            store_category, store_address, store_phone, store_email,
            store_website, store_policy, is_store_enabled, store_created_at,
            store_stats, is_online, last_seen
          ''')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final userData = Map<String, dynamic>.from(response);
        
        // Obtener conteo de productos
        int actualProductCount = 0;
        try {
          final productCountResponse = await _supabase
              .from('products')
              .select('id')
              .filter('user_id', 'eq', userId);
          actualProductCount = productCountResponse.length;
        } catch (e) {
          AppLogger.e('❌ Error contando productos: $e');
        }

        // Parsear store_stats
        Map<String, dynamic> storeStats = {'total_sales': 0, 'store_rating': 0, 'total_products': actualProductCount};
        if (userData['store_stats'] != null) {
          if (userData['store_stats'] is String) {
            try {
              final parsed = jsonDecode(userData['store_stats']);
              if (parsed is Map) {
                storeStats = Map<String, dynamic>.from(parsed);
                storeStats['total_products'] = actualProductCount;
              }
            } catch (e) {
              AppLogger.e('❌ Error parseando store_stats JSON: $e');
            }
          } else if (userData['store_stats'] is Map) {
            storeStats = Map<String, dynamic>.from(userData['store_stats']);
            storeStats['total_products'] = actualProductCount;
          }
        }

        return AppUser(
          id: userId,
          email: userData['email']?.toString() ?? '',
          username: userData['username']?.toString() ?? 'Usuario',
          rating: (userData['rating'] as num?)?.toDouble(),
          totalRatings: userData['total_ratings'] as int? ?? 0,
          joinedAt: userData['joined_at'] != null 
              ? DateTime.parse(userData['joined_at']) 
              : DateTime.now(),
          bio: userData['bio'] as String?,
          phone: userData['phone'] as String?,
          avatarUrl: userData['avatar_url'] as String?,
          isVerified: userData['is_verified'] as bool? ?? false,
          successfulTransactions: 0,
          lastActive: userData['last_active'] != null
              ? DateTime.parse(userData['last_active'])
              : DateTime.now(),
          transactionStats: {'total': 0, 'as_buyer': 0, 'as_seller': 0},
          
          verificationStatus: userData['verification_status'] as String? ?? 'pending',
          verificationDocumentUrl: userData['verification_document_url'] as String?,
          verificationSubmittedAt: userData['verification_submitted_at'] != null 
              ? DateTime.parse(userData['verification_submitted_at']) 
              : null,
          verificationReviewedAt: userData['verification_reviewed_at'] != null
              ? DateTime.parse(userData['verification_reviewed_at'])
              : null,

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
          storeStats: storeStats,
          actualProductCount: actualProductCount,
          
          isOnline: userData['is_online'] as bool? ?? false,
          lastSeen: userData['last_seen'] != null
              ? DateTime.parse(userData['last_seen'])
              : userData['last_active'] != null
                  ? DateTime.parse(userData['last_active'])
                  : DateTime.now(),
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
   - loginAttempts: ${_loginAttempts.length}
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

  // ✅ verifyCredentials con límite de intentos
  Future<Map<String, dynamic>> verifyCredentials(String email, String password) async {
    try {
      if (isUserLockedOut(email)) {
        return {
          'valid': false,
          'message': 'Cuenta temporalmente bloqueada',
          'type': 'account_locked',
          'locked': true,
        };
      }

      AppLogger.d('🔐 Verificando credenciales para: $email');
      
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        return {
          'valid': false,
          'message': emailError,
          'type': 'invalid_email'
        };
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _recordFailedAttempt(email);
        return {
          'valid': false,
          'message': 'Credenciales inválidas',
          'type': 'invalid_credentials',
          'remaining_attempts': getLoginAttemptStatus(email)['remaining_attempts'],
        };
      }

      final userProfile = await getUserProfile(response.user!.id);
      await _supabase.auth.signOut();

      return {
        'valid': true,
        'message': 'Credenciales válidas',
        'type': 'valid_credentials',
        'email_confirmed': response.user!.emailConfirmedAt != null,
        'user_id': response.user!.id,
        'user_profile': userProfile != null,
        'requires_verification': response.user!.emailConfirmedAt == null,
      };

    } catch (e) {
      AppLogger.e('❌ Error verificando credenciales: $e');
      
      String errorType = 'unknown_error';
      String errorMessage = 'Error verificando credenciales';
      
      if (e.toString().contains('Invalid login credentials')) {
        errorType = 'invalid_credentials';
        errorMessage = 'Email o contraseña incorrectos';
        _recordFailedAttempt(email);
      } else if (e.toString().contains('Email not confirmed')) {
        errorType = 'email_not_confirmed';
        errorMessage = 'Email no confirmado';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorType = 'network_error';
        errorMessage = 'Error de conexión';
      } else if (e.toString().contains('rate limit')) {
        errorType = 'rate_limited';
        errorMessage = 'Demasiados intentos';
        _recordFailedAttempt(email);
      }
      
      return {
        'valid': false,
        'message': errorMessage,
        'type': errorType,
        'error': kDebugMode ? e.toString() : null,
        'remaining_attempts': getLoginAttemptStatus(email)['remaining_attempts'],
      };
    }
  }

  // ✅ resetPassword con validación
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        return {
          'success': false,
          'error': emailError,
          'code': 'INVALID_EMAIL',
        };
      }

      AppLogger.d('📧 Solicitando reset de contraseña para: $email');
      
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterdemo://reset-password',
      );

      AppLogger.d('✅ Email de recuperación enviado');
      return {
        'success': true,
        'message': 'Email de recuperación enviado. Revisa tu bandeja.',
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('❌ Error enviando email de recuperación: $e');
      
      String errorMessage;
      String errorCode = 'UNKNOWN_ERROR';
      
      if (e.toString().contains('rate limit') || e.toString().contains('too many requests')) {
        errorMessage = 'Demasiados intentos. Espera unos minutos.';
        errorCode = 'RATE_LIMITED';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
        errorCode = 'NETWORK_ERROR';
      } else if (e.toString().contains('user not found')) {
        errorMessage = 'No existe una cuenta con este email';
        errorCode = 'USER_NOT_FOUND';
      } else {
        errorMessage = 'Error enviando email de recuperación';
        errorCode = 'EMAIL_SEND_FAILED';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'code': errorCode,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ resendEmailVerification con límite
  Future<Map<String, dynamic>> resendEmailVerification(String email) async {
    try {
      final emailError = AuthValidator.validateEmail(email);
      if (emailError != null) {
        return {
          'success': false,
          'error': emailError,
          'code': 'INVALID_EMAIL',
        };
      }

      AppLogger.d('📧 Reenviando email de verificación para: $email');
      
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
      
      AppLogger.d('✅ Email de verificación reenviado');
      return {
        'success': true,
        'message': 'Email de verificación reenviado. Revisa tu bandeja.',
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('❌ Error reenviando email de verificación: $e');
      
      String errorMessage;
      String errorCode = 'UNKNOWN_ERROR';
      
      if (e.toString().contains('rate limit')) {
        errorMessage = 'Demasiados intentos. Espera unos minutos.';
        errorCode = 'RATE_LIMITED';
      } else if (e.toString().contains('user not found')) {
        errorMessage = 'No existe una cuenta con este email';
        errorCode = 'USER_NOT_FOUND';
      } else {
        errorMessage = 'Error reenviando email: ${e.toString()}';
        errorCode = 'EMAIL_SEND_FAILED';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'code': errorCode,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ✅ refreshSessionIfNeeded
  Future<void> refreshSessionIfNeeded() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;
      
      final expiresAt = session.expiresAt;
      if (expiresAt == null) return;
      
      final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final timeUntilExpiry = expiresAtDateTime.difference(DateTime.now());
      
      if (timeUntilExpiry.inMinutes < 5) {
        AppLogger.d('🔄 Refrescando sesión que expira en ${timeUntilExpiry.inMinutes} minutos');
        
        final refreshedSession = await _supabase.auth.refreshSession();
        if (refreshedSession.session != null) {
          AppLogger.d('✅ Sesión refrescada exitosamente');
        }
      }
    } catch (e) {
      AppLogger.e('❌ Error refrescando sesión: $e');
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isLoading', _isLoading));
    properties.add(StringProperty('error', _error));
    properties.add(DiagnosticsProperty<AppUser?>('currentUser', _currentUser));
    properties.add(StringProperty('pendingVerificationEmail', _pendingVerificationEmail));
    properties.add(DiagnosticsProperty<int>('loginAttemptsCount', _loginAttempts.length));
    properties.add(DiagnosticsProperty<bool>('isLoggedIn', isLoggedIn));
  }
}

// ✅ CLASE PARA MANEJAR INTENTOS DE LOGIN
class LoginAttempt {
  final String email;
  int failedCount;
  DateTime lastAttempt;
  bool isLockedOut;
  DateTime? lockoutTime;

  LoginAttempt({
    required this.email,
    this.failedCount = 0,
    DateTime? lastAttempt,
    this.isLockedOut = false,
    this.lockoutTime,
  }) : lastAttempt = lastAttempt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'failed_count': failedCount,
      'last_attempt': lastAttempt.toIso8601String(),
      'is_locked_out': isLockedOut,
      'lockout_time': lockoutTime?.toIso8601String(),
    };
  }
}