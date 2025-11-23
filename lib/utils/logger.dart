class AppLogger {
  static void i(String message) {
    print('ℹ️ $message');
  }

  static void d(String message) {
    print('🐛 $message');
  }

  static void w(String message) {
    print('⚠️ $message');
  }

  static void e(String message, [Object? error]) {
    print('❌ $message');
    if (error != null) {
      print('Error details: $error');
    }
  }
}