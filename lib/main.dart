// lib/main.dart - VERSIÓN COMPLETA CON SERVICIOS INTEGRADOS (CORREGIDA)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/service_model.dart' show ServiceModel;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Importar providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/story_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/reputation_provider.dart';
import 'providers/verification_provider.dart';
import 'providers/store_provider.dart';
import 'providers/typing_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/service_provider.dart'; // ✅ NUEVO: Provider para servicios

// ✅ IMPORTACIONES CORREGIDAS - Usar alias para evitar conflictos
import 'services/connection_manager.dart';
import 'services/message_retry_service.dart';
import 'services/message_cache_service.dart';
import 'services/image_compression_service.dart';
import 'services/chat_service.dart' as chat_service_lib; // ✅ ALIAS
import 'services/notification_service.dart';
import 'services/file_upload_service.dart';
import 'services/cleanup_service.dart';
import 'services/presence_service.dart';
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
// ✅ IMPORTAR ChatScreen COMO CHAT_SCREEN_WIDGET para evitar conflicto
import 'screens/chat/chat_screen.dart' as chat_screen_widget;
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/reputation/ratings_list_screen.dart';
import 'screens/reputation/rating_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/map_screen.dart';
import 'screens/store_screen.dart';
import 'screens/edit_store_screen.dart';

// ✅ IMPORTAR PANTALLAS DE SERVICIOS
import 'screens/services/services_screen.dart';
import 'screens/services/service_detail_screen.dart';
import 'screens/services/add_edit_service_screen.dart';
import 'screens/services/my_services_screen.dart';
import 'screens/services/service_search_screen.dart';

import 'theme/app_theme.dart';
import 'utils/logger.dart';

// ✅ GLOBAL: Notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INICIALIZAR SUPABASE Y NOTIFICACIONES
  await initializeApp();
  
  runApp(const MyApp());
}

Future<void> initializeApp() async {
  try {
    const supabaseUrl = 'https://lgbwswlauddlwwrsjest.supabase.co';
    const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYndzd2xhdWRkbHd3cnNqZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNjI4NTUsImV4cCI6MjA3NjYzODg1NX0.VneAE4Ke9Udq6og75WVFwlLnYcJCfd9J-MTXX4rDk8s';
    
    // 1. Inicializar Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    AppLogger.d('✅ Supabase inicializado correctamente');
    
    // 2. ✅ INICIALIZAR NOTIFICACIONES LOCALES
    await _initializeLocalNotifications();
    
  } catch (e) {
    AppLogger.e('❌ Error inicializando la app: $e');
    rethrow;
  }
}

