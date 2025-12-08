import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';

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
              // ignore: prefer_const_constructors
              Text('⚙️ Config Supabase:'),
              Text('   - URL: ${diagnostic['supabase_config']?['url']}'),
              Text('   - Key length: ${diagnostic['supabase_config']?['anon_key_length']}'),
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
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa tu email')),
                );
                return;
              }
              
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final error = await authProvider.resetPassword(email);
              
              if (error == null) {
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
                    content: Text('❌ Error: $error'),
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
                
                // ✅ ACTUALIZADO: Mismo icono que SplashScreen (bolso)
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
                
                // Títulos
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Email inválido. Ejemplo: usuario@dominio.com';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo contraseña
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botón login
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // ignore: avoid_print
                                print('📱 Iniciando proceso de login...');
                                
                                final error = await authProvider.signIn(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                                
                                if (error != null && mounted) {
                                  if (error == 'email_not_confirmed') {
                                    // ignore: use_build_context_synchronously
                                    _showEmailNotVerifiedDialog(context);
                                  } else {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Botón recuperar contraseña
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
                    onPressed: () {
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

  void _showEmailNotVerifiedDialog(BuildContext context) {
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
              final error = await authProvider.resendEmailVerification(_emailController.text.trim());
              
              if (error == null) {
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
                    content: Text('❌ Error: $error'),
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}