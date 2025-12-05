// lib/models/message_model.dart - VERSIÓN 20.0.0 COMPLETAMENTE CORREGIDA
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import '../utils/time_utils.dart';
import '../utils/logger.dart';

enum MessageType {
  text,
  image,
  file,
  agreement,
  system
}

class Message extends Equatable {
  final String id;
  final String chatId;
  final String? fromId;
  final String text;
  final MessageType type;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool read;
  final bool delivered;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final bool isSystem;
  final String? tempId;
  final bool isUploading;

  const Message({
    required this.id,
    required this.chatId,
    this.fromId,
    required this.text,
    this.type = MessageType.text,
    this.metadata = const {},
    required this.createdAt,
    this.read = false,
    this.delivered = false,
    this.readAt,
    this.deliveredAt,
    this.isSystem = false,
    this.tempId,
    this.isUploading = false,
  });

  // ✅ MÉTODO ESTÁTICO CORREGIDO
  static String generateTempId([String? fromId]) {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'temp_${List.generate(12, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // ✅ GETTER: Saber si es mensaje temporal
  bool get isTemporary => tempId != null || id.startsWith('temp_');

  // ✅ FUNCIÓN: Preparar metadata para Supabase
  static Map<String, dynamic> _prepareMetadataForSupabase(Map<String, dynamic> metadata) {
    final Map<String, dynamic> prepared = {};
    
    metadata.forEach((key, value) {
      if (value is DateTime) {
        prepared[key] = value.toIso8601String();
      } else if (value is Map) {
        prepared[key] = _prepareMetadataForSupabase(Map<String, dynamic>.from(value));
      } else if (value is List) {
        prepared[key] = _prepareListForSupabase(value);
      } else {
        prepared[key] = value;
      }
    });
    
    return prepared;
  }

  static List<dynamic> _prepareListForSupabase(List<dynamic> list) {
    return list.map((item) {
      if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map) {
        return _prepareMetadataForSupabase(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _prepareListForSupabase(item);
      }
      return item;
    }).toList();
  }

  // ✅ FUNCIÓN: Convertir fechas en JSON a DateTime
  static Map<String, dynamic> _convertJsonDatesToDateTime(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    
    data.forEach((key, value) {
      if (value is String && _looksLikeDateTime(value)) {
        try {
          result[key] = DateTime.parse(value);
        } catch (e) {
          result[key] = value;
        }
      } else if (value is Map) {
        result[key] = _convertJsonDatesToDateTime(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[key] = _convertListDatesToDateTime(value);
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

  static List<dynamic> _convertListDatesToDateTime(List<dynamic> list) {
    return list.map((item) {
      if (item is String && _looksLikeDateTime(item)) {
        try {
          return DateTime.parse(item);
        } catch (e) {
          return item;
        }
      } else if (item is Map) {
        return _convertJsonDatesToDateTime(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _convertListDatesToDateTime(item);
      }
      return item;
    }).toList();
  }

  static bool _looksLikeDateTime(String value) {
    try {
      final patterns = [
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}',
        r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}',
        r'^\d{4}-\d{2}-\d{2}$',
      ];
      
      for (final pattern in patterns) {
        if (RegExp(pattern).hasMatch(value)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ FACTORY CONSTRUCTOR COMPLETAMENTE CORREGIDO Y ROBUSTO
  factory Message.fromMap(Map<String, dynamic> map) {
    try {
      // ✅ DIAGNÓSTICO: Verificar tipos de datos recibidos
      AppLogger.d('🔍 Message.fromMap - Mapa recibido con claves: ${map.keys.toList()}');
      
      if (map.containsKey('created_at')) {
        AppLogger.d('🔍 Message.fromMap - created_at tipo: ${map['created_at'].runtimeType}');
        AppLogger.d('🔍 Message.fromMap - created_at valor: ${map['created_at']}');
      }
      
      // ✅ SANITIZAR EL MAPA COMPLETO ANTES DE PROCESAR
      Map<String, dynamic> sanitizedMap = {};
      
      for (final entry in map.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Si es DateTime, convertir a String
        if (value is DateTime) {
          sanitizedMap[key] = value.toIso8601String();
          AppLogger.d('🔄 Convertido $key de DateTime a String');
        } 
        // Si es Map, limpiar recursivamente
        else if (value is Map) {
          sanitizedMap[key] = _sanitizeMapValue(value);
        }
        // Si es List, limpiar cada elemento
        else if (value is List) {
          sanitizedMap[key] = _sanitizeListValue(value);
        }
        // Cualquier otro valor, dejarlo como está
        else {
          sanitizedMap[key] = value;
        }
      }
      
      // ✅ FUNCIÓN HELPER MEJORADA PARA PARSEAR FECHAS
      DateTime parseDateTime(dynamic dateValue) {
        try {
          if (dateValue == null) return DateTime.now();
          
          if (dateValue is DateTime) return dateValue;
          
          if (dateValue is String) {
            if (dateValue.isEmpty) return DateTime.now();
            
            try {
              return DateTime.parse(dateValue);
            } catch (e) {
              // Intentar diferentes formatos
              final cleaned = dateValue.replaceAll(' ', 'T');
              try {
                return DateTime.parse(cleaned);
              } catch (e2) {
                AppLogger.w('⚠️ No se pudo parsear fecha: $dateValue, usando DateTime.now()');
                return DateTime.now();
              }
            }
          }
          
          return DateTime.now();
        } catch (e) {
          AppLogger.e('❌ Error parseando fecha: $dateValue - $e');
          return DateTime.now();
        }
      }

      // ✅ PARSER PARA FECHAS NULLABLES
      DateTime? parseNullableDateTime(dynamic dateValue) {
        if (dateValue == null) return null;
        try {
          if (dateValue is DateTime) return dateValue;
          if (dateValue is String) {
            if (dateValue.isEmpty) return null;
            try {
              return DateTime.parse(dateValue);
            } catch (e) {
              return null;
            }
          }
          return null;
        } catch (e) {
          return null;
        }
      }

      // ✅ PARSER PARA TIPO DE MENSAJE
      MessageType parseMessageType(String? typeString) {
        try {
          if (typeString == null || typeString.isEmpty) return MessageType.text;
          final type = typeString.toLowerCase();
          
          if (type == 'image') return MessageType.image;
          if (type == 'file') return MessageType.file;
          if (type == 'agreement') return MessageType.agreement;
          if (type == 'system') return MessageType.system;
          return MessageType.text;
        } catch (e) {
          return MessageType.text;
        }
      }

      // ✅ PARSER PARA METADATA MEJORADO
      Map<String, dynamic> parseMetadata(dynamic metadata) {
        try {
          if (metadata == null) return {};
          
          Map<String, dynamic> result = {};
          
          if (metadata is String) {
            if (metadata.isEmpty) return {};
            
            if (metadata.trim().startsWith('{') || metadata.trim().startsWith('[')) {
              try {
                final decoded = json.decode(metadata);
                if (decoded is Map) {
                  result = Map<String, dynamic>.from(decoded);
                }
              } catch (e) {
                result = {'raw': metadata, 'parse_error': e.toString()};
              }
            } else {
              result = {'raw': metadata};
            }
          } else if (metadata is Map) {
            result = Map<String, dynamic>.from(metadata);
          }
          
          // ✅ Asegurar que no haya objetos DateTime en el metadata
          result = TimeUtils.sanitizeMetadata(result);
          return result;
        } catch (e) {
          AppLogger.e('❌ Error parseando metadata: $e');
          return {};
        }
      }

      // ✅ PARSER PARA BOOLEANOS ROBUSTO
      bool parseBool(dynamic value) {
        if (value == null) return false;
        if (value is bool) return value;
        if (value is String) {
          final str = value.toLowerCase().trim();
          return str == 'true' || str == '1' || str == 'yes' || str == 'on';
        }
        if (value is int) return value == 1;
        if (value is double) return value == 1.0;
        return false;
      }

      // ✅ EXTRAER VALORES DEL MAPA SANITIZADO
      final id = sanitizedMap['id']?.toString() ?? '';
      final chatId = sanitizedMap['chat_id']?.toString() ?? '';
      final fromId = sanitizedMap['from_id']?.toString();
      final text = sanitizedMap['text']?.toString() ?? '';
      final type = parseMessageType(sanitizedMap['type']?.toString());
      final metadata = parseMetadata(sanitizedMap['metadata']);
      final createdAt = parseDateTime(sanitizedMap['created_at']);
      final read = parseBool(sanitizedMap['read']);
      final delivered = parseBool(sanitizedMap['delivered']);
      final readAt = parseNullableDateTime(sanitizedMap['read_at']);
      final deliveredAt = parseNullableDateTime(sanitizedMap['delivered_at']);
      final isSystem = parseBool(sanitizedMap['is_system']);
      final tempId = sanitizedMap['temp_id']?.toString();
      final isUploading = parseBool(sanitizedMap['is_uploading']);

      AppLogger.d('✅ Message.fromMap exitoso - ID: $id, Tipo: $type');

      return Message(
        id: id,
        chatId: chatId,
        fromId: fromId,
        text: text,
        type: type,
        metadata: metadata,
        createdAt: createdAt,
        read: read,
        delivered: delivered,
        readAt: readAt,
        deliveredAt: deliveredAt,
        isSystem: isSystem,
        tempId: tempId,
        isUploading: isUploading,
      );
    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO en Message.fromMap: $e');
      AppLogger.e('🔍 Mapa que causó el error: $map');
      
      // Retornar mensaje de error para evitar crash
      return Message(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        chatId: map['chat_id']?.toString() ?? 'unknown',
        text: 'Error cargando mensaje: ${e.toString().substring(0, 50)}',
        createdAt: DateTime.now(),
        isSystem: true,
        metadata: {'error': e.toString(), 'original_data': map.toString()},
      );
    }
  }

  // ✅ FUNCIONES HELPER PARA SANITIZAR DATOS
  static Map<String, dynamic> _sanitizeMapValue(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    
    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is Map) {
        result[key] = _sanitizeMapValue(value);
      } else if (value is List) {
        result[key] = _sanitizeListValue(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  static List<dynamic> _sanitizeListValue(List<dynamic> list) {
    return list.map((item) {
      if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map) {
        return _sanitizeMapValue(item);
      } else if (item is List) {
        return _sanitizeListValue(item);
      }
      return item;
    }).toList();
  }

  // ✅ toMap() COMPLETAMENTE CORREGIDO
  Map<String, dynamic> toMap() {
    try {
      // ✅ Preparar metadata para Supabase
      final preparedMetadata = TimeUtils.ensureJsonSerializable(metadata);
      
      final result = {
        'id': id,
        'chat_id': chatId,
        'from_id': fromId,
        'text': text,
        'type': type.name,
        'metadata': preparedMetadata,
        'created_at': createdAt.toIso8601String(),
        'read': read,
        'delivered': delivered,
        'read_at': readAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'is_system': isSystem,
        'temp_id': tempId,
        'is_uploading': isUploading,
      };
      
      // ✅ Verificar que el resultado sea JSON serializable
      if (!TimeUtils.isJsonSerializable(result)) {
        AppLogger.e('❌ Resultado toMap no es JSON serializable');
        result['metadata'] = {};
      }
      
      return result;
    } catch (e) {
      AppLogger.e('❌ Error en Message.toMap: $e');
      return {
        'id': id,
        'chat_id': chatId,
        'text': text,
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
        'read': read,
        'delivered': delivered,
        'is_system': isSystem,
      };
    }
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? fromId,
    String? text,
    MessageType? type,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? read,
    bool? delivered,
    DateTime? readAt,
    DateTime? deliveredAt,
    bool? isSystem,
    String? tempId,
    bool? isUploading,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      fromId: fromId ?? this.fromId,
      text: text ?? this.text,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      delivered: delivered ?? this.delivered,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isSystem: isSystem ?? this.isSystem,
      tempId: tempId ?? this.tempId,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  // ✅ FACTORY PARA MENSAJE TEMPORAL
  factory Message.temporary({
    required String chatId,
    required String fromId,
    required String text,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
    bool isUploading = false,
  }) {
    final tempId = Message.generateTempId();
    return Message(
      id: tempId,
      chatId: chatId,
      fromId: fromId,
      text: text,
      type: type,
      metadata: metadata,
      createdAt: DateTime.now(),
      read: false,
      delivered: false,
      tempId: tempId,
      isUploading: isUploading,
    );
  }

  // ✅ GETTERS DE CONVENIENCIA
  bool get isTextMessage => type == MessageType.text;
  bool get isImageMessage => type == MessageType.image;
  bool get isFileMessage => type == MessageType.file;
  bool get isAgreementMessage => type == MessageType.agreement;
  bool get isSystemMessage => type == MessageType.system || isSystem;

  String? get fileUrl => metadata['file_url'] as String?;
  String? get fileName => metadata['file_name'] as String?;
  String? get fileSize => metadata['file_size'] as String?;
  String? get mimeType => metadata['mime_type'] as String?;
  String? get agreementId => metadata['agreement_id'] as String?;
  String? get agreementType => metadata['agreement_type'] as String?;
  String? get agreementStatus => metadata['agreement_status'] as String?;

  bool get isValid {
    if (id.isEmpty && tempId == null) return false;
    if (chatId.isEmpty) return false;
    if (text.isEmpty && !isImageMessage && !isFileMessage) return false;
    return true;
  }

  String get preview {
    if (isImageMessage) return '🖼️ Imagen';
    if (isFileMessage) return '📎 $fileName';
    if (isAgreementMessage) return '🤝 Acuerdo enviado';
    if (isSystemMessage) return '🔔 $text';
    if (text.length > 30) return '${text.substring(0, 30)}...';
    return text;
  }

  @override
  List<Object?> get props => [
    id, chatId, fromId, text, type, metadata, createdAt,
    read, delivered, readAt, deliveredAt, isSystem, tempId, isUploading
  ];

  @override
  String toString() {
    return 'Message(id: $id, text: $text, type: $type, createdAt: $createdAt, tempId: $tempId)';
  }
  
  // ✅ MÉTODO PARA DIAGNÓSTICO
  void debug() {
    AppLogger.d('🔍 DEBUG MESSAGE:');
    AppLogger.d('   - ID: $id');
    AppLogger.d('   - Chat ID: $chatId');
    AppLogger.d('   - Text: $text');
    AppLogger.d('   - Type: $type');
    AppLogger.d('   - Created At: $createdAt');
    AppLogger.d('   - Read: $read');
    AppLogger.d('   - Delivered: $delivered');
    AppLogger.d('   - Is System: $isSystem');
    AppLogger.d('   - Is Temporary: $isTemporary');
    AppLogger.d('   - Metadata keys: ${metadata.keys.toList()}');
  }
}