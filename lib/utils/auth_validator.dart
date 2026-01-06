// lib/utils/auth_validator.dart - VALIDADOR UNIFICADO 
import 'package:flutter/material.dart';

class AuthValidator {
  // ✅ REGEX MEJORADOS
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );
  
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  
  static final RegExp _usernameRegex = RegExp(
    r'^[a-zA-Z0-9_]{3,30}$',
  );
  
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[0-9]{7,15}$',
  );

  // ✅ VALIDACIÓN DE EMAIL (UNIFICADA)
  static String? validateEmail(String? email, {bool isRequired = true}) {
    if (!isRequired && (email == null || email.isEmpty)) return null;
    
    if (email == null || email.isEmpty) {
      return 'El email es requerido';
    }
    
    final trimmedEmail = email.trim();
    
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'Email inválido. Ejemplo: usuario@dominio.com';
    }
    
    // Evitar emails temporales
    if (trimmedEmail.contains('temp-') || 
        trimmedEmail.contains('@temp.com') ||
        trimmedEmail.contains('@example.com')) {
      return 'Email no permitido';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE CONTRASEÑA FUERTE
  static String? validatePassword(String? password, {bool isRequired = true}) {
    if (!isRequired && (password == null || password.isEmpty)) return null;
    
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (password.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    
    if (!_passwordRegex.hasMatch(password)) {
      return 'Debe contener mayúsculas, minúsculas, números y un carácter especial (@\$!%*?&)';
    }
    
    // Verificar contraseñas comunes (opcional)
    final commonPasswords = [
      '12345678', 'password', 'contraseña', 'admin123', 'qwerty123'
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'Contraseña demasiado común';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE CONFIRMACIÓN DE CONTRASEÑA
  static String? validateConfirmPassword(
    String? password, 
    String? confirmPassword,
    {bool isRequired = true}
  ) {
    if (!isRequired && (confirmPassword == null || confirmPassword.isEmpty)) {
      return null;
    }
    
    final passwordError = validatePassword(password, isRequired: isRequired);
    if (passwordError != null) return passwordError;
    
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }
    
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE NOMBRE DE USUARIO
  static String? validateUsername(String? username, {bool isRequired = true}) {
    if (!isRequired && (username == null || username.isEmpty)) return null;
    
    if (username == null || username.isEmpty) {
      return 'El nombre de usuario es requerido';
    }
    
    final trimmedUsername = username.trim();
    
    if (trimmedUsername.length < 3) {
      return 'Mínimo 3 caracteres';
    }
    
    if (trimmedUsername.length > 30) {
      return 'Máximo 30 caracteres';
    }
    
    if (!_usernameRegex.hasMatch(trimmedUsername)) {
      return 'Solo letras, números y guiones bajos (_)';
    }
    
    // Nombres reservados
    final reservedNames = [
      'admin', 'administrador', 'root', 'system', 'support', 
      'soporte', 'null', 'undefined', 'test', 'user'
    ];
    
    if (reservedNames.contains(trimmedUsername.toLowerCase())) {
      return 'Nombre de usuario no disponible';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE TELÉFONO
  static String? validatePhone(String? phone, {bool isRequired = false}) {
    if (!isRequired && (phone == null || phone.isEmpty)) return null;
    
    if (phone == null || phone.isEmpty) {
      return isRequired ? 'El teléfono es requerido' : null;
    }
    
    final cleanedPhone = phone.replaceAll(RegExp(r'[-\s()]'), '');
    
    if (!_phoneRegex.hasMatch(cleanedPhone)) {
      return 'Formato inválido. Ejemplo: +5351234567';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE BIO
  static String? validateBio(String? bio, {int maxLength = 500}) {
    if (bio == null || bio.isEmpty) return null;
    
    if (bio.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }
    
    // Evitar contenido malicioso (básico)
    final maliciousPatterns = [
      '<script', 'javascript:', 'onload=', 'onerror=', 
      'data:text/html', 'eval(', 'document.cookie'
    ];
    
    for (final pattern in maliciousPatterns) {
      if (bio.toLowerCase().contains(pattern)) {
        return 'Contenido no permitido';
      }
    }
    
    return null;
  }

  // ✅ VALIDACIÓN DE CÓDIGO DE VERIFICACIÓN
  static String? validateVerificationCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'El código es requerido';
    }
    
    if (code.length != 6) {
      return 'El código debe tener 6 dígitos';
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      return 'Solo números del 0 al 9';
    }
    
    return null;
  }

  // ✅ VALIDACIÓN COMPUESTA PARA REGISTRO
  static Map<String, String?> validateRegistration({
    required String email,
    required String password,
    required String confirmPassword,
    String? username,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
      'confirmPassword': validateConfirmPassword(password, confirmPassword),
      'username': validateUsername(username, isRequired: false),
    };
  }

  // ✅ VALIDACIÓN COMPUESTA PARA LOGIN
  static Map<String, String?> validateLogin({
    required String email,
    required String password,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
    };
  }

  // ✅ SANITIZAR INPUTS (PREVENCIÓN DE INYECCIÓN)
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control chars
        .replaceAll(RegExp(r'\s{2,}'), ' '); // Multiple spaces to single
  }

  // ✅ CALCULAR FORTALEZA DE CONTRASEÑA
  static double calculatePasswordStrength(String password) {
    double strength = 0.0;
    
    // Longitud
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    
    // Diversidad de caracteres
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) strength += 0.2;
    
    return strength.clamp(0.0, 1.0);
  }

  // ✅ OBTENER COLOR DE FORTALEZA
  static Color getPasswordStrengthColor(double strength) {
    if (strength < 0.4) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  // ✅ OBTENER TEXTO DE FORTALEZA
  static String getPasswordStrengthText(double strength) {
    if (strength < 0.4) return 'Débil';
    if (strength < 0.7) return 'Media';
    return 'Fuerte';
  }

  // ✅ VALIDAR DOCUMENTO DE VERIFICACIÓN
  static String? validateDocumentUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'El documento es requerido';
    }
    
    // Verificar que sea una URL de Supabase Storage
    if (!url.contains('storage/v1/object/public/verifications/')) {
      return 'Formato de documento inválido';
    }
    
    // Verificar extensión
    final validExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
    final hasValidExtension = validExtensions.any((ext) => url.toLowerCase().endsWith(ext));
    
    if (!hasValidExtension) {
      return 'Solo JPG, PNG o PDF (máx. 5MB)';
    }
    
    return null;
  }

  // ✅ VALIDAR DATOS DE VERIFICACIÓN
  static Map<String, String?> validateVerificationData({
    required String fullName,
    required String nationalId,
    required String address,
    required String documentUrl,
  }) {
    return {
      'fullName': fullName.isEmpty ? 'Nombre completo requerido' : null,
      'nationalId': nationalId.isEmpty ? 'Identificación requerida' : null,
      'address': address.isEmpty ? 'Dirección requerida' : null,
      'documentUrl': validateDocumentUrl(documentUrl),
    };
  }
}