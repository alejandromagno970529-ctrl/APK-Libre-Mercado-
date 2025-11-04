import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/reputation_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/verification_provider.dart';
import 'providers/story_provider.dart';

// TEMA UNIFICADO
import 'theme/app_theme.dart';

// PANTALLAS PRINCIPALES
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/reputation/ratings_list_screen.dart';

// PANTALLAS DE PRODUCTOS
import 'screens/product/add_product_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/product/my_products_screen.dart';
import 'screens/product/edit_product_screen.dart';

// OTRAS PANTALLAS
import 'screens/search_screen.dart';
import 'screens/map_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';

// MODELOS
import 'models/product_model.dart';
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
        ChangeNotifierProvider(
          create: (_) => AgreementProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => VerificationProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => StoryProvider(Supabase.instance.client),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme, // ✅ TEMA UNIFICADO
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          
          AppRoutes.addProduct: (context) => const AddProductScreen(),
          AppRoutes.productDetail: (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is Product) {
              return ProductDetailScreen(product: arguments);
            }
            return const Scaffold(
              body: Center(child: Text('Producto no encontrado'))
            );
          },
          
          AppRoutes.products: (context) => const ProductListScreen(),
          AppRoutes.myProducts: (context) => const MyProductsScreen(),
          AppRoutes.editProduct: (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is Product) {
              return EditProductScreen(product: arguments);
            }
            return const Scaffold(
              body: Center(child: Text('Producto no válido'))
            );
          },
          
          AppRoutes.chatList: (context) => const ChatListScreen(),
          AppRoutes.chat: (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is Map<String, dynamic>) {
              return ChatScreen(
                chatId: arguments['chatId'] ?? '',
                productId: arguments['productId'] ?? '',
                otherUserId: arguments['otherUserId'] ?? '',
              );
            }
            return const Scaffold(
              body: Center(child: Text('Chat no disponible'))
            );
          },
          
          AppRoutes.map: (context) => const MapScreen(),
          '/search': (context) => const SearchScreen(),
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
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      AppLogger.d('✅ AuthProvider inicializado');
      
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();
      AppLogger.d('✅ ProductProvider inicializado');
      
      if (authProvider.isLoggedIn) {
        final storyProvider = Provider.of<StoryProvider>(context, listen: false);
        await storyProvider.fetchStories();
        await storyProvider.deleteExpiredStories();
        AppLogger.d('✅ StoryProvider inicializado');
        
        Provider.of<AgreementProvider>(context, listen: false);
        Provider.of<VerificationProvider>(context, listen: false);
        AppLogger.d('✅ Providers adicionales listos');
      }
      
    } catch (e) {
      AppLogger.e('❌ Error durante inicialización', e);
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
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
      backgroundColor: Colors.white, // ✅ CAMBIADO: Fondo blanco
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black, // ✅ CAMBIADO: Fondo negro
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 60,
                color: Colors.white, // ✅ CAMBIADO: Icono blanco
              ),
            ),
            const SizedBox(height: 30),
            
            // TEXTO
            Column(
              children: [
                const Text(
                  'Libre Mercado',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // ✅ CAMBIADO: Texto negro
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appSlogan,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87, // ✅ CAMBIADO: Texto negro
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // INDICADOR DE CARGA
            Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black), // ✅ CAMBIADO: Indicador negro
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
                        color: Colors.black87, // ✅ CAMBIADO: Texto negro
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.black54, // ✅ CAMBIADO: Texto negro
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}