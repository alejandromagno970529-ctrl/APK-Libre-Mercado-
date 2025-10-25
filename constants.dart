class AppConstants {
  static const String appName = 'Libre Mercado';
  static const String appVersion = '1.0.0';
  
  // Supabase Configuration - REEMPLAZA CON TUS DATOS REALES
  static const String supabaseUrl = 'https://lgbwswlauddlwwrsjest.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYndzd2xhdWRkbHd3cnNqZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNjI4NTUsImV4cCI6MjA3NjYzODg1NX0.VneAE4Ke9Udq6og75WVFwlLnYcJCfd9J-MTXX4rDk8s';
  
  // App Settings
  static const int productsPerPage = 20;
  static const double defaultMapZoom = 15.0;
  static const int chatMessageLimit = 100;
  
  // Image Settings
  static const double productImageMaxSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
}

class AppStrings {
  static const String appSlogan = 'Compra y vende de forma libre';
  static const String welcomeMessage = 'Bienvenido a Libre Mercado';
  static const String noProducts = 'No hay productos disponibles';
  static const String loading = 'Cargando...';
  static const String errorGeneric = 'Ha ocurrido un error';
  static const String noInternet = 'No hay conexión a internet';
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String addProduct = '/add-product';
  static const String productDetail = '/product-detail';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String map = '/map';
}