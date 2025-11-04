class Story {
  final String id;
  final String userId;
  final String username;
  final String? imageUrl;
  final String? text;
  final String? color;
  final String? productId; // ✅ NUEVO: ID del producto relacionado
  final DateTime createdAt;
  final DateTime expiresAt;

  Story({
    required this.id,
    required this.userId,
    required this.username,
    this.imageUrl,
    this.text,
    this.color,
    this.productId, // ✅ NUEVO
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

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

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      imageUrl: json['image_url'],
      text: json['text'],
      color: json['color'],
      productId: json['product_id'], // ✅ NUEVO
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(const Duration(hours: 24)).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'image_url': imageUrl,
      'text': text,
      'color': color,
      'product_id': productId, // ✅ NUEVO
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}