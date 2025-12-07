import 'dart:convert';

class ServiceModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final List<String>? images;
  final String location;
  final double? latitude;
  final double? longitude;
  final String serviceType;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final double? rating;
  final int? totalReviews;
  final Map<String, dynamic>? metadata;

  ServiceModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.priceUnit,
    this.images,
    required this.location,
    this.latitude,
    this.longitude,
    required this.serviceType,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.rating,
    this.totalReviews,
    this.metadata,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: map['price_unit'] ?? 'por servicio',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      serviceType: map['service_type'] ?? 'fijo',
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      isActive: map['is_active'] ?? true,
      rating: (map['rating'] as num?)?.toDouble(),
      totalReviews: map['total_reviews'] as int?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'price_unit': priceUnit,
      'images': images,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'service_type': serviceType,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'rating': rating,
      'total_reviews': totalReviews,
      'metadata': metadata,
    };
  }

  String toJson() => json.encode(toMap());
  factory ServiceModel.fromJson(String source) => 
      ServiceModel.fromMap(json.decode(source));
}