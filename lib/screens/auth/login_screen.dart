// lib/screens/auth/login_screen.dart - VERSIÓN MEJORADA CON VALIDACIÓN
// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/utils/auth_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _showDebugOptions = false;
  bool _isSubmitting = false;
  String? _passwordStrengthText;
  Color? _passwordStrengthColor;

  void _showAuthDiagnostic(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final diagnostic = await authProvider.debugAuthState();
    
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Diagnóstico de Autenticación'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📧 Email ingresado: ${_emailController.text}'),
              const SizedBox(height: 10),
              Text('🕐 Timestamp: ${diagnostic['timestamp']}'),
              const SizedBox(height: 10),
              Text('🔐 Sesión Supabase: ${diagnostic['has_session']}'),
              Text('👤 Usuario Supabase: ${diagnostic['has_user']}'),
              Text('📨 Email usuario: ${diagnostic['user_email']}'),
              Text('🆔 ID usuario: ${diagnostic['user_id']}'),
              Text('✅ Email confirmado: ${diagnostic['email_confirmed']}'),
              const SizedBox(height: 10),
              Text('🔧 AuthProvider - LoggedIn: ${diagnostic['auth_provider_logged_in']}'),
              Text('🔧 AuthProvider - CurrentUser: ${diagnostic['auth_provider_current_user']}'),
              const SizedBox(height: 10),
              Text('📊 Intentos de login: ${diagnostic['login_attempts_status']}'),
              if (diagnostic['error'] != null) ...[
                const SizedBox(height: 10),
                Text('❌ Error: ${diagnostic['error']}', 
                  style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                final credentialCheck = await authProvider.verifyCredentials(
                  _emailController.text, 
                  _passwordController.text
                );
                
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                _showCredentialCheckResult(context, credentialCheck);
              }
            },
            child: const Text('Verificar Credenciales'),
          ),
        ],
      ),
    );
  }

  void _showCredentialCheckResult(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['valid'] == true ? '✅ Credenciales Válidas' : '❌ Problema con Credenciales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultado: ${result['message']}'),
            if (result['type'] != null) Text('Tipo: ${result['type']}'),
            if (result['email_confirmed'] != null) 
              Text('Email confirmado: ${result['email_confirmed']}'),
            if (result['user_id'] != null) Text('User ID: ${result['user_id']}'),
            if (result['remaining_attempts'] != null) 
              Text('Intentos restantes: ${result['remaining_attempts']}'),
            if (result['error'] != null) 
              Text('Error técnico: ${result['error']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu email para recibir un enlace de recuperación:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) => AuthValidator.validateEmail(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final emailError = AuthValidator.validateEmail(email);
              
              if (emailError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(emailError)),
                );
                return;
              }
              
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final result = await authProvider.resetPassword(email);
              
              if (result['success'] == true) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Email de recuperación enviado. Revisa tu bandeja.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrengthText = null;
        _passwordStrengthColor = null;
      });
      return;
    }
    
    final strength = AuthValidator.calculatePasswordStrength(password);
    setState(() {
      _passwordStrengthText = AuthValidator.getPasswordStrengthText(strength);
      _passwordStrengthColor = AuthValidator.getPasswordStrengthColor(strength);
    });
  }

  void _showEmailNotVerifiedDialog(BuildContext context, {String? userId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📧 Email No Verificado'),
        content: const Text(
          'Tu email no ha sido verificado. '
          'Revisa tu bandeja de entrada y spam para el email de verificación. '
          '¿Quieres que reenviemos el email de verificación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final result = await authProvider.resendEmailVerification(_emailController.text.trim());
              
              if (result['success'] == true) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Email de verificación reenviado. Revisa tu bandeja.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reenviar Email'),
          ),
        ],
      ),
    );
  }

  void _handleLoginError(BuildContext context, Map<String, dynamic> result) {
    if (result['locked'] == true) {
      _showAccountLockedDialog(context, result);
    } else if (result['code'] == 'EMAIL_NOT_CONFIRMED') {
      _showEmailNotVerifiedDialog(context, userId: result['user_id']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error desconocido'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: result['remaining_attempts'] != null 
              ? SnackBarAction(
                  label: 'Intentos: ${result['remaining_attempts']}',
                  onPressed: () {},
                  textColor: Colors.white,
                )
              : null,
        ),
      );
    }
  }

  void _showAccountLockedDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔒 Cuenta Bloqueada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demasiados intentos fallidos de inicio de sesión.'),
            const SizedBox(height: 10),
            // ignore: prefer_const_constructors
            Text('Tu cuenta está bloqueada temporalmente por seguridad.'),
            const SizedBox(height: 10),
            // ignore: prefer_const_constructors
            Text('Puedes intentar nuevamente en:'),
            Text('⏰ ${result['unlock_in_minutes']} minutos', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                Container(
                  width: 120, 
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag, 
                    size: 60, 
                    color: Colors.black
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Libre Mercado',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Compra y vende de forma libre',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => AuthValidator.validateEmail(value),
                  onChanged: (_) {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Campo contraseña
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) => AuthValidator.validatePassword(value),
                      onChanged: (value) {
                        _checkPasswordStrength(value);
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() {});
                        }
                      },
                    ),
                    
                    // Indicador de fortaleza de contraseña
                    if (_passwordStrengthText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: _passwordStrengthColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _passwordStrengthText!,
                              style: TextStyle(
                                color: _passwordStrengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón login
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final isLoading = authProvider.isLoading || _isSubmitting;

                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isSubmitting = true);
                                
                                final result = await authProvider.signIn(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                                
                                setState(() => _isSubmitting = false);
                                
                                if (result['success'] == true) {
                                  // Login exitoso - El provider ya navega automáticamente
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    // ignore: prefer_const_constructors
                                    SnackBar(
                                      content: const Text('✅ Login exitoso'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  // ignore: use_build_context_synchronously
                                  _handleLoginError(context, result);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'INICIAR SESIÓN',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () => _showResetPasswordDialog(context),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        
                        if (_showDebugOptions) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => _showAuthDiagnostic(context),
                            child: const Text(
                              '🔍 Diagnóstico Auth',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Botón registro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '¿No tienes cuenta? Crear cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Botón para mostrar/ocultar opciones de debug
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDebugOptions = !_showDebugOptions;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _showDebugOptions ? '▲ Ocultar diagnóstico' : '▼ Mostrar diagnóstico',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}