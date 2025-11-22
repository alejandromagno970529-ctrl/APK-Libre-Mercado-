class Chat {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;
  final String? productCurrency;
  final String? lastMessage;
  final bool? productAvailable;
  final int unreadCount;
  final String? otherUserName; // ✅ NUEVO: Nombre del otro usuario

  Chat({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.createdAt,
    required this.updatedAt,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.productCurrency,
    this.lastMessage,
    this.productAvailable,
    this.unreadCount = 0,
    this.otherUserName, // ✅ NUEVO
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at']);
    
    final updatedAt = map['updated_at'] != null
        ? DateTime.parse(map['updated_at'])
        : createdAt;

    return Chat(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
      productTitle: map['products']?['title'] as String?,
      productImage: map['products']?['image_url'] as String?,
      productPrice: map['products']?['precio'] != null
          ? (map['products']['precio'] as num).toDouble()
          : null,
      productCurrency: map['products']?['moneda'] as String?,
      productAvailable: map['products']?['disponible'] as bool?,
      otherUserName: map['other_user_name'] as String?, // ✅ NUEVO
    );
  }

  String getOtherUserId(String currentUserId) {
    if (currentUserId == sellerId) return buyerId;
    if (currentUserId == buyerId) return sellerId;
    throw Exception('El usuario $currentUserId no es participante de este chat');
  }

  bool isParticipant(String userId) {
    return userId == buyerId || userId == sellerId;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Chat copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productTitle,
    String? productImage,
    double? productPrice,
    String? productCurrency,
    String? lastMessage,
    bool? productAvailable,
    int? unreadCount,
    String? otherUserName, // ✅ NUEVO
  }) {
    return Chat(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      productCurrency: productCurrency ?? this.productCurrency,
      lastMessage: lastMessage ?? this.lastMessage,
      productAvailable: productAvailable ?? this.productAvailable,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserName: otherUserName ?? this.otherUserName, // ✅ NUEVO
    );
  }
}