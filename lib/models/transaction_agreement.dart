class TransactionAgreement {
  final String id;
  final String chatId;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double agreedPrice;
  final String meetingLocation;
  final DateTime meetingTime;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransactionAgreement({
    required this.id,
    required this.chatId,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.agreedPrice,
    required this.meetingLocation,
    required this.meetingTime,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransactionAgreement.fromJson(Map<String, dynamic> json) {
    return TransactionAgreement(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      agreedPrice: (json['agreed_price'] as num).toDouble(),
      meetingLocation: json['meeting_location'] as String,
      meetingTime: DateTime.parse(json['meeting_time'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'agreed_price': agreedPrice,
      'meeting_location': meetingLocation,
      'meeting_time': meetingTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForInsert() {
    final json = {
      'chat_id': chatId,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'agreed_price': agreedPrice,
      'meeting_location': meetingLocation,
      'meeting_time': meetingTime.toIso8601String(),
      'status': status,
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  factory TransactionAgreement.createNew({
    required String chatId,
    required String productId,
    required String buyerId,
    required String sellerId,
    required double agreedPrice,
    required String meetingLocation,
    required DateTime meetingTime,
  }) {
    return TransactionAgreement(
      id: '',
      chatId: chatId,
      productId: productId,
      buyerId: buyerId,
      sellerId: sellerId,
      agreedPrice: agreedPrice,
      meetingLocation: meetingLocation,
      meetingTime: meetingTime,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }
}