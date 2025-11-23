class Rating {
  final String id;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String? comment;
  final String? transactionId;
  final DateTime createdAt;
  final String? fromUserName;
  final String? fromUserEmail;

  Rating({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    this.transactionId,
    required this.createdAt,
    this.fromUserName,
    this.fromUserEmail,
  });

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'] as String,
      fromUserId: map['from_user_id'] as String,
      toUserId: map['to_user_id'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      transactionId: map['transaction_id'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      fromUserName: map['from_user_name'] as String?,
      fromUserEmail: map['from_user_email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
      'comment': comment,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'from_user_name': fromUserName,
      'from_user_email': fromUserEmail,
    };
  }
}