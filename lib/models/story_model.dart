import '../utils/logger.dart';

class Story {
  final String id;
  final String imageUrl;
  final String? text;
  final String? productId;
  final String userId;
  final String username;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  Story({
    required this.id,
    required this.imageUrl,
    this.text,
    this.productId,
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });

  // ✅ GETTERS MEJORADOS
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActiveAndNotExpired => isActive && !isExpired;
  
  // ✅ TIEMPO RESTANTE MEJORADO
  String get timeRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds}s';
    } else {
      return 'Expirada';
    }
  }

  // ✅ PORCENTAJE DE PROGRESO (para círculo de progreso)
  double get progressPercentage {
    final now = DateTime.now();
    final totalDuration = expiresAt.difference(createdAt).inSeconds;
    final elapsedDuration = now.difference(createdAt).inSeconds;
    
    if (totalDuration <= 0 || elapsedDuration <= 0) return 0.0;
    if (elapsedDuration >= totalDuration) return 1.0;
    
    return elapsedDuration / totalDuration;
  }

  // ✅ FACTORY METHOD MEJORADO
  factory Story.fromJson(Map<String, dynamic> json) {
    try {
      // Manejar fechas de forma segura
      DateTime parseDate(String dateString) {
        try {
          return DateTime.parse(dateString).toLocal();
        } catch (e) {
          AppLogger.w('⚠️ Error parseando fecha: $dateString, usando fecha actual');
          return DateTime.now();
        }
      }

      final createdAt = parseDate(json['created_at'] ?? '');
      final expiresAt = json['expires_at'] != null 
          ? parseDate(json['expires_at'])
          : createdAt.add(const Duration(hours: 24));

      return Story(
        id: json['id']?.toString() ?? '',
        imageUrl: json['image_url']?.toString() ?? '',
        text: json['text']?.toString(),
        productId: json['product_id']?.toString(),
        userId: json['user_id']?.toString() ?? '',
        username: json['username']?.toString() ?? 'Usuario',
        createdAt: createdAt,
        expiresAt: expiresAt,
        isActive: json['is_active'] ?? true,
      );
    } catch (e) {
      AppLogger.e('Error en Story.fromJson', e);
      // Retornar una story por defecto en caso de error
      final now = DateTime.now();
      return Story(
        id: 'error-${now.millisecondsSinceEpoch}',
        imageUrl: '',
        userId: 'error',
        username: 'Error',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        isActive: false,
      );
    }
  }

  // ✅ TO JSON MEJORADO
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'text': text,
      'product_id': productId,
      'user_id': userId,
      'username': username,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'is_active': isActive,
    };
  }

  // ✅ MÉTODO PARA COPIAR CON NUEVOS VALORES
  Story copyWith({
    String? id,
    String? imageUrl,
    String? text,
    String? productId,
    String? userId,
    String? username,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return Story(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // ✅ MÉTODO PARA VERIFICAR SI ES VÁLIDA
  bool get isValid {
    return id.isNotEmpty && 
           imageUrl.isNotEmpty && 
           userId.isNotEmpty && 
           username.isNotEmpty;
  }

  // ✅ OVERRIDE DE toString PARA DEBUG
  @override
  String toString() {
    return 'Story{id: $id, user: $username, active: $isActive, expired: $isExpired, timeRemaining: $timeRemaining}';
  }

  // ✅ OVERRIDE DE equals Y hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}