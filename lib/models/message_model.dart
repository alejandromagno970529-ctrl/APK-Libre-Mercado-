class Message {
  final String id;
  final String chatId;
  final String text;
  final String? fromId; // ✅ CAMBIADO: Ahora puede ser null
  final DateTime createdAt;
  final bool read;
  final bool isSystem;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    this.fromId, // ✅ CAMBIADO: Ahora puede ser null
    required this.createdAt,
    this.read = false,
    this.isSystem = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      text: map['text'] as String,
      fromId: map['from_id'] as String?, // ✅ CAMBIADO: Ahora puede ser null
      createdAt: DateTime.parse(map['created_at']),
      read: map['read'] as bool? ?? false,
      isSystem: map['is_system'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'text': text,
      'from_id': fromId, // ✅ CAMBIADO: Ahora puede ser null
      'created_at': createdAt.toIso8601String(),
      'read': read,
      'is_system': isSystem,
    };
  }

  Message markAsRead() {
    return Message(
      id: id,
      chatId: chatId,
      text: text,
      fromId: fromId,
      createdAt: createdAt,
      read: true,
      isSystem: isSystem,
    );
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? text,
    String? fromId,
    DateTime? createdAt,
    bool? read,
    bool? isSystem,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      fromId: fromId ?? this.fromId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  // ✅ NUEVO: Helper para verificar si es mensaje del sistema
  bool get isSystemMessage => isSystem || fromId == null;
}