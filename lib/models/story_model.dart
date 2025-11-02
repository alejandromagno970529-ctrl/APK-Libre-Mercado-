class Story {
  final String id;
  final String userId;
  final String username;
  final String? imageUrl;
  final String? text;
  final String? color;
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.userId,
    required this.username,
    this.imageUrl,
    this.text,
    this.color,
    required this.createdAt,
    required this.expiresAt,
  });

  // Verificar si la historia ha expirado
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Tiempo restante en formato legible
  String get timeRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Pronto';
    }
  }

  // Convertir desde JSON
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['image_url'],
      text: json['text'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(const Duration(hours: 24)).toString()),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'image_url': imageUrl,
      'text': text,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}