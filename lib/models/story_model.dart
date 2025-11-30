import '../utils/logger.dart';

class Story {
  final String id;
  final List<String> imageUrls;
  final String? text;
  final String? productId;
  final String userId;
  final String username;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  Story({
    required this.id,
    required this.imageUrls,
    this.text,
    this.productId,
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
  });

  // ✅ GETTER para compatibilidad
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActiveAndNotExpired => isActive && !isExpired;
  
  // ✅ CORRECCIÓN: TIEMPO RESTANTE DESDE CREACIÓN HASTA EXPIRACIÓN (24 HORAS)
  String get timeRemaining {
    final now = DateTime.now();
    
    // Si ya expiró
    if (now.isAfter(expiresAt)) {
      return 'Expirada';
    }
    
    final difference = expiresAt.difference(now);
    
    // ✅ CALCULAR HORAS Y MINUTOS CORRECTAMENTE
    final totalHours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    
    if (totalHours >= 1) {
      if (minutes > 0) {
        return '${totalHours}h ${minutes}m';
      }
      return '${totalHours}h';
    } 
    else if (difference.inMinutes >= 1) {
      final remainingMinutes = difference.inMinutes;
      final seconds = difference.inSeconds.remainder(60);
      
      if (seconds > 0) {
        return '${remainingMinutes}m ${seconds}s';
      }
      return '${remainingMinutes}m';
    } 
    else {
      final seconds = difference.inSeconds;
      if (seconds <= 0) {
        return 'Expirada';
      }
      return '${seconds}s';
    }
  }

  // ✅ TIEMPO TRANSCURRIDO DESDE LA PUBLICACIÓN
  String get timeSincePublished {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora mismo';
    }
  }

  // ✅ PORCENTAJE DE PROGRESO CORREGIDO
  double get progressPercentage {
    final now = DateTime.now();
    final totalDuration = expiresAt.difference(createdAt).inSeconds.toDouble();
    final remainingDuration = expiresAt.difference(now).inSeconds.toDouble();
    
    if (totalDuration <= 0) return 0.0;
    if (remainingDuration <= 0) return 1.0;
    
    final elapsedDuration = totalDuration - remainingDuration;
    return elapsedDuration / totalDuration;
  }

  // ✅ TIEMPO RESTANTE EN SEGUNDOS (para animaciones)
  int get secondsRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now).inSeconds;
    return difference > 0 ? difference : 0;
  }

  // ✅ VERIFICAR SI FALTA POCO PARA EXPIRAR (menos de 1 hora)
  bool get isAboutToExpire {
    final now = DateTime.now();
    return expiresAt.difference(now).inHours < 1;
  }

  // ✅ VERIFICAR SI ES NUEVA (menos de 1 hora de publicada)
  bool get isNew {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 1;
  }

  // Resto del código permanece igual...
  factory Story.fromJson(Map<String, dynamic> json) {
    try {
      DateTime parseDate(String dateString) {
        try {
          return DateTime.parse(dateString).toLocal();
        } catch (e) {
          AppLogger.w('⚠️ Error parseando fecha: $dateString, usando fecha actual');
          return DateTime.now();
        }
      }

      final createdAt = parseDate(json['created_at'] ?? '');
      // ✅ GARANTIZAR QUE EXPIRE EN 24 HORAS EXACTAS
      final expiresAt = json['expires_at'] != null 
          ? parseDate(json['expires_at'])
          : createdAt.add(const Duration(hours: 24));

      List<String> imageUrls = [];
      
      if (json['image_urls'] != null && json['image_urls'] is List) {
        imageUrls = List<String>.from(json['image_urls']);
      } 
      else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
        imageUrls = [json['image_url'].toString()];
      }

      return Story(
        id: json['id']?.toString() ?? '',
        imageUrls: imageUrls,
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
      final now = DateTime.now();
      return Story(
        id: 'error-${now.millisecondsSinceEpoch}',
        imageUrls: [],
        userId: 'error',
        username: 'Error',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        isActive: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_urls': imageUrls,
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

  Story copyWith({
    String? id,
    List<String>? imageUrls,
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
      imageUrls: imageUrls ?? this.imageUrls,
      text: text ?? this.text,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isValid {
    return id.isNotEmpty && 
           imageUrls.isNotEmpty && 
           userId.isNotEmpty && 
           username.isNotEmpty;
  }

  int get imageCount => imageUrls.length;

  // ✅ Compatibilidad: getter esperado por algunas vistas/operaciones de edición
  // Devuelve las URLs de las imágenes como elementos editables simples.
  List<String> get editingElements => imageUrls;

  @override
  String toString() {
    return 'Story{id: $id, user: $username, created: $createdAt, expires: $expiresAt, timeRemaining: $timeRemaining}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}