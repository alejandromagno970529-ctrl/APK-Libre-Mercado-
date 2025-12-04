// lib/models/message_model.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';

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

  // ✅ MÉTODO ESTÁTICO CORREGIDO: SIN parámetros
  static String generateTempId([String? fromId]) {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'temp_${List.generate(12, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // ✅ GETTER: Saber si es mensaje temporal
  bool get isTemporary => tempId != null || id.startsWith('temp_');

  // ✅ NUEVAS FUNCIONES HELPER PARA SANITIZAR METADATA
  Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final Map<String, dynamic> sanitized = {};
    
    metadata.forEach((key, value) {
      try {
        if (value is DateTime) {
          // ✅ Convertir DateTime a String ISO
          sanitized[key] = value.toIso8601String();
        } else if (value is String && _looksLikeDateTime(value)) {
          // ✅ Si es String con formato de fecha, dejarla como está
          sanitized[key] = value;
        } else if (value is Map) {
          // ✅ Recursión para maps anidados
          sanitized[key] = _sanitizeMetadata(Map<String, dynamic>.from(value));
        } else if (value is List) {
          // ✅ Manejar listas
          sanitized[key] = _sanitizeList(value);
        } else {
          // ✅ Otros tipos (String, num, bool, null)
          sanitized[key] = value;
        }
      } catch (e) {
        // ✅ Si hay error con un campo específico, omitirlo
        sanitized[key] = value?.toString() ?? '';
      }
    });
    
    return sanitized;
  }

  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map) {
        return _sanitizeMetadata(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _sanitizeList(item);
      }
      return item;
    }).toList();
  }

  bool _looksLikeDateTime(String value) {
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

  // ✅ FACTORY CONSTRUCTOR COMPLETAMENTE CORREGIDO
  factory Message.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      try {
        if (date == null) return DateTime.now();
        if (date is String) return DateTime.parse(date);
        if (date is DateTime) return date;
        if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
        if (date is double) return DateTime.fromMillisecondsSinceEpoch(date.toInt());
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    MessageType parseMessageType(String? typeString) {
      try {
        if (typeString == null || typeString.isEmpty) return MessageType.text;
        return MessageType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeString.toLowerCase(),
          orElse: () => MessageType.text,
        );
      } catch (e) {
        return MessageType.text;
      }
    }

    // ✅ VERSIÓN CORREGIDA DE parseMetadata
    Map<String, dynamic> parseMetadata(dynamic metadata) {
      try {
        if (metadata == null) return {};
        
        if (metadata is String) {
          if (metadata.isEmpty) return {};
          
          // ✅ Si es String, decodificar JSON
          final decoded = json.decode(metadata) as Map<String, dynamic>?;
          if (decoded == null) return {};
          
          return Map<String, dynamic>.from(decoded);
          
        } else if (metadata is Map) {
          // ✅ Si ya es Map, convertir directamente
          return Map<String, dynamic>.from(metadata);
        }
        
        return {};
      } catch (e) {
        return {};
      }
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    }

    return Message(
      id: map['id']?.toString() ?? '',
      chatId: map['chat_id']?.toString() ?? '',
      fromId: map['from_id']?.toString(),
      text: map['text']?.toString() ?? '',
      type: parseMessageType(map['type']?.toString()),
      metadata: parseMetadata(map['metadata']),
      createdAt: parseDate(map['created_at']),
      read: parseBool(map['read']),
      delivered: parseBool(map['delivered']),
      readAt: map['read_at'] != null ? parseDate(map['read_at']) : null,
      deliveredAt: map['delivered_at'] != null ? parseDate(map['delivered_at']) : null,
      isSystem: parseBool(map['is_system']),
      tempId: map['temp_id']?.toString(),
      isUploading: parseBool(map['is_uploading']),
    );
  }

  // ✅ toMap() COMPLETAMENTE CORREGIDO
  Map<String, dynamic> toMap() {
    // ✅ Sanitizar metadata antes de enviar
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    
    return {
      'id': id,
      'chat_id': chatId,
      'from_id': fromId,
      'text': text,
      'type': type.name,
      // ✅ Enviar metadata como Map (Supabase lo manejará como JSONB)
      'metadata': sanitizedMetadata,
      'created_at': createdAt.toIso8601String(),
      'read': read,
      'delivered': delivered,
      'read_at': readAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'is_system': isSystem,
      'temp_id': tempId,
      'is_uploading': isUploading,
    };
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

  // ✅ FACTORY PARA MENSAJE TEMPORAL - LLAMADA CORRECTA
  factory Message.temporary({
    required String chatId,
    required String fromId,
    required String text,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
    bool isUploading = false,
  }) {
    // ✅ LLAMADA CORRECTA: Sin parámetros
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
    return 'Message(id: $id, text: $text, tempId: $tempId, isUploading: $isUploading)';
  }
}