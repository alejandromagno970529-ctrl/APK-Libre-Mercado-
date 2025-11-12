// lib/main.dart - VERSIÓN CORREGIDA CON PRODUCT PROVIDER ACTUALIZADO
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
import 'services/image_upload_service.dart'; // ✅ IMPORTACIÓN AGREGADA
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/product/add_product_screen.dart';
import 'screens/product/edit_product_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/my_products_screen.dart';
import 'screens/product/product_search_screen.dart';
import 'screens/product/category_products_screen.dart';
import 'screens/stories/create_story_screen.dart';
import 'screens/stories/story_view_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/reputation/ratings_list_screen.dart';
import 'screens/reputation/rating_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/map_screen.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const MyApp());
}

Future<void> initializeSupabase() async {
  try {
    const supabaseUrl = 'https://lgbwswlauddlwwrsjest.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYndzd2xhdWRkbHd3cnNqZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNjI4NTUsImV4cCI6MjA3NjYzODg1NX0.VneAE4Ke9Udq6og75WVFwlLnYcJCfd9J-MTXX4rDk8s';
    
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    AppLogger.d('✅ Supabase inicializado');
  } catch (e) {
    AppLogger.e('❌ Error inicializando Supabase: $e');
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
        // ✅ CORREGIDO: ProductProvider ahora recibe 2 argumentos
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(
            Supabase.instance.client,
            ImageUploadService(Supabase.instance.client), // ✅ SEGUNDO ARGUMENTO AGREGADO
          ),
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
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/create-story': (context) => const CreateStoryScreen(),
          '/products': (context) => const ProductListScreen(),
          '/my-products': (context) => const MyProductsScreen(),
          '/search': (context) => const ProductSearchScreen(),
          '/catalog': (context) => const CatalogScreen(),
          '/map': (context) => const MapScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/chats': (context) => const ChatListScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/ratings':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('userId')) {
                return MaterialPageRoute(
                  builder: (context) => RatingsListScreen(
                    userId: args['userId'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              );
            
            case '/story-view':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && 
                  args.containsKey('stories') && 
                  args.containsKey('initialIndex') &&
                  args.containsKey('isOwner')) {
                return MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: args['stories'],
                    initialIndex: args['initialIndex'],
                    isOwner: args['isOwner'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            
            case '/product-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('product')) {
                return MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    product: args['product'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              );
            
            case '/edit-product':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('product')) {
                return MaterialPageRoute(
                  builder: (context) => EditProductScreen(
                    product: args['product'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const MyProductsScreen(),
              );
            
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && 
                  args.containsKey('chatId') && 
                  args.containsKey('otherUserId') &&
                  args.containsKey('productId')) {
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: args['chatId'],
                    otherUserId: args['otherUserId'],
                    productId: args['productId'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const ChatListScreen(),
              );
            
            case '/rate-user':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && 
                  args.containsKey('toUserId') &&
                  args.containsKey('userName')) {
                return MaterialPageRoute(
                  builder: (context) => RatingScreen(
                    toUserId: args['toUserId'],
                    userName: args['userName'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              );
            
            case '/category-products':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('category')) {
                return MaterialPageRoute(
                  builder: (context) => CategoryProductsScreen(
                    category: args['category'],
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
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
    Future.delayed(const Duration(milliseconds: 500), _initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
    } catch (e) {
      AppLogger.e('Error inicializando app: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.3),
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
            const SizedBox(height: 30),
            
            const Text(
              'Libre Mercado', 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            
            const Text(
              'Mercado Libre Cubano', 
              style: TextStyle(
                color: Colors.grey, 
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ CORREGIDO CRÍTICO: AuthStateHandler con Consumer para reactividad
class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // ✅ DEBUG: Verificar estado de autenticación
        print('🔄 AuthStateHandler - isLoggedIn: ${authProvider.isLoggedIn}');
        print('🔄 AuthStateHandler - isLoading: ${authProvider.isLoading}');
        print('🔄 AuthStateHandler - currentUser: ${authProvider.currentUser?.email}');
        
        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verificando sesión...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // ✅ DECISIÓN CRÍTICA: Redirigir basado en estado de autenticación
        if (authProvider.isLoggedIn) {
          print('🎯 Redirigiendo a HomeScreen');
          // ✅ Forzar una reconstrucción limpia del HomeScreen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🏠 Navegación completada a HomeScreen');
          });
          return const HomeScreen();
        } else {
          print('🎯 Redirigiendo a LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}

/// Servicio global para manejo de errores y notificaciones
class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void handleAuthError(BuildContext context, String error) {
    if (error == 'email_not_confirmed') {
      showWarningSnackBar(
        context, 
        'Por favor verifica tu email antes de iniciar sesión. Revisa tu bandeja de entrada.'
      );
    } else if (error.contains('register_success_but_email_not_sent')) {
      showWarningSnackBar(
        context,
        'Cuenta creada pero no se pudo enviar el email de verificación. Contacta con soporte.'
      );
    } else {
      showErrorSnackBar(context, error);
    }
  }

  static void handleNetworkError(BuildContext context) {
    showErrorSnackBar(
      context,
      'Error de conexión. Verifica tu conexión a internet e intenta nuevamente.'
    );
  }
}

/// Utilidades para navegación global
class NavigationHelper {
  static void navigateToSignup(BuildContext context) {
    Navigator.pushNamed(context, '/signup');
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/login', 
      (route) => false
    );
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/home', 
      (route) => false
    );
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  static void navigateToProductDetail(BuildContext context, dynamic product) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'product': product},
    );
  }

  static void navigateToChat(BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String productId,
  }) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'productId': productId,
      },
    );
  }
}

/// Clase para manejo de estado de la aplicación
class AppStateManager {
  static bool get isDebugMode {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  static void logAppState(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    AppLogger.d('''
📱 APP STATE:
   - User: ${authProvider.currentUser?.email ?? 'No autenticado'}
   - Logged In: ${authProvider.isLoggedIn}
   - User ID: ${authProvider.userId ?? 'N/A'}
   - Debug Mode: $isDebugMode
''');
  }

  static Future<bool> checkActiveSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session != null;
    } catch (e) {
      AppLogger.e('Error verificando sesión: $e');
      return false;
    }
  }
}

/// Extensiones de utilidad para BuildContext
extension ContextExtensions on BuildContext {
  void goToSignup() => NavigationHelper.navigateToSignup(this);
  void goToLogin() => NavigationHelper.navigateToLogin(this);
  void goToHome() => NavigationHelper.navigateToHome(this);
  void goToProfile() => NavigationHelper.navigateToProfile(this);

  AuthProvider get authProvider => Provider.of<AuthProvider>(this, listen: false);
  ProductProvider get productProvider => Provider.of<ProductProvider>(this, listen: false);
  ChatProvider get chatProvider => Provider.of<ChatProvider>(this, listen: false);

  void showError(String message) => ErrorHandler.showErrorSnackBar(this, message);
  void showSuccess(String message) => ErrorHandler.showSuccessSnackBar(this, message);
  void showWarning(String message) => ErrorHandler.showWarningSnackBar(this, message);
  void handleAuthError(String error) => ErrorHandler.handleAuthError(this, error);
}