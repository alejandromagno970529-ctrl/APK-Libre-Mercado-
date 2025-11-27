// lib/utils/time_utils.dart - NUEVO ARCHIVO CREADO
import 'package:libre_mercado_final_app/utils/logger.dart';

class TimeUtils {
  // ✅ FUNCIÓN MEJORADA: Manejo robusto de diferencia de tiempo
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Si la diferencia es negativa (timestamp en el futuro), ajustar
    if (difference.isNegative) {
      AppLogger.w('⚠️ Timestamp en el futuro detectado: $dateTime, ahora: $now');
      return 'ahora mismo';
    }

    if (difference.inSeconds < 5) {
      return 'ahora mismo';
    } else if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return 'hace ${difference.inDays}d';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'hace ${months}mes';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'hace ${years}a';
    }
  }

  // ✅ NUEVO: Función para debuggear timestamps
  static void debugTimestamp(DateTime dateTime, String label) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    AppLogger.d('🕒 DEBUG $label:');
    AppLogger.d('   - Fecha/hora: $dateTime');
    AppLogger.d('   - Ahora: $now');
    AppLogger.d('   - Diferencia: ${difference.inHours}h ${difference.inMinutes.remainder(60)}m');
    AppLogger.d('   - Diferencia total minutos: ${difference.inMinutes}');
    AppLogger.d('   - Diferencia total segundos: ${difference.inSeconds}');
  }
}