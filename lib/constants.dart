// lib/constants.dart
class AppConstants {
  static const String appName = 'Libre Mercado';
  static const String appVersion = '1.0.0';
  
  // ✅ SUPABASE CONFIGURATION - CON TUS DATOS REALES
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYndzd2xhdWRkbHd3cnNqZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNjI4NTUsImV4cCI6MjA3NjYzODg1NX0.VneAE4Ke9Udq6og75WVFwlLnYcJCfd9J-MTXX4rDk8s';
  
  // ✅ APP SETTINGS
  static const int productsPerPage = 20;
  static const double defaultMapZoom = 15.0;
  static const int chatMessageLimit = 100;
  static const int storyDurationHours = 24;
  static const int maxProductImages = 5;
  static const int maxStoryTextLength = 200;
  
  // ✅ IMAGE SETTINGS
  static const double productImageMaxSize = 5 * 1024 * 1024; // 5MB
  static const double profileImageMaxSize = 3 * 1024 * 1024; // 3MB
  static const double storyImageMaxSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // ✅ STORAGE BUCKETS
  static const String productImagesBucket = 'product-images';
  static const String storyImagesBucket = 'stories';
  
  // ✅ DATABASE TABLE NAMES
  static const String productsTable = 'products';
  static const String storiesTable = 'stories';
  static const String usersTable = 'profiles';
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String ratingsTable = 'ratings';
  static const String agreementsTable = 'transaction_agreements';
  
  // ✅ DEFAULT VALUES
  static const String defaultCurrency = 'CUP';
  static const String defaultCategory = 'Tecnología';
  static const String defaultCity = 'Holguín';
  
  // ✅ LOCATION DEFAULTS (Holguín, Cuba)
  static const double defaultLatitude = 20.8887;
  static const double defaultLongitude = -76.2573;
  
  // ✅ TIME CONSTANTS
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheDuration = Duration(minutes: 15);
  static const Duration storyLifeSpan = Duration(hours: 24);
  
  // ✅ VALIDATION CONSTANTS
  static const int minProductTitleLength = 5;
  static const int maxProductTitleLength = 100;
  static const int minProductDescriptionLength = 10;
  static const int maxProductDescriptionLength = 1000;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 6;
  
  // ✅ PAGINATION
  static const int initialPageSize = 10;
  static const int loadMoreThreshold = 5;
}

class AppStrings {
  static const String appSlogan = 'Compra y vende de forma libre';
  static const String welcomeMessage = 'Bienvenido a Libre Mercado';
  static const String noProducts = 'No hay productos disponibles';
  static const String noStories = 'No hay historias disponibles';
  static const String noChats = 'No hay conversaciones';
  static const String loading = 'Cargando...';
  static const String errorGeneric = 'Ha ocurrido un error';
  static const String noInternet = 'No hay conexión a internet';
  static const String tryAgain = 'Intentar nuevamente';
  static const String success = 'Éxito';
  static const String error = 'Error';
  static const String warning = 'Advertencia';
  static const String info = 'Información';
  
  // ✅ AUTH STRINGS
  static const String login = 'Iniciar Sesión';
  static const String signup = 'Registrarse';
  static const String logout = 'Cerrar Sesión';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar Contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String noAccount = '¿No tienes cuenta?';
  static const String hasAccount = '¿Ya tienes cuenta?';
  
  // ✅ PRODUCT STRINGS
  static const String myProducts = 'Mis Productos';
  static const String allProducts = 'Todos los Productos';
  static const String productDetails = 'Detalles del Producto';
  static const String editProduct = 'Editar Producto';
  static const String addProduct = 'Publicar Producto';
  static const String deleteProduct = 'Eliminar Producto';
  static const String productTitle = 'Título del Producto';
  static const String productDescription = 'Descripción';
  static const String productPrice = 'Precio';
  static const String productCategory = 'Categoría';
  static const String productLocation = 'Ubicación';
  static const String productImages = 'Imágenes del Producto';
  static const String publishProduct = 'Publicar Producto';
  static const String updateProduct = 'Actualizar Producto';
  
  // ✅ STORY STRINGS
  static const String createStory = 'Crear Historia';
  static const String storyText = 'Texto de la Historia';
  static const String storyImage = 'Imagen de la Historia';
  static const String linkProduct = 'Vincular Producto';
  static const String noLinkedProduct = 'Sin producto vinculado';
  static const String storyExpiresIn = 'La historia expira en';
  static const String storyExpired = 'Historia Expirada';
  
  // ✅ PROFILE STRINGS
  static const String profile = 'Perfil';
  static const String editProfile = 'Editar Perfil';
  static const String myProfile = 'Mi Perfil';
  static const String username = 'Nombre de Usuario';
  static const String fullName = 'Nombre Completo';
  static const String phone = 'Teléfono';
  static const String bio = 'Biografía';
  static const String saveChanges = 'Guardar Cambios';
  
  // ✅ CHAT STRINGS
  static const String chats = 'Conversaciones';
  static const String newMessage = 'Nuevo mensaje';
  static const String typeMessage = 'Escribe un mensaje...';
  static const String send = 'Enviar';
  static const String startConversation = 'Iniciar Conversación';
  
