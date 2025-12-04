// lib/utils/time_utils.dart - VERSIÓN COMPLETA CORREGIDA
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class TimeUtils {
  // ✅ MANTENER tus funciones existentes
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // ✅ FUNCIONES NUEVAS CRÍTICAS PARA RESOLVER EL ERROR
  
  // 1. Parsear cualquier tipo de fecha dinámicamente
  static DateTime parseDynamicDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) return DateTime.now();
      
      if (dateValue is DateTime) return dateValue;
      
      if (dateValue is String) {
        if (dateValue.isEmpty) return DateTime.now();
        
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // Intentar diferentes formatos
          if (dateValue.contains('T')) {
            final cleaned = dateValue.replaceAll(' ', 'T');
            return DateTime.parse(cleaned);
          }
          
          final formats = [
            'yyyy-MM-dd HH:mm:ss',
            'yyyy-MM-dd HH:mm',
            'dd/MM/yyyy HH:mm:ss',
            'dd/MM/yyyy HH:mm',
          ];
          
          for (final format in formats) {
            try {
              return DateFormat(format).parse(dateValue);
            } catch (_) {}
          }
          
          return DateTime.now();
        }
      }
      
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
      
      return DateTime.now();
    } catch (e) {
      AppLogger.e('❌ Error parseando fecha: $dateValue - $e');
      return DateTime.now();
    }
  }

  // 2. Sanitizar metadata para evitar objetos DateTime
  static Map<String, dynamic> sanitizeMetadata(Map<String, dynamic>? metadata) {
    final sanitized = <String, dynamic>{};
    
    if (metadata == null) return sanitized;
    
    for (final entry in metadata.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is DateTime) {
        sanitized[key] = value.toUtc().toIso8601String();
      } else if (value is Map) {
        sanitized[key] = sanitizeMetadata(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is DateTime) return e.toUtc().toIso8601String();
          if (e is Map) return sanitizeMetadata(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  // 3. Parsear metadata de manera segura (para lectura)
  static Map<String, dynamic> parseMetadata(dynamic metadata) {
    if (metadata == null) return {};
    
    if (metadata is String) {
      try {
        return Map<String, dynamic>.from(json.decode(metadata));
      } catch (e) {
        AppLogger.e('❌ Error parseando metadata string: $e');
        return {};
      }
    } else if (metadata is Map) {
      // Sanitizar para eliminar DateTime
      return sanitizeMetadata(Map<String, dynamic>.from(metadata));
    }
    
    return {};
  }

  // 4. Convertir cualquier valor a JSON seguro
  static dynamic toJsonSafeValue(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    } else if (value is Map) {
      return sanitizeMetadata(Map<String, dynamic>.from(value));
    } else if (value is List) {
      return List<dynamic>.from(value.map((e) => toJsonSafeValue(e)));
    }
    
    return value;
  }

  // 5. Obtener string ISO 8601
  static String toIso8601String(DateTime? dateTime) {
    if (dateTime == null) return '';
    return dateTime.toUtc().toIso8601String();
  }

  // 6. Timestamp actual
  static String currentIso8601String() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // 7. Verificar si un valor contiene DateTime
  static bool containsDateTime(dynamic obj) {
    if (obj == null) return false;
    
    if (obj is DateTime) return true;
    
    if (obj is Map) {
      for (final value in obj.values) {
        if (containsDateTime(value)) return true;
      }
    }
    
    if (obj is List) {
      for (final item in obj) {
        if (containsDateTime(item)) return true;
      }
    }
    
    return false;
  }
}