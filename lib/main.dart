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
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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
          '/products': (context) => const ProductListScreen(),
          '/my-products': (context) => const MyProductsScreen(),
          '/search': (context) => const ProductSearchScreen(),
          '/catalog': (context) => const CatalogScreen(),
          '/map': (context) => const MapScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/chats': (context) => const ChatListScreen(),
          // '/ratings': (context) => const RatingsListScreen(), // ❌ REMOVIDO - Se maneja en onGenerateRoute
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/ratings':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('userId')) {
                return MaterialPageRoute(
                  builder: (context) => RatingsListScreen(
                    userId: args['userId'], // ✅ CORREGIDO: userId proporcionado
                  ),
                );
              }
              // Si no hay userId, redirigir al perfil para obtener el userId del usuario actual
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
                builder: (context) => const ProfileScreen(), // ✅ CORREGIDO: Redirigir a perfil en lugar de ratings
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

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
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
    
    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}

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
}