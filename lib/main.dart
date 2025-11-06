import 'dart:typed_data'; // ✅ AÑADIR IMPORTACIÓN PARA Uint8List

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/story_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/reputation_provider.dart';
import 'providers/verification_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product/add_product_screen.dart';
import 'screens/stories/create_story_screen.dart';
import 'screens/stories/story_editor_screen.dart';
import 'screens/stories/story_view_screen.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';
import 'services/supabase_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INICIALIZAR SUPABASE CON MANEJO DE ERRORES MEJORADO
  await initializeSupabase();
  
  runApp(const MyApp());
}

// ✅ INICIALIZACIÓN DE SUPABASE - CON MANEJO ROBUSTO DE ERRORES
Future<void> initializeSupabase() async {
  try {
    // ✅ REEMPLAZA CON TUS CREDENCIALES REALES
    const supabaseUrl = 'https://lgbwswlauddlwwrsjest.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYndzd2xhdWRkbHd3cnNqZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNjI4NTUsImV4cCI6MjA3NjYzODg1NX0.VneAE4Ke9Udq6og75WVFwlLnYcJCfd9J-MTXX4rDk8s';
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    AppLogger.d('✅ Supabase inicializado correctamente');
    
    // ✅ VERIFICAR CONEXIÓN CON TIMEOUT
    try {
      final supabaseCheck = SupabaseCheck(Supabase.instance.client);
      final connectionResult = await supabaseCheck.checkConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'success': false, 'error': 'Timeout'},
      );
      
      if (connectionResult['success'] == true) {
        AppLogger.d('✅ Conexión a Supabase verificada');
      } else {
        AppLogger.e('⚠️ Advertencia de conexión: ${connectionResult['error']}');
        // No bloquear la app - continuar en modo offline
      }
    } catch (e) {
      AppLogger.e('⚠️ No se pudo verificar conexión: $e');
      // Continuar en modo offline
    }
    
  } catch (e) {
    AppLogger.e('❌ Error inicializando Supabase: $e');
    // La app puede continuar incluso si Supabase falla
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<StoryProvider>(
          create: (_) => StoryProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<AgreementProvider>(
          create: (_) => AgreementProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<ReputationProvider>(
          create: (_) => ReputationProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider<VerificationProvider>(
          create: (_) => VerificationProvider(Supabase.instance.client),
        ),
      ],
      child: MaterialApp(
        title: 'Libre Mercado',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/create-story': (context) => const CreateStoryScreen(),
          // ❌ QUITAMOS story-editor y story-view de las rutas fijas
          // porque requieren parámetros obligatorios
        },
        // ✅ MANEJAR RUTAS CON PARÁMETROS - CORREGIDO
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/story-editor':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('imageBytes')) {
                // ✅ CONVERTIR List<int> a Uint8List
                final imageBytes = args['imageBytes'] as List<int>;
                final uint8list = Uint8List.fromList(imageBytes);
                
                return MaterialPageRoute(
                  builder: (context) => StoryEditorScreen(
                    imageBytes: uint8list, // ✅ AHORA ES Uint8List
                    // ❌ QUITAMOS onStoryCreated porque no es parámetro válido
                  ),
                );
              }
              // Si no hay parámetros, redirigir a crear historia
              return MaterialPageRoute(
                builder: (context) => const CreateStoryScreen(),
              );
            
            case '/story-view':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('story')) {
                return MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    story: args['story'],
                  ),
                );
              }
              // Si no hay story, redirigir a home
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            
            default:
              return MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ Usar un delay para evitar problemas de inicialización
    Future.delayed(const Duration(milliseconds: 500), _initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
    } catch (e) {
      AppLogger.e('Error inicializando app: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? const SplashScreen() : const AuthStateHandler();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, 
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.shopping_bag, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 30),
            const Text(
              'Libre Mercado', 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mercado Libre Cubano', 
              style: TextStyle(
                color: Colors.grey, 
                fontSize: 16
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
            ),
          ],
        ),
      ),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // ✅ Mostrar pantalla de login si hay problemas de conexión
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator()
        ),
      );
    }
    
    // ✅ Si hay un usuario en caché, ir a home, sino a login
    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}