class AppLogger {
  static void i(String message) {
    // ignore: avoid_print
    print('ℹ️ $message');
  }

  static void d(String message) {
    // ignore: avoid_print
    print('🐛 $message');
  }

  static void w(String message) {
    // ignore: avoid_print
    print('⚠️ $message');
  }

  static void e(String message, [Object? error]) {
    // ignore: avoid_print
    print('❌ $message');
    if (error != null) {
      // ignore: avoid_print
      print('Error details: $error');
    }
  }

  static void info(String s) {}

  static void error(String s) {}
}