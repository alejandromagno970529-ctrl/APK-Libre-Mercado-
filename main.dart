import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/reputation_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/reputation/ratings_list_screen.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.d('🚀 Iniciando aplicación Libre Mercado...');
  try {
    AppLogger.d('🔗 Conectando con Supabase...');
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    
    AppLogger.d('✅ Supabase inicializado correctamente');
    
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    AppLogger.d('🔐 Estado de sesión: ${session != null ? "ACTIVA" : "INACTIVA"}');
    
  } catch (e) {
    AppLogger.e('❌ Error crítico inicializando Supabase', e);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => ReputationProvider(Supabase.instance.client),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          primarySwatch: Colors.amber,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            elevation: 2,
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          cardTheme: CardThemeData( // ✅ CORREGIDO: Usar CardThemeData
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          // ✅ AGREGAR NUEVAS RUTAS PARA PERFILES Y REPUTACIÓN
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/ratings': (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            return RatingsListScreen(userId: authProvider.userId ?? '');
          },
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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      AppLogger.d('🔄 Inicializando aplicación...');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authProvider = Provider.of<AuthProvider>(
        context,
        listen: false
      );
      
      await authProvider.initialize();
      AppLogger.d('✅ AuthProvider inicializado');
      
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false
      );
      await productProvider.fetchProducts();
      AppLogger.d('✅ ProductProvider inicializado');
      
    } catch (e) {
      AppLogger.e('❌ Error durante inicialización', e);
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        AppLogger.d('🔄 AuthWrapper - LoggedIn: ${authProvider.isLoggedIn}');
        AppLogger.d('🔄 AuthWrapper - CurrentUser: ${authProvider.currentUser?.username}');
        
        if (authProvider.isLoading) {
          return const SplashScreen();
        }
        
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 60,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 30),
            
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 1000),
              child: Column(
                children: [
                  const Text(
                    'Libre Mercado',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appSlogan,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Text(
                      authProvider.isLoggedIn
                          ? 'Cargando tu perfil...'
                          : 'Inicializando...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text(
              'v${AppConstants.appVersion}',
              style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}