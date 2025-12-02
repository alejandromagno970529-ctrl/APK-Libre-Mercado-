// lib/models/message_model.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:convert';

class Message {
  final String id;
  final String chatId;
  final String text;
  final String? fromId;
  final DateTime createdAt;
  final bool read;
  final bool delivered; // ✅ NUEVO CAMPO
  final DateTime? readAt; // ✅ NUEVO CAMPO
  final DateTime? deliveredAt; // ✅ NUEVO CAMPO
  final bool isSystem;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final String? tempId;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    this.fromId,
    required this.createdAt,
    this.read = false,
    this.delivered = false, // ✅ VALOR POR DEFECTO
    this.readAt,
    this.deliveredAt,
    this.isSystem = false,
    this.type = MessageType.text,
    this.metadata,
    this.tempId,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      if (map['metadata'] is String) {
        try {
          metadata = Map<String, dynamic>.from(json.decode(map['metadata'] as String));
        } catch (e) {
          metadata = {'parse_error': 'Failed to parse metadata: $e'};
        }
      } else if (map['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(map['metadata'] as Map);
      }
    }

    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      text: map['text'] as String,
      fromId: map['from_id'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      read: map['read'] as bool? ?? false,
      delivered: map['delivered'] as bool? ?? false, // ✅ PARSEAR NUEVO CAMPO
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      deliveredAt: map['delivered_at'] != null ? DateTime.parse(map['delivered_at']) : null,
      isSystem: map['is_system'] as bool? ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      metadata: metadata,
      tempId: map['temp_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'text': text,
      'from_id': fromId,
      'created_at': createdAt.toIso8601String(),
      'read': read,
      'delivered': delivered, // ✅ INCLUIR NUEVO CAMPO
      'read_at': readAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'is_system': isSystem,
      'type': type.name,
      'metadata': metadata != null ? json.encode(metadata) : null,
      'temp_id': tempId,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? text,
    String? fromId,
    DateTime? createdAt,
    bool? read,
    bool? delivered,
    DateTime? readAt,
    DateTime? deliveredAt,
    bool? isSystem,
    MessageType? type,
    Map<String, dynamic>? metadata,
    String? tempId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      fromId: fromId ?? this.fromId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      delivered: delivered ?? this.delivered,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isSystem: isSystem ?? this.isSystem,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      tempId: tempId ?? this.tempId,
    );
  }

  // ✅ CORREGIDO: Generar ID temporal único sin usar UniqueKey
  static String generateTempId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 100000;
    return 'temp_${timestamp}_${userId}_$random';
  }

  bool get isTemporary => id.startsWith('temp_') || (tempId?.isNotEmpty ?? false);
  bool get isSystemMessage => isSystem || fromId == null;
  bool get isFileMessage => type == MessageType.file;
  bool get isAudioMessage => type == MessageType.audio;
  bool get isImageMessage => type == MessageType.image;
  bool get isUploading => metadata?['is_uploading'] == true;

  // ✅ NUEVOS GETTERS PARA ESTADOS
  bool get isSent => !isTemporary;
  bool get isDelivered => delivered;
  bool get isRead => read;
  
  // ✅ MÉTODO PARA OBTENER ICONO DE ESTADO
  String get statusIcon {
    if (isRead) return '✅✅'; // Dos palomillas azules
    if (isDelivered) return '✅✅'; // Dos palomillas grises
    if (isSent) return '✅'; // Una palomilla
    return '🕒'; // Reloj para enviando
  }

  String? get fileUrl => metadata?['file_url'];
  String? get fileName => metadata?['file_name'];
  String? get fileSize => metadata?['file_size'];
  String? get mimeType => metadata?['mime_type'];
}

enum MessageType {
  text,
  file,
  audio,
  image,
  agreement,
}