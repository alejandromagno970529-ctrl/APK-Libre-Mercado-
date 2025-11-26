// lib/models/message_model.dart
import 'dart:convert';

class Message {
  final String id;
  final String chatId;
  final String text;
  final String? fromId;
  final DateTime createdAt;
  final bool read;
  final bool isSystem;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    this.fromId,
    required this.createdAt,
    this.read = false,
    this.isSystem = false,
    this.type = MessageType.text,
    this.metadata,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      text: map['text'] as String,
      fromId: map['from_id'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      read: map['read'] as bool? ?? false,
      isSystem: map['is_system'] as bool? ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(json.decode(map['metadata'] as String))
          : null,
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
      'is_system': isSystem,
      'type': type.name,
      'metadata': metadata != null ? json.encode(metadata) : null,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? text,
    String? fromId,
    DateTime? createdAt,
    bool? read,
    bool? isSystem,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      fromId: fromId ?? this.fromId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      isSystem: isSystem ?? this.isSystem,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isSystemMessage => isSystem || fromId == null;
  bool get isFileMessage => type == MessageType.file;
  bool get isAudioMessage => type == MessageType.audio;
  bool get isImageMessage => type == MessageType.image;

  // Getters para archivos
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