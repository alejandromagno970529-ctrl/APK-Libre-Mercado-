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

  // ✅ NUEVOS CAMPOS PARA TIENDA PROFESIONAL
  final String? storeName;
  final String? storeDescription;
  final String? storeLogoUrl;
  final String? storeBannerUrl;
  final String? storeCategory;
  final String? storeAddress;
  final String? storePhone;
  final String? storeEmail;
  final String? storeWebsite;
  final String? storePolicy;
  final bool isStoreEnabled;
  final DateTime? storeCreatedAt;
  final Map<String, dynamic>? storeStats;

  // ✅ NUEVO: Contador real de productos
  final int? actualProductCount;

  // ✅ NUEVO: Campos para presencia en línea
  final bool isOnline;
  final DateTime? lastSeen;

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

    // ✅ NUEVOS PARÁMETROS DE TIENDA
    this.storeName,
    this.storeDescription,
    this.storeLogoUrl,
    this.storeBannerUrl,
    this.storeCategory,
    this.storeAddress,
    this.storePhone,
    this.storeEmail,
    this.storeWebsite,
    this.storePolicy,
    this.isStoreEnabled = false,
    this.storeCreatedAt,
    this.storeStats,
    
    // ✅ NUEVO: Contador real
    this.actualProductCount,

    // ✅ NUEVO: Presencia en línea
    this.isOnline = false,
    this.lastSeen,
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

      // ✅ NUEVO: CAMPOS DE TIENDA
      storeName: map['store_name'] as String?,
      storeDescription: map['store_description'] as String?,
      storeLogoUrl: map['store_logo_url'] as String?,
      storeBannerUrl: map['store_banner_url'] as String?,
      storeCategory: map['store_category'] as String?,
      storeAddress: map['store_address'] as String?,
      storePhone: map['store_phone'] as String?,
      storeEmail: map['store_email'] as String?,
      storeWebsite: map['store_website'] as String?,
      storePolicy: map['store_policy'] as String?,
      isStoreEnabled: map['is_store_enabled'] as bool? ?? false,
      storeCreatedAt: map['store_created_at'] != null
          ? DateTime.parse(map['store_created_at'])
          : null,
      storeStats: map['store_stats'] != null
          ? Map<String, dynamic>.from(map['store_stats'])
          : {'total_products': 0, 'total_sales': 0, 'store_rating': 0.0},
      
      // ✅ NUEVO: Contador real desde la base de datos
      actualProductCount: map['actual_product_count'] as int? ?? 0,

      // ✅ NUEVO: Presencia en línea
      isOnline: map['is_online'] as bool? ?? false,
      lastSeen: map['last_seen'] != null
          ? DateTime.parse(map['last_seen'])
          : null,
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

      // ✅ NUEVO: CAMPOS DE TIENDA
      'store_name': storeName,
      'store_description': storeDescription,
      'store_logo_url': storeLogoUrl,
      'store_banner_url': storeBannerUrl,
      'store_category': storeCategory,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'store_email': storeEmail,
      'store_website': storeWebsite,
      'store_policy': storePolicy,
      'is_store_enabled': isStoreEnabled,
      'store_created_at': storeCreatedAt?.toIso8601String(),
      'store_stats': storeStats,
      
      // ✅ NUEVO: Contador real
      'actual_product_count': actualProductCount,

      // ✅ NUEVO: Presencia en línea
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  // ✅ GETTERS PARA TIENDA PROFESIONAL - CORREGIDOS

  bool get hasStore => isStoreEnabled && storeName != null && storeName!.isNotEmpty;

  String get storeDisplayName => storeName ?? 'Mi Tienda';

  String get storeCategoryText => storeCategory ?? 'General';

  String get storeContactInfo {
    final parts = <String>[];
    if (storePhone != null && storePhone!.isNotEmpty) parts.add(storePhone!);
    if (storeEmail != null && storeEmail!.isNotEmpty) parts.add(storeEmail!);
    if (parts.isEmpty) return 'Sin información de contacto';
    return parts.join(' • ');
  }

  String get storeLocationText => storeAddress ?? 'Ubicación no especificada';

  // ✅ CORREGIDO: Usar el contador real en lugar de storeStats
  int get storeTotalProducts => actualProductCount ?? storeStats?['total_products'] ?? 0;
  int get storeTotalSales => storeStats?['total_sales'] ?? 0;
  double get storeRating => (storeStats?['store_rating'] as num?)?.toDouble() ?? 0.0;

  // ✅ CORREGIDO: Mostrar el número real de productos
  String get storeStatsText {
    return '$storeTotalProducts productos • $storeTotalSales ventas';
  }

  String get storeRatingText {
    if (storeTotalProducts == 0) return 'Sin valoraciones';
    return '${storeRating.toStringAsFixed(1)} ⭐';
  }

  bool get isProfessionalStore {
    return hasStore && storeTotalProducts >= 5 && storeRating >= 4.0;
  }

  String get storeBadge {
    if (!hasStore) return 'Tienda Personal';
    if (isProfessionalStore) return '🏪 Tienda Profesional';
    return '🏪 Tienda';
  }

  // ✅ NUEVO: Getters para presencia en línea
  String get onlineStatus {
    if (isOnline) return 'En línea';
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      if (difference.inMinutes < 1) return 'En línea';
      if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
      return 'Hace ${difference.inDays} d';
    }
    return 'Desconectado';
  }

  // ✅ MÉTODO COPYWITH ACTUALIZADO
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

    // ✅ NUEVOS PARÁMETROS DE TIENDA
    String? storeName,
    String? storeDescription,
    String? storeLogoUrl,
    String? storeBannerUrl,
    String? storeCategory,
    String? storeAddress,
    String? storePhone,
    String? storeEmail,
    String? storeWebsite,
    String? storePolicy,
    bool? isStoreEnabled,
    DateTime? storeCreatedAt,
    Map<String, dynamic>? storeStats,
    
    // ✅ NUEVO: Contador real
    int? actualProductCount,

    // ✅ NUEVO: Presencia en línea
    bool? isOnline,
    DateTime? lastSeen,
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

      // ✅ NUEVO: CAMPOS DE TIENDA
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      storeBannerUrl: storeBannerUrl ?? this.storeBannerUrl,
      storeCategory: storeCategory ?? this.storeCategory,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeEmail: storeEmail ?? this.storeEmail,
      storeWebsite: storeWebsite ?? this.storeWebsite,
      storePolicy: storePolicy ?? this.storePolicy,
      isStoreEnabled: isStoreEnabled ?? this.isStoreEnabled,
      storeCreatedAt: storeCreatedAt ?? this.storeCreatedAt,
      storeStats: storeStats ?? this.storeStats,
      
      // ✅ NUEVO: Contador real
      actualProductCount: actualProductCount ?? this.actualProductCount,

      // ✅ NUEVO: Presencia en línea
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  String toString() {
    return 'AppUser{id: $id, email: $email, username: $username, hasStore: $hasStore, storeName: $storeName, actualProductCount: $actualProductCount, isOnline: $isOnline}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  get name => null;

  // Compatibilidad para getters usados por StoreProvider
  String get fullName => username;

  int get storeRatingCount {
    if (totalRatings != null) return totalRatings!;
    if (storeStats != null && storeStats!['total_ratings'] != null) {
      return storeStats!['total_ratings'] as int;
    }
    return 0;
  }
}