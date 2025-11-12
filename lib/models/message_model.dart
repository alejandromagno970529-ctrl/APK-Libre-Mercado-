class Message {
  final String id;
  final String chatId;
  final String text;
  final String fromId;
  final DateTime createdAt;
  final bool read;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.fromId,
    required this.createdAt,
    this.read = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      text: map['text'] as String,
      fromId: map['from_id'] as String,
      createdAt: DateTime.parse(map['created_at']),
      read: map['read'] as bool? ?? false,
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
    );
  }
}