  // ✅ RATING STRINGS
  static const String ratings = 'Calificaciones';
  static const String myRatings = 'Mis Calificaciones';
  static const String leaveRating = 'Dejar Calificación';
  static const String ratingComment = 'Comentario (opcional)';
  static const String submitRating = 'Enviar Calificación';
  
  // ✅ AGREEMENT STRINGS
  static const String transactionAgreement = 'Acuerdo de Transacción';
  static const String createAgreement = 'Crear Acuerdo';
  static const String agreementTerms = 'Términos del Acuerdo';
  static const String acceptAgreement = 'Aceptar Acuerdo';
  static const String rejectAgreement = 'Rechazar Acuerdo';
  
  // ✅ VERIFICATION STRINGS
  static const String verification = 'Verificación';
  static const String identityVerification = 'Verificación de Identidad';
  static const String uploadDocument = 'Subir Documento';
  static const String verificationPending = 'Verificación Pendiente';
  static const String verificationApproved = 'Verificación Aprobada';
  static const String verificationRejected = 'Verificación Rechazada';
  
  // ✅ CATEGORIES - ACTUALIZADO: "Música y Películas" → "Alimentos y bebidas"
  static const List<String> productCategories = [
    'Tecnología',
    'Electrodomésticos',
    'Ropa y Accesorios',
    'Hogar y Jardín',
    'Deportes',
    'Videojuegos',
    'Libros',
    'Alimentos y bebidas', // ✅ REEMPLAZADO
    'Salud y Belleza',
    'Juguetes',
    'Herramientas',
    'Automóviles',
    'Motos',
    'Bicicletas',
    'Mascotas',
    'Arte y Coleccionables',
    'Inmuebles',
    'Empleos',
    'Servicios',
    'Otros'
  ];
  
  // ✅ CURRENCIES
  static const List<String> currencies = ['CUP', 'USD'];
  
  // ✅ ERROR MESSAGES
  static const String errorInvalidEmail = 'Correo electrónico inválido';
  static const String errorShortPassword = 'La contraseña debe tener al menos 6 caracteres';
  static const String errorPasswordMismatch = 'Las contraseñas no coinciden';
  static const String errorShortUsername = 'El nombre de usuario debe tener al menos 3 caracteres';
  static const String errorRequiredField = 'Este campo es obligatorio';
  static const String errorInvalidPrice = 'Precio inválido';
  static const String errorImageRequired = 'La imagen es obligatoria';
  static const String errorImageTooLarge = 'La imagen es demasiado grande';
  static const String errorLocationRequired = 'La ubicación es obligatoria';
  
  // ✅ SUCCESS MESSAGES
  static const String successProductPublished = 'Producto publicado exitosamente';
  static const String successProductUpdated = 'Producto actualizado exitosamente';
  static const String successProductDeleted = 'Producto eliminado exitosamente';
  static const String successStoryPublished = 'Historia publicada exitosamente';
  static const String successProfileUpdated = 'Perfil actualizado exitosamente';
  static const String successRatingSubmitted = 'Calificación enviada exitosamente';
  static const String successAgreementCreated = 'Acuerdo creado exitosamente';
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String addProduct = '/add-product';
  static const String productDetail = '/product-detail';
  static const String editProduct = '/edit-product';
  static const String myProducts = '/my-products';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String map = '/map';
  static const String catalog = '/catalog';
  static const String search = '/search';
  
  // ✅ STORY ROUTES
  static const String storyView = '/story-view';
  static const String createStory = '/create-story';
  
  // ✅ RATING ROUTES
  static const String ratingsList = '/ratings-list';
  static const String ratingScreen = '/rating-screen';
  
  // ✅ AGREEMENT ROUTES
  static const String agreementScreen = '/agreement-screen';
  
  // ✅ VERIFICATION ROUTES
  static const String verificationScreen = '/verification-screen';
}

class AppStoragePaths {
  static const String products = 'products/';
  static const String profiles = 'profiles/';
  static const String stories = 'stories/';
  static const String verification = 'verification/';
}

class AppApiEndpoints {
  static const String products = 'products';
  static const String stories = 'stories';
  static const String profiles = 'profiles';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String ratings = 'ratings';
  static const String agreements = 'transaction_agreements';
}

class AppValidationPatterns {
  // ignore: deprecated_member_use
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  // ignore: deprecated_member_use
  static final RegExp phoneRegex = RegExp(
    r'^[+]?[\d\s-()]{10,}$'
  );
  // ignore: deprecated_member_use
  static final RegExp usernameRegex = RegExp(
    r'^[a-zA-Z0-9_]{3,30}$'
  );
}

class AppDimensions {
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  static const double smallMargin = 8.0;
  static const double mediumMargin = 16.0;
  static const double largeMargin = 24.0;
  
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  static const double buttonHeight = 48.0;
  static const double textFieldHeight = 56.0;
  static const double appBarHeight = 56.0;
  
  static const double productImageSize = 120.0;
  static const double storyImageSize = 72.0;
  static const double profileImageSize = 80.0;

}
