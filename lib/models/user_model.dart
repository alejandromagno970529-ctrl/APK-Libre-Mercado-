class AppUser {
  final String id;
  final String email;
  final String username;
  final double? rating;
  final int? totalRatings;
  final DateTime? joinedAt;
  final String? bio;
  final String? phone;
  final String? avatarUrl;
  final bool? isVerified;
  final int? successfulTransactions;
  final DateTime? lastActive;
  final Map<String, dynamic>? transactionStats;

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    this.rating,
    this.totalRatings,
    this.joinedAt,
    this.bio,
    this.phone,
    this.avatarUrl,
    this.isVerified,
    this.successfulTransactions,
    this.lastActive,
    this.transactionStats,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username']?.toString() ?? 'Usuario',
      rating: (map['rating'] as num?)?.toDouble(),
      totalRatings: map['total_ratings'] as int?,
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'])
          : DateTime.now(),
      bio: map['bio'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
      successfulTransactions: map['successful_transactions'] as int? ?? 0,
      lastActive: map['last_active'] != null
          ? DateTime.parse(map['last_active'])
          : DateTime.now(),
      transactionStats: map['transaction_stats'] != null
          ? Map<String, dynamic>.from(map['transaction_stats'])
          : {'total': 0, 'as_buyer': 0, 'as_seller': 0},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'rating': rating,
      'total_ratings': totalRatings,
      'joined_at': joinedAt?.toIso8601String(),
      'bio': bio,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'successful_transactions': successfulTransactions,
      'last_active': lastActive?.toIso8601String(),
      'transaction_stats': transactionStats,
    };
  }

  // ✅ GETTERS PARA REPUTACIÓN

  String get reputationText {
    if (totalRatings == null || totalRatings == 0) return 'Sin valoraciones';
    return '${rating?.toStringAsFixed(1) ?? "0.0"} ⭐ ($totalRatings valoraciones)';
  }

  bool get isReliableSeller {
    return (rating ?? 0) >= 4.0 && (totalRatings ?? 0) >= 3;
  }

  String get verificationText {
    return isVerified == true ? '✅ Verificado' : '⏳ Pendiente';
  }

  String get joinedTimeText {
    if (joinedAt == null) return 'Recién unido';

    final now = DateTime.now();
    final difference = now.difference(joinedAt!);

    if (difference.inDays < 1) {
      return 'Se unió hoy';
    } else if (difference.inDays < 30) {
      return 'Se unió hace ${difference.inDays} días';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Se unió hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Se unió hace $years ${years == 1 ? 'año' : 'años'}';
    }
  }

  String get reputationBadge {
    if (totalRatings == null || totalRatings == 0) return 'Nuevo';

    final userRating = rating ?? 0;

    if (userRating >= 4.5 && totalRatings! >= 10) return '⭐ Excelente';
    if (userRating >= 4.0 && totalRatings! >= 5) return '👍 Confiable';
    if (userRating >= 3.0) return '✅ Bueno';
    if (userRating >= 2.0) return '⚠️ Regular';
    return '❌ Malo';
  }

  String get reputationColor {
    if (totalRatings == null || totalRatings == 0) return 'grey';

    final userRating = rating ?? 0;

    if (userRating >= 4.0) return 'green';
    if (userRating >= 3.0) return 'orange';
    return 'red';
  }

  // ✅ GETTERS PARA INFORMACIÓN DE CONTACTO

  bool get hasContactInfo {
    return (phone != null && phone!.isNotEmpty) || (email.isNotEmpty);
  }

  String get contactInfo {
    if (phone != null && phone!.isNotEmpty) return phone!;
    if (email.isNotEmpty) return email;
    return 'Sin información de contacto';
  }

  // ✅ GETTERS PARA TRANSACCIONES Y ACTIVIDAD

  String get transactionsText {
    final total = successfulTransactions ?? 0;
    if (total == 0) return 'Sin transacciones';
    return '$total transacción${total != 1 ? 'es' : ''} exitosa${total != 1 ? 's' : ''}';
  }

  String get transactionStatsText {
    final stats = transactionStats ?? {'total': 0, 'as_buyer': 0, 'as_seller': 0};
    final total = stats['total'] ?? 0;
    final asBuyer = stats['as_buyer'] ?? 0;
    final asSeller = stats['as_seller'] ?? 0;
    
    return 'Total: $total • Comprador: $asBuyer • Vendedor: $asSeller';
  }

  double get completionRate {
    final stats = transactionStats ?? {'total': 0, 'as_buyer': 0, 'as_seller': 0};
    final total = (stats['total'] ?? 0) as int;
    final successful = successfulTransactions ?? 0;
    
    if (total == 0) return 0.0;
    return (successful / total) * 100;
  }

  String get activityStatus {
    if (lastActive == null) return 'Recién unido';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive!);
    
    if (difference.inMinutes < 5) return 'En línea';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} d';
    return 'Hace ${(difference.inDays / 7).floor()} sem';
  }

  // ✅ MÉTODO COPYWITH

  AppUser copyWith({
    String? id,
    String? email,
    String? username,
    double? rating,
    int? totalRatings,
    DateTime? joinedAt,
    String? bio,
    String? phone,
    String? avatarUrl,
    bool? isVerified,
    int? successfulTransactions,
    DateTime? lastActive,
    Map<String, dynamic>? transactionStats,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      joinedAt: joinedAt ?? this.joinedAt,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      successfulTransactions: successfulTransactions ?? this.successfulTransactions,
      lastActive: lastActive ?? this.lastActive,
      transactionStats: transactionStats ?? this.transactionStats,
    );
  }

  @override
  String toString() {
    return 'AppUser{id: $id, email: $email, username: $username, rating: $rating, totalRatings: $totalRatings, isVerified: $isVerified}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}