// ✅ MÉTODO: Inicializar notificaciones locales
Future<void> _initializeLocalNotifications() async {
  try {
    // ignore: prefer_const_declarations
    final AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar clic en notificación
        if (response.payload?.startsWith('chat_') ?? false) {
          final chatId = response.payload!.replaceFirst('chat_', '');
          AppLogger.d('📱 Notificación tocada - Chat ID: $chatId');
        }
      },
    );

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Notifications for new messages',
      importance: Importance.high,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    AppLogger.d('✅ Notificaciones locales inicializadas');
  } catch (e) {
    AppLogger.e('❌ Error inicializando notificaciones locales: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ PROVIDERS BÁSICOS
        ChangeNotifierProvider(create: (_) => AuthProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ProductProvider(
          Supabase.instance.client,
          ImageUploadService(Supabase.instance.client),
        )),
        ChangeNotifierProvider(create: (_) => StoryProvider(Supabase.instance.client)),
        
        // ✅ NUEVO: PROVIDER DE SERVICIOS
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        
        // ✅ PROVIDER DE CHAT MEJORADO CON NUEVOS SERVICIOS
        ChangeNotifierProvider(create: (_) {
          // ✅ USAR ALIAS chat_service_lib
          final chatService = chat_service_lib.ChatService(Supabase.instance.client);
          final notificationService = NotificationService(Supabase.instance.client);
          final fileUploadService = FileUploadService(Supabase.instance.client);
          final imageUploadService = ImageUploadService(Supabase.instance.client);
          
          return ChatProvider(
            chatService: chatService,
            notificationService: notificationService,
            fileUploadService: fileUploadService,
            imageUploadService: imageUploadService,
          );
        }),
        
        // ✅ NUEVOS PROVIDERS PARA CONEXIÓN Y CACHÉ
        ChangeNotifierProvider(create: (_) => ConnectionManager()),
        ChangeNotifierProvider(create: (_) => MessageRetryService()),
        
        // ✅ PROVIDERS ADICIONALES
        ChangeNotifierProvider(create: (_) => AgreementProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => ReputationProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => VerificationProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => StoreProvider(Supabase.instance.client)),
        
        // ✅ PROVIDERS PARA NOTIFICACIONES Y TYPING
        ChangeNotifierProvider(create: (_) => TypingProvider(Supabase.instance.client)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(Supabase.instance.client)),
        
        // ✅ SERVICIOS
        Provider(create: (_) => CleanupService(Supabase.instance.client)),
        Provider(create: (_) => PresenceService()),
        // ✅ USAR ALIAS para ChatService
        Provider<chat_service_lib.ChatService>(create: (_) => chat_service_lib.ChatService(Supabase.instance.client)),
        Provider(create: (_) => NotificationService(Supabase.instance.client)),
        Provider(create: (_) => FileUploadService(Supabase.instance.client)),
        Provider(create: (_) => ImageUploadService(Supabase.instance.client)),
        Provider(create: (_) => ImageCompressionService()),
        
        // ✅ NUEVO: MessageCacheService
        Provider<Future<MessageCacheService>>(
          create: (_) => MessageCacheService.create(),
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
          '/store': (context) => const StoreScreen(),
          '/edit-store': (context) => const EditStoreScreen(),
          
          // ✅ NUEVAS RUTAS PARA SERVICIOS
          '/services': (context) => const ServicesScreen(),
          '/my-services': (context) => const MyServicesScreen(),
          '/add-edit-service': (context) => const AddEditServiceScreen(),
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
            
            // ✅ RUTA DE CHAT CORREGIDA - USAR ALIAS chat_screen_widget
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && 
                  args.containsKey('chatId') && 
                  args.containsKey('otherUserId') && 
                  args.containsKey('productId')) {
                return MaterialPageRoute(
                  // ✅ USAR ALIAS chat_screen_widget.ChatScreen
                  builder: (context) => chat_screen_widget.ChatScreen(
                    chatId: args['chatId'],
                    otherUserId: args['otherUserId'],
                    productId: args['productId'],
                    otherUserName: args['otherUserName'] ?? 'Usuario',
                    otherUserAvatar: args['otherUserAvatar'],
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
            
            // ✅ CORRECCIÓN: ServiceDetailScreen - Validar que serviceId no sea null
            case '/service-detail':
              final serviceId = settings.arguments as String?;
              if (serviceId != null && serviceId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) => ServiceDetailScreen(serviceId: serviceId),
                );
              }
              return MaterialPageRoute(builder: (context) => const ServicesScreen());
            
            // ✅ CORRECCIÓN: ServiceSearchScreen - Validar que query no sea null
            case '/service-search':
              final query = settings.arguments as String?;
              if (query != null) {
                return MaterialPageRoute(
                  builder: (context) => ServiceSearchScreen(initialQuery: query),
                );
              }
              return MaterialPageRoute(builder: (context) => const ServicesScreen());
            
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
  MessageCacheService? _messageCacheService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // ✅ INICIALIZAR CACHE SERVICE
      _messageCacheService = await MessageCacheService.create();
      
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final cleanupService = Provider.of<CleanupService>(context, listen: false);
      // ignore: use_build_context_synchronously, unused_local_variable
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final presenceService = Provider.of<PresenceService>(context, listen: false);
      // ignore: use_build_context_synchronously
      final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
      // ignore: use_build_context_synchronously
      final messageRetryService = Provider.of<MessageRetryService>(context, listen: false);
      // ignore: use_build_context_synchronously
      final imageCompressionService = Provider.of<ImageCompressionService>(context, listen: false);
      
      // ✅ INICIALIZAR CONNECTION MANAGER
      await connectionManager.checkConnection();
      AppLogger.d('✅ ConnectionManager inicializado');
      
      // ✅ INICIALIZAR MESSAGE RETRY SERVICE
      messageRetryService.initialize();
      AppLogger.d('✅ MessageRetryService inicializado');
      
      // ✅ CONFIGURAR CHAT PROVIDER CON NUEVOS SERVICIOS
      if (_messageCacheService != null) {
        chatProvider.initializeWithServices(
          connectionManager: connectionManager,
          messageRetryService: messageRetryService,
          messageCacheService: _messageCacheService!,
          imageCompressionService: imageCompressionService,
        );
      }
      
      // ✅ DIAGNÓSTICO INMEDIATO DE PRESENCIA
      AppLogger.d('🔍 EJECUTANDO DIAGNÓSTICO DE PRESENCIA...');
      final presenceDiagnostic = await presenceService.diagnosePresenceSystem();
      
      // ✅ INICIALIZAR TODOS LOS PROVIDERS
      await Future.wait([
        authProvider.initialize(),
        productProvider.initialize(),
        storeProvider.fetchAllStores(),
        serviceProvider.fetchServices(),
      ]);

      // ✅ INICIALIZAR CONFIGURACIÓN RLS PARA CHAT
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await chatProvider.initializeRLS();
          AppLogger.d('✅ Configuración RLS inicializada para chat');
          
          // ✅ EJECUTAR LIMPIEZA PROGRAMADA EN SEGUNDO PLANO
          Future.delayed(const Duration(seconds: 10), () {
            cleanupService.scheduleCleanup();
          });
        } catch (e) {
          AppLogger.e('⚠️ Error inicializando RLS (no crítico): $e');
        }
      });

      // ✅ VERIFICAR ESTADO DE SERVICIOS
      AppLogger.d('🔧 Estado de servicios inicializados:');
      AppLogger.d('   - Auth: ${authProvider.isLoggedIn}');
      AppLogger.d('   - Products: ${productProvider.products.length}');
      AppLogger.d('   - Stores: ${storeProvider.stores.length}');
      AppLogger.d('   - Services: ${serviceProvider.services.length}');
      AppLogger.d('   - Chats: ${chatProvider.chatsList.length}');
      AppLogger.d('   - Connection: ${connectionManager.status}');
      AppLogger.d('   - Cache Service: ${_messageCacheService != null}');
      AppLogger.d('   - Presence System: ${presenceDiagnostic['success'] ? 'OK' : 'Needs Setup'}');
      
    } catch (e) {
      AppLogger.e('❌ Error inicializando app: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // ✅ LIMPIAR PROVIDERS AL CERRAR APP
    final notificationProvider = context.read<NotificationProvider>();
    final typingProvider = context.read<TypingProvider>();
    final presenceService = context.read<PresenceService>();
    final connectionManager = context.read<ConnectionManager>();
    final messageRetryService = context.read<MessageRetryService>();
    
    notificationProvider.dispose();
    typingProvider.dispose();
    presenceService.dispose();
    connectionManager.dispose();
    messageRetryService.dispose();
    
    super.dispose();
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
              'Compra y vende de forma Libre', 
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
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final presenceService = Provider.of<PresenceService>(context, listen: false);
      final typingProvider = Provider.of<TypingProvider>(context, listen: false);
      final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
      
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;
      
      AppLogger.d('📊 Sesión Supabase: ${session != null}');
      AppLogger.d('👤 Usuario Supabase: ${user?.email}');
      AppLogger.d('🔄 Estado AuthProvider: ${authProvider.isLoggedIn}');
      AppLogger.d('🏪 Tiendas cargadas: ${storeProvider.stores.length}');
      AppLogger.d('🔧 Servicios cargados: ${serviceProvider.services.length}');
      AppLogger.d('💬 Chats cargados: ${chatProvider.chatsList.length}');
      AppLogger.d('📶 Estado conexión: ${connectionManager.status}');
      
      if (session != null && user != null) {
        AppLogger.d('✅ Sesión activa encontrada - Cargando perfil...');
        await authProvider.loadUserProfile(user.id);
        
        // ✅ CARGAR CHATS DEL USUARIO SI ESTÁ AUTENTICADO
        if (authProvider.isLoggedIn) {
          AppLogger.d('💬 Cargando chats del usuario...');
          try {
            await chatProvider.loadUserChats(user.id);
            AppLogger.d('✅ Chats cargados: ${chatProvider.chatsList.length}');
          } catch (e) {
            AppLogger.e('❌ Error cargando chats: $e');
          }
        }
        
        // ✅ CARGAR SERVICIOS DEL USUARIO SI ESTÁ AUTENTICADO
        if (authProvider.isLoggedIn) {
          AppLogger.d('🔧 Cargando servicios del usuario...');
          try {
            await serviceProvider.fetchMyServices(user.id);
            AppLogger.d('✅ Servicios personales cargados: ${serviceProvider.myServices.length}');
          } catch (e) {
            AppLogger.e('❌ Error cargando servicios: $e');
          }
        }
        
        // ✅ INICIALIZAR NOTIFICACIONES
        AppLogger.d('🔔 Inicializando notificaciones...');
        await notificationProvider.initialize(user.id);
        
        // ✅ ACTUALIZAR PRESENCIA DEL USUARIO
        await presenceService.updateUserPresence(userId: user.id, online: true);
        presenceService.startPresenceMonitor(user.id);
        
        if (storeProvider.stores.isEmpty) {
          AppLogger.d('🔄 Recargando tiendas para usuario autenticado...');
          await storeProvider.fetchAllStores();
        }
      } else {
        AppLogger.d('🔐 No hay sesión activa - Limpiando estado...');
        await authProvider.clearAuthState();
        
        // ✅ LIMPIAR PROVIDERS SI NO HAY SESIÓN
        chatProvider.disposeAll();
        notificationProvider.dispose();
        typingProvider.dispose();
        presenceService.dispose();
        serviceProvider.clearServices();
        
        if (storeProvider.stores.isEmpty) {
          AppLogger.d('🔄 Cargando tiendas públicas...');
          await storeProvider.fetchAllStores();
        }
      }
      
    } catch (e) {
      AppLogger.e('❌ Error verificando auth: $e');
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final typingProvider = Provider.of<TypingProvider>(context, listen: false);
      // ignore: use_build_context_synchronously
      final presenceService = Provider.of<PresenceService>(context, listen: false);
      // ignore: use_build_context_synchronously
      final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
      
      await authProvider.clearAuthState();
      chatProvider.disposeAll();
      serviceProvider.clearServices();
      notificationProvider.dispose();
      typingProvider.dispose();
      presenceService.dispose();
      connectionManager.dispose();
    } finally {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  @override
  void dispose() {
    // ✅ LIMPIAR AL CERRAR PANTALLA
    final presenceService = context.read<PresenceService>();
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      presenceService.stopPresenceMonitor(currentUser.id);
    }
    
    super.dispose();
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

  static void handleChatError(BuildContext context, String error) {
    if (error.contains('bucket')) {
      showErrorSnackBar(
        context,
        'Error de configuración del chat. Contacta con soporte.'
      );
    } else if (error.contains('permission')) {
      showErrorSnackBar(
        context,
        'No tienes permisos para realizar esta acción en el chat.'
      );
    } else {
      showErrorSnackBar(context, 'Error en el chat: $error');
    }
  }

  static void handleFileError(BuildContext context, String error) {
    if (error.contains('too large')) {
      showErrorSnackBar(
        context,
        'El archivo es demasiado grande. Máximo 10MB.'
      );
    } else if (error.contains('permission')) {
      showErrorSnackBar(
        context,
        'Permiso denegado para acceder al archivo.'
      );
    } else {
      showErrorSnackBar(context, 'Error con el archivo: $error');
    }
  }

  // ✅ NUEVO: Manejo de errores para servicios
  static void handleServiceError(BuildContext context, String error) {
    if (error.contains('no_services')) {
      showWarningSnackBar(
        context,
        'No hay servicios disponibles en este momento.'
      );
    } else if (error.contains('service_not_found')) {
      showErrorSnackBar(
        context,
        'Servicio no encontrado.'
      );
    } else {
      showErrorSnackBar(context, 'Error con el servicio: $error');
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

  // ✅ NAVEGACIÓN A SERVICIOS
  static void navigateToServices(BuildContext context) {
    Navigator.pushNamed(context, '/services');
  }

  static void navigateToMyServices(BuildContext context) {
    Navigator.pushNamed(context, '/my-services');
  }

  static void navigateToServiceDetail(BuildContext context, String serviceId) {
    Navigator.pushNamed(
      context,
      '/service-detail',
      arguments: serviceId,
    );
  }

  static void navigateToAddEditService(BuildContext context, {ServiceModel? service}) {
    Navigator.pushNamed(
      context,
      '/add-edit-service',
      arguments: service,
    );
  }

  static void navigateToServiceSearch(BuildContext context, String query) {
    Navigator.pushNamed(
      context,
      '/service-search',
      arguments: query,
    );
  }

  // ✅ NAVEGACIÓN A CHAT
  static void navigateToChat(BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String productId,
    String otherUserName = 'Usuario',
    String? otherUserAvatar,
  }) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'productId': productId,
        'otherUserName': otherUserName,
        'otherUserAvatar': otherUserAvatar,
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

  // ✅ NUEVO: Navegación a lista de chats
  static void navigateToChatList(BuildContext context) {
    Navigator.pushNamed(context, '/chats');
  }

  // ✅ NUEVO: Navegación para crear chat
  static void navigateToCreateChat(BuildContext context, {
    required String productId,
    required String sellerId,
    required String productTitle,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        ErrorHandler.showErrorSnackBar(context, 'Debes iniciar sesión para chatear');
        return;
      }

      final chatId = await chatProvider.getOrCreateChat(
        productId: productId,
        buyerId: authProvider.currentUser!.id,
        sellerId: sellerId,
        buyerName: authProvider.currentUser!.username,
        productTitle: productTitle, 
        serviceId: '',
      );

      navigateToChat(
        // ignore: use_build_context_synchronously
        context,
        chatId: chatId,
        otherUserId: sellerId,
        productId: productId,
        otherUserName: 'Vendedor',
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ErrorHandler.handleChatError(context, e.toString());
    }
  }

  // ✅ NUEVO: Navegación para contactar proveedor de servicio
  static void navigateToContactServiceProvider(BuildContext context, {
    required String serviceId,
    required String providerId,
    required String serviceTitle,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        ErrorHandler.showErrorSnackBar(context, 'Debes iniciar sesión para contactar');
        return;
      }

      // ✅ ¡CORRECCIÓN AQUÍ! Cambiar productId: null por productId: ''
      final chatId = await chatProvider.getOrCreateChat(
        productId: '', // ← CORREGIDO: Cambiar null por string vacío
        serviceId: serviceId,
        buyerId: authProvider.currentUser!.id,
        sellerId: providerId,
        buyerName: authProvider.currentUser!.username,
        productTitle: serviceTitle,
      );

      navigateToChat(
        // ignore: use_build_context_synchronously
        context,
        chatId: chatId,
        otherUserId: providerId,
        productId: serviceId, // Aquí productId se refiere al servicio
        otherUserName: 'Proveedor de servicio',
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ErrorHandler.handleChatError(context, e.toString());
    }
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
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final typingProvider = Provider.of<TypingProvider>(context, listen: false);
    final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    final messageRetryService = Provider.of<MessageRetryService>(context, listen: false);
    
    AppLogger.d(''' 
📱 APP STATE:
   - User: ${authProvider.currentUser?.email ?? 'No autenticado'}
   - Logged In: ${authProvider.isLoggedIn}
   - User ID: ${authProvider.userId ?? 'N/A'}
   - Products Loaded: ${productProvider.products.length}
   - Services Loaded: ${serviceProvider.services.length} (Personales: ${serviceProvider.myServices.length})
   - Stores Loaded: ${storeProvider.stores.length}
   - Chats Loaded: ${chatProvider.chatsList.length}
   - Notificaciones: ${notificationProvider.notifications.length}
   - Notificaciones no leídas: ${notificationProvider.unreadCount}
   - Typing activos: ${typingProvider.typingUsers.length}
   - Stores Initialized: ${storeProvider.isInitialized}
   - Connection Status: ${connectionManager.status}
   - Connection Quality: ${connectionManager.quality}
   - Message Retry Queue: ${messageRetryService.getStats()['total_pending']}
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

  static void checkServiceState(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    
    AppLogger.d(''' 
🔧 SERVICE STATE:
   - Total Services: ${serviceProvider.services.length}
   - My Services: ${serviceProvider.myServices.length}
   - Service Provider Loading: ${serviceProvider.isLoading}
   - Selected Category: ${serviceProvider.selectedCategory ?? 'Ninguna'}
''');
  }

  static void checkChatState(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    
    AppLogger.d(''' 
💬 CHAT STATE:
   - Total Chats: ${chatProvider.chatsList.length}
   - Chat Provider Loading: ${chatProvider.isLoading}
   - Chat Provider Error: ${chatProvider.error ?? 'Ninguno'}
   - User Authenticated: ${authProvider.isLoggedIn}
   - User ID: ${authProvider.userId ?? 'N/A'}
   - Connection Status: ${connectionManager.status}
   - Is Online: ${connectionManager.isOnline}
''');
  }

  static void checkNotificationState(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    AppLogger.d(''' 
🔔 NOTIFICATION STATE:
   - Total Notificaciones: ${notificationProvider.notifications.length}
   - No leídas: ${notificationProvider.unreadCount}
   - Loading: ${notificationProvider.isLoading}
   - Error: ${notificationProvider.error ?? 'Ninguno'}
''');
  }

  static void checkConnectionState(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    
    AppLogger.d(''' 
📶 CONNECTION STATE:
   - Status: ${connectionManager.status}
   - Quality: ${connectionManager.quality}
   - Is Online: ${connectionManager.isOnline}
   - Last Online: ${connectionManager.lastOnlineTime}
   - Reconnect Attempts: ${connectionManager.reconnectAttempts}
''');
  }

  static Future<void> checkCleanupState(BuildContext context) async {
    final cleanupService = Provider.of<CleanupService>(context, listen: false);
    
    try {
      final stats = await cleanupService.getCleanupStats();
      AppLogger.d(''' 
🧹 CLEANUP STATE:
   - Mensajes antiguos: ${stats['old_messages']}
   - Notificaciones antiguas: ${stats['old_notifications']}
   - Chats vacíos: ${stats['empty_chats']}
   - Última limpieza: ${stats['last_cleanup']}
''');
    } catch (e) {
      AppLogger.e('❌ Error verificando estado de limpieza: $e');
    }
  }

  static Future<Map<String, dynamic>> getFullDiagnostic(BuildContext context) async {
    final connectionManager = Provider.of<ConnectionManager>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final messageRetryService = Provider.of<MessageRetryService>(context, listen: false);
    
    try {
      final connectionInfo = await connectionManager.getConnectionInfo();
      final retryStats = messageRetryService.getStats();
      
      return {
        'connection': connectionInfo,
        'service_stats': {
          'services_count': serviceProvider.services.length,
          'my_services_count': serviceProvider.myServices.length,
          'is_loading': serviceProvider.isLoading,
        },
        'chat_stats': {
          'chats_count': chatProvider.chatsList.length,
          'is_loading': chatProvider.isLoading,
          'error': chatProvider.error,
        },
        'retry_stats': retryStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}