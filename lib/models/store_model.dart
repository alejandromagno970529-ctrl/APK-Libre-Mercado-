// lib/models/store_model.dart - VERSIÓN ACTUALIZADA CON DATOS EN TIEMPO REAL

// Clase ligera para representar una ubicación (reemplaza GeoPoint de Firestore)
class StoreLocation {
  final double latitude;
  final double longitude;

  StoreLocation(this.latitude, this.longitude);
}

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String? imageUrl;
  final String? coverImageUrl;
  final String category;
  final String? address;
  final StoreLocation? location;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final bool isActive;
  final bool isProfessionalStore;
  final String? phone;
  final String? email;
  final int productCount;
  final int totalSales;
  final bool isVerified;

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    this.imageUrl,
    this.coverImageUrl,
    required this.category,
    this.address,
    this.location,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
    this.isActive = true,
    this.isProfessionalStore = false,
    this.phone,
    this.email,
    this.productCount = 0,
    this.totalSales = 0,
    this.isVerified = false,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    // Manejo robusto de timestamps
    DateTime parseCreatedAt() {
      try {
        final createdAtString = map['created_at']?.toString();
        if (createdAtString == null || createdAtString.isEmpty) {
          return DateTime.now().toLocal();
        }
        
        var dateTime = DateTime.parse(createdAtString);
        if (!createdAtString.endsWith('Z') && !createdAtString.contains('+')) {
          dateTime = dateTime.toUtc();
        }
        
        return dateTime.toLocal();
      } catch (e) {
        return DateTime.now().toLocal();
      }
    }

    // Manejo de GeoPoint
    StoreLocation? parseLocation() {
      try {
        if (map['location'] is Map) {
          final locationMap = Map<String, dynamic>.from(map['location']);
          return StoreLocation(
            (locationMap['latitude'] ?? locationMap['lat'] ?? 0.0).toDouble(),
            (locationMap['longitude'] ?? locationMap['lng'] ?? 0.0).toDouble(),
          );
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return StoreModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['store_name']?.toString() ?? '',
      description: map['description']?.toString() ?? map['store_description']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? map['user_id']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? map['store_logo_url']?.toString(),
      coverImageUrl: map['cover_image_url']?.toString() ?? map['store_banner_url']?.toString(),
      category: map['category']?.toString() ?? map['store_category']?.toString() ?? 'General',
      address: map['address']?.toString() ?? map['store_address']?.toString(),
      location: parseLocation(),
      rating: (map['rating'] is num ? map['rating'] : double.tryParse(map['rating']?.toString() ?? '0'))?.toDouble() ?? 0.0,
      ratingCount: (map['rating_count'] is int ? map['rating_count'] : int.tryParse(map['rating_count']?.toString() ?? '0')) ?? 0,
      createdAt: parseCreatedAt(),
      isActive: map['is_active']?.toString() == 'true' || map['is_active'] == true || map['is_store_enabled'] == true,
      isProfessionalStore: map['is_professional_store']?.toString() == 'true' || map['is_professional_store'] == true,
      phone: map['phone']?.toString() ?? map['store_phone']?.toString(),
      email: map['email']?.toString() ?? map['store_email']?.toString(),
      productCount: (map['product_count'] is int ? map['product_count'] : int.tryParse(map['product_count']?.toString() ?? '0')) ?? 0,
      totalSales: (map['total_sales'] is int ? map['total_sales'] : int.tryParse(map['total_sales']?.toString() ?? '0')) ?? 0,
      isVerified: map['is_verified']?.toString() == 'true' || map['is_verified'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'image_url': imageUrl,
      'cover_image_url': coverImageUrl,
      'category': category,
      'address': address,
      'location': location != null ? {
        'latitude': location!.latitude,
        'longitude': location!.longitude,
      } : null,
      'rating': rating,
      'rating_count': ratingCount,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'is_professional_store': isProfessionalStore,
      'phone': phone,
      'email': email,
      'product_count': productCount,
      'total_sales': totalSales,
      'is_verified': isVerified,
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? imageUrl,
    String? coverImageUrl,
    String? category,
    String? address,
    StoreLocation? location,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    bool? isActive,
    bool? isProfessionalStore,
    String? phone,
    String? email,
    int? productCount,
    int? totalSales,
    bool? isVerified,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      address: address ?? this.address,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isProfessionalStore: isProfessionalStore ?? this.isProfessionalStore,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      productCount: productCount ?? this.productCount,
      totalSales: totalSales ?? this.totalSales,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // ✅ NUEVO: GETTERS MEJORADOS PARA DATOS EN TIEMPO REAL
  String get ratingText => rating > 0 ? '$rating ($ratingCount reseñas)' : 'Sin calificaciones';
  String get productCountText => '$productCount ${productCount == 1 ? 'producto' : 'productos'}';
  String get salesText => '$totalSales ${totalSales == 1 ? 'venta' : 'ventas'}';
  
  // ✅ NUEVO: Verificar si tiene datos reales
  bool get hasRealData => productCount > 0 || totalSales > 0;
  
  // ✅ NUEVO: Estadísticas en tiempo real
  String get realTimeStats {
    if (productCount == 0) return 'Sin productos aún';
    return '$productCountText • $salesText • ⭐ $rating';
  }
  
  // ✅ NUEVO: Determinar si necesita actualización
  bool get needsDataRefresh {
    return isActive && productCount == 0;
  }

  // ✅ NUEVO: Método para actualizar con datos reales
  StoreModel updateWithRealData({
    int? realProductCount,
    int? realTotalSales,
    double? realRating,
    int? realRatingCount,
  }) {
    return copyWith(
      productCount: realProductCount ?? productCount,
      totalSales: realTotalSales ?? totalSales,
      rating: realRating ?? rating,
      ratingCount: realRatingCount ?? ratingCount,
    );
  }

  // Getters existentes mantenidos
  bool get hasLocation => location != null;
  bool get hasCoverImage => coverImageUrl != null && coverImageUrl!.isNotEmpty;
  bool get hasLogoImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StoreModel(id: $id, name: $name, category: $category, rating: $rating, products: $productCount, sales: $totalSales)';
  }
}