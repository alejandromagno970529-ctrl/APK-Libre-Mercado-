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
    );
  }

  String getOtherUserId(String currentUserId) {
    if (currentUserId == sellerId) return buyerId;
    if (currentUserId == buyerId) return sellerId;
    throw Exception('El usuario $currentUserId no es participante de este chat');
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
}