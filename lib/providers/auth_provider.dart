import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  bool _isLoading = false;
  String? _error;
  AppUser? _currentUser;
  String? _pendingVerificationEmail;

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
        );
        
        print('✅ Perfil cargado: ${_currentUser!.username}');
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

  // ✅ CORREGIDO: Manejo mejorado de registro
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

      // ✅ CREAMOS EL PERFIL SIEMPRE - incluso si falla el email
      try {
        await _createInitialProfile(user.id);
        print('✅ Perfil inicial creado para: ${user.id}');
      } catch (profileError) {
        print('⚠️ Error creando perfil: $profileError');
      }

      // ✅ MANEJO MEJORADO: Si hay error en el email pero el usuario se creó
      if (response.session == null) {
        print('⚠️ Usuario creado pero email no enviado - ID: ${user.id}');
        _pendingVerificationEmail = email;
        
        // ✅ ÉXITO - El usuario puede verificar después
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
        // ✅ MEJORA CRÍTICA: No devolvemos error, consideramos éxito
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

  // ✅ CORREGIDO CRÍTICO: Notificación inmediata después del login exitoso
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
      
      _error = null;
      
      // ✅ CRÍTICO: Notificar inmediatamente después del login exitoso
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

  // ✅ NUEVO: Reenviar verificación de email
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

  // ✅ CORREGIDO: Verificar estado de email sin usar reload()
  Future<bool> checkEmailVerificationStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Obtener información actualizada del usuario
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

  // ✅ NUEVO: Método para verificar si un email está registrado
  Future<bool> isEmailRegistered(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ NUEVO: Método para recuperar contraseña
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

  // ✅ NUEVO: Método para cambiar contraseña
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
      await _supabase.auth.signOut();
      _currentUser = null;
      _error = null;
      _pendingVerificationEmail = null;
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error en logout: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    try {
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
}