// lib/main.dart - VERSIÓN COMPLETAMENTE CORREGIDA
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
import 'providers/store_provider.dart';
import 'services/image_upload_service.dart';

// Importaciones de pantallas
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/product/add_product_screen.dart';
import 'screens/product/edit_product_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/my_products_screen.dart';
import 'screens/product/category_products_screen.dart';
import 'screens/product/product_search_screen.dart';
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
import 'screens/store_screen.dart';
import 'screens/edit_store_screen.dart';

import 'theme/app_theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const MyApp());
}

Future<void> initializeSupabase() async {
  try {
    const supabaseUrl = '';
    const supabaseAnonKey = '';
    
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
        ChangeNotifierProvider(create: (_) => AuthProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ProductProvider(
          Supabase.instance.client,
          ImageUploadService(Supabase.instance.client),
        )),
        ChangeNotifierProvider(create: (_) => StoryProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ChatProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => AgreementProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ReputationProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => VerificationProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => StoreProvider(Supabase.instance.client)),
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
          '/store': (context) => const StoreScreen(),
          '/edit-store': (context) => const EditStoreScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/ratings':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('userId')) {
                return MaterialPageRoute(
                  builder: (context) => RatingsListScreen(userId: args['userId']),
                );
              }
              return MaterialPageRoute(builder: (context) => const ProfileScreen());
            
            case '/story-view':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('stories') && args.containsKey('initialIndex') && args.containsKey('isOwner')) {
                return MaterialPageRoute(
                  builder: (context) => StoryViewScreen(
                    stories: args['stories'],
                    initialIndex: args['initialIndex'],
                    isOwner: args['isOwner'],
                  ),
                );
              }
              return MaterialPageRoute(builder: (context) => const HomeScreen());
            
            case '/product-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('product')) {
                return MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: args['product']),
                );
              }
              return MaterialPageRoute(builder: (context) => const ProductListScreen());
            
            case '/edit-product':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('product')) {
                return MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: args['product']),
                );
              }
              return MaterialPageRoute(builder: (context) => const MyProductsScreen());
            
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('chatId') && args.containsKey('otherUserId') && args.containsKey('productId')) {
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: args['chatId'],
                    otherUserId: args['otherUserId'],
                    productId: args['productId'],
                  ),
                );
              }
              return MaterialPageRoute(builder: (context) => const ChatListScreen());
            
            case '/rate-user':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('toUserId') && args.containsKey('userName')) {
                return MaterialPageRoute(
                  builder: (context) => RatingScreen(
                    toUserId: args['toUserId'],
                    userName: args['userName'],
                  ),
                );
              }
              return MaterialPageRoute(builder: (context) => const ProfileScreen());
            
            case '/category-products':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('category')) {
                return MaterialPageRoute(
                  builder: (context) => CategoryProductsScreen(category: args['category']),
                );
              }
              return MaterialPageRoute(builder: (context) => const ProductListScreen());
            
            case '/user-store':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('userId')) {
                return MaterialPageRoute(
                  builder: (context) => StoreScreen(
                    userId: args['userId'],
                    isCurrentUser: args['isCurrentUser'] ?? false,
                  ),
                );
              }
              return MaterialPageRoute(builder: (context) => const StoreScreen());
            
            default:
              return MaterialPageRoute(builder: (context) => const AuthWrapper());
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
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
      await Future.wait([
        authProvider.initialize(),
        productProvider.initialize(),
        storeProvider.fetchAllStores(),
      ]);

      // Registrar storeProvider en productProvider después de la inicialización
      productProvider.registerStoreProvider(storeProvider);
      
      AppLogger.d('✅ Todos los providers inicializados correctamente');
      AppLogger.d('📊 Tiendas cargadas: ${storeProvider.stores.length}');
      
    } catch (e) {
      AppLogger.e('❌ Error inicializando app: $e');
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

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      AppLogger.d('🔍 Verificando estado de autenticación...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      AppLogger.d('📊 Sesión Supabase: ${session != null}');
      AppLogger.d('👤 Usuario Supabase: ${user?.email}');
      AppLogger.d('🔄 Estado AuthProvider: ${authProvider.isLoggedIn}');
      AppLogger.d('🏪 Tiendas cargadas: ${storeProvider.stores.length}');
      
      if (session != null && user != null) {
        AppLogger.d('✅ Sesión activa encontrada - Cargando perfil...');
        await authProvider.loadUserProfile(user.id);
        
        if (storeProvider.stores.isEmpty) {
          AppLogger.d('🔄 Recargando tiendas para usuario autenticado...');
          await storeProvider.fetchAllStores();
        }
      } else {
        AppLogger.d('🔐 No hay sesión activa - Limpiando estado...');
        await authProvider.clearAuthState();
        
        if (storeProvider.stores.isEmpty) {
          AppLogger.d('🔄 Cargando tiendas públicas...');
          await storeProvider.fetchAllStores();
        }
      }
      
    } catch (e) {
      AppLogger.e('❌ Error verificando auth: $e');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.clearAuthState();
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
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
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        AppLogger.d('🎯 AuthStateHandler - isLoggedIn: ${authProvider.isLoggedIn}');
        AppLogger.d('🎯 AuthStateHandler - currentUser: ${authProvider.currentUser?.email}');
        
        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          AppLogger.d('🚀 Redirigiendo a HomeScreen');
          return const HomeScreen();
        } else {
          AppLogger.d('🔐 Redirigiendo a LoginScreen');
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

  static void handleStoreError(BuildContext context, String error) {
    if (error.contains('no_store_enabled')) {
      showWarningSnackBar(
        context,
        'Este usuario no tiene una tienda habilitada.'
      );
    } else if (error.contains('store_not_found')) {
      showErrorSnackBar(
        context,
        'Tienda no encontrada.'
      );
    } else {
      showErrorSnackBar(context, 'Error cargando tienda: $error');
    }
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

  static void navigateToStore(BuildContext context, {String? userId, bool isCurrentUser = false}) {
    Navigator.pushNamed(
      context,
      '/user-store',
      arguments: {
        'userId': userId,
        'isCurrentUser': isCurrentUser,
      },
    );
  }

  static void navigateToEditStore(BuildContext context) {
    Navigator.pushNamed(context, '/edit-store');
  }

  static void navigateToSearch(BuildContext context, {String initialQuery = ''}) {
    Navigator.pushNamed(
      context,
      '/search',
      arguments: {'initialQuery': initialQuery},
    );
  }

  static void navigateToCategoryProducts(BuildContext context, String category) {
    Navigator.pushNamed(
      context,
      '/category-products',
      arguments: {'category': category},
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    
    AppLogger.d('''
📱 APP STATE:
   - User: ${authProvider.currentUser?.email ?? 'No autenticado'}
   - Logged In: ${authProvider.isLoggedIn}
   - User ID: ${authProvider.userId ?? 'N/A'}
   - Products Loaded: ${productProvider.products.length}
   - Stores Loaded: ${storeProvider.stores.length}
   - Stores Initialized: ${storeProvider.isInitialized}
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

  static void checkStoreState(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    AppLogger.d('''
🏪 STORE STATE:
   - Total Stores: ${storeProvider.stores.length}
   - Store Provider Initialized: ${storeProvider.isInitialized}
   - Store Provider Loading: ${storeProvider.isLoading}
   - Current User Has Store: ${authProvider.currentUser?.hasStore ?? false}
   - Current User Store Name: ${authProvider.currentUser?.storeName ?? 'N/A'}
''');
  }
}

/// Extensiones de utilidad para BuildContext
extension ContextExtensions on BuildContext {
  void goToSignup() => NavigationHelper.navigateToSignup(this);
  void goToLogin() => NavigationHelper.navigateToLogin(this);
  void goToHome() => NavigationHelper.navigateToHome(this);
  void goToProfile() => NavigationHelper.navigateToProfile(this);
  void goToStore({String? userId, bool isCurrentUser = false}) => 
      NavigationHelper.navigateToStore(this, userId: userId, isCurrentUser: isCurrentUser);
  void goToEditStore() => NavigationHelper.navigateToEditStore(this);
  void goToSearch({String initialQuery = ''}) => 
      NavigationHelper.navigateToSearch(this, initialQuery: initialQuery);
  void goToCategoryProducts(String category) => 
      NavigationHelper.navigateToCategoryProducts(this, category);
  void goToProductDetail(dynamic product) => 
      NavigationHelper.navigateToProductDetail(this, product);

  AuthProvider get authProvider => Provider.of<AuthProvider>(this, listen: false);
  ProductProvider get productProvider => Provider.of<ProductProvider>(this, listen: false);
  ChatProvider get chatProvider => Provider.of<ChatProvider>(this, listen: false);
  StoreProvider get storeProvider => Provider.of<StoreProvider>(this, listen: false);
  StoryProvider get storyProvider => Provider.of<StoryProvider>(this, listen: false);

  void showError(String message) => ErrorHandler.showErrorSnackBar(this, message);
  void showSuccess(String message) => ErrorHandler.showSuccessSnackBar(this, message);
  void showWarning(String message) => ErrorHandler.showWarningSnackBar(this, message);
  void handleAuthError(String error) => ErrorHandler.handleAuthError(this, error);
  void handleStoreError(String error) => ErrorHandler.handleStoreError(this, error);
  void handleNetworkError() => ErrorHandler.handleNetworkError(this);

  void logAppState() => AppStateManager.logAppState(this);
  void checkStoreState() => AppStateManager.checkStoreState(this);

  bool get isDebugMode => AppStateManager.isDebugMode;
  Future<bool> get hasActiveSession => AppStateManager.checkActiveSession();
}

/// Widget de utilidad para mostrar loading en toda la pantalla
class FullScreenLoader extends StatelessWidget {
  final String message;

  const FullScreenLoader({
    super.key,
    this.message = 'Cargando...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin para manejo de estado de carga en pantallas
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  Future<void> executeWithLoading(Future<void> Function() action) async {
    setLoading(true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        context.showError('Error: $e');
      }
      rethrow;
    } finally {
      if (mounted) {
        setLoading(false);
      }
    }
  }

  Widget buildLoadingOverlay(Widget child) {
    return Stack(
      children: [
        child,
        if (_isLoading) const FullScreenLoader(),
      ],
    );
  }
}

/// Mixin para manejo de errores en pantallas
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void handleError(dynamic error, [String? customMessage]) {
    AppLogger.e('Error en ${T.toString()}: $error');
    
    if (error is String) {
      context.showError(customMessage ?? error);
    } else if (error.toString().contains('network') || 
               error.toString().contains('connection') ||
               error.toString().contains('socket')) {
      context.handleNetworkError();
    } else {
      context.showError(customMessage ?? 'Ha ocurrido un error inesperado');
    }
  }

  void handleStoreError(dynamic error) {
    if (error.toString().contains('no_store_enabled')) {
      context.showWarning('Este usuario no tiene una tienda habilitada');
    } else if (error.toString().contains('store_not_found')) {
      context.showError('Tienda no encontrada');
    } else {
      handleError(error, 'Error cargando tienda');
    }
  }

}
