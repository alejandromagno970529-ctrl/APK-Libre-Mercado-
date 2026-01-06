// lib/screens/auth/signup_screen.dart - VERSIÓN MEJORADA CON VALIDACIÓN
// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/utils/auth_validator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _passwordStrengthText;
  Color? _passwordStrengthColor;
  double _passwordStrength = 0.0;

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrengthText = null;
        _passwordStrengthColor = null;
        _passwordStrength = 0.0;
      });
      return;
    }
    
    final strength = AuthValidator.calculatePasswordStrength(password);
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = AuthValidator.getPasswordStrengthText(strength);
      _passwordStrengthColor = AuthValidator.getPasswordStrengthColor(strength);
    });
  }

  void _handleSignupResult(BuildContext context, Map<String, dynamic> result) {
    if (result['success'] == true) {
      if (result['requires_email_verification'] == true) {
        _showEmailVerificationDialog(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cuenta creada exitosamente. Ya puedes iniciar sesión.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context, 
              '/login', 
              (route) => false
            );
          }
        });
      }
    } else {
      String errorMessage = result['error'] ?? 'Error desconocido';
      Color backgroundColor = Colors.red;
      IconData icon = Icons.error;
      
      if (result['code'] == 'EMAIL_ALREADY_EXISTS') {
        errorMessage = 'Este email ya está registrado';
      } else if (result['code'] == 'WEAK_PASSWORD') {
        errorMessage = 'La contraseña es muy débil';
      } else if (result['code'] == 'NETWORK_ERROR') {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (result['code'] == 'RATE_LIMITED') {
        errorMessage = 'Demasiados intentos. Espera unos minutos.';
        backgroundColor = Colors.orange;
        icon = Icons.warning;
      } else if (result['code'] == 'EMAIL_SEND_FAILED') {
        errorMessage = 'Cuenta creada pero no se pudo enviar el email de verificación. Contacta con soporte.';
        backgroundColor = Colors.orange;
        icon = Icons.warning;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showEmailVerificationDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📧 Verificación de Email Requerida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu cuenta ha sido creada exitosamente.'),
            const SizedBox(height: 10),
            const Text('Para activar tu cuenta, debes verificar tu email.'),
            const SizedBox(height: 10),
            Text('Hemos enviado un email a: ${_emailController.text}'),
            const SizedBox(height: 10),
            const Text('Revisa tu bandeja de entrada y la carpeta de spam.'),
            const SizedBox(height: 10),
            if (result['email_sent'] == false)
              const Text(
                '⚠️ No se pudo enviar el email automáticamente. Contacta con soporte.',
                style: TextStyle(color: Colors.orange),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            child: const Text('Ir a Login'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final resendResult = await authProvider.resendEmailVerification(
                _emailController.text.trim()
              );
              
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              
              if (resendResult['success'] == true) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Email de verificación reenviado.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: ${resendResult['error']}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
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
                const SizedBox(height: 16),
                const Text(
                  'Crear Nueva Cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Únete a la comunidad de Libre Mercado',
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
                    
                    // Barra de fortaleza de contraseña
                    if (_passwordStrength > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _passwordStrengthColor ?? Colors.grey
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _passwordStrengthText ?? '',
                                  style: TextStyle(
                                    color: _passwordStrengthColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Requisitos: 8+ caracteres, mayúscula, minúscula, número, especial',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) => AuthValidator.validateConfirmPassword(
                    _passwordController.text, 
                    value
                  ),
                  onChanged: (_) {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Botón de registro
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || !(_formKey.currentState?.validate() ?? false))
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSubmitting = true);
                            
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final result = await authProvider.signUp(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            
                            setState(() => _isSubmitting = false);
                            // ignore: use_build_context_synchronously
                            _handleSignupResult(context, result);
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
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CREAR CUENTA',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Enlace a login
                TextButton(
                  onPressed: _isSubmitting ? null : () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia Sesión',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Información adicional
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Al crear una cuenta aceptas nuestros Términos de Servicio y Política de Privacidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}