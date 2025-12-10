// lib/models/notification_model.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:convert';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;
  final String? chatId;
  final String? productId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.read = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
    this.chatId,
    this.productId,
  });

  // ✅ CORREGIDO: Método fromMap con parsing robusto de fechas
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    // ✅ FUNCIÓN HELPER PARA PARSEAR FECHAS
    DateTime parseDateTime(dynamic dateValue) {
      try {
        if (dateValue == null) return DateTime.now();
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) {
          // Si la cadena está vacía
          if (dateValue.isEmpty) return DateTime.now();
          return DateTime.parse(dateValue);
        }
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    DateTime? parseNullableDateTime(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) {
          // Si la cadena está vacía
          if (dateValue.isEmpty) return null;
          return DateTime.parse(dateValue);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    Map<String, dynamic> metadata = {};
    if (map['metadata'] != null) {
      if (map['metadata'] is String) {
        try {
          metadata = Map<String, dynamic>.from(json.decode(map['metadata'] as String));
        } catch (e) {
          metadata = {'parse_error': e.toString()};
        }
      } else if (map['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(map['metadata'] as Map);
      }
    }

    return AppNotification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      read: map['read'] as bool? ?? false,
      // ✅ CORREGIDO: Usar parseDateTime
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseNullableDateTime(map['updated_at']),
      metadata: metadata,
      chatId: map['chat_id']?.toString(),
      productId: map['product_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': json.encode(metadata),
      'chat_id': chatId,
      'product_id': productId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? chatId,
    String? productId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      chatId: chatId ?? this.chatId,
      productId: productId ?? this.productId,
    );
  }

  // ✅ MÉTODOS DE CONVENIENCIA
  bool get isChatMessage => type == 'chat_message';
  bool get isSystem => type == 'system';
  bool get isAgreement => type == 'agreement';

  String get senderName => metadata['from_user'] ?? 'Sistema';
  String get productTitle => metadata['product_title'] ?? '';
  String get messagePreview => metadata['message_preview'] ?? '';

  static List<AppNotification> fromList(List<dynamic> list) {
    return list.map((item) => AppNotification.fromMap(item as Map<String, dynamic>)).toList();
  }
}