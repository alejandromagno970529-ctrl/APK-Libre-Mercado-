// lib/models/product_model.dart - VERSIÓN COMPLETAMENTE CORREGIDA
class Product {
  final String id;
  final String titulo;
  final String? descripcion;
  final double? precio; // ✅ CAMBIADO A NULLABLE
  final String categorias;
  final List<String>? imagenUrls; // ✅ CAMBIADO A LISTA
  final String userId;
  final DateTime createdAt;
  final double latitud;
  final double longitud;
  final String? sellerId;
  final String moneda;
  final bool disponible;
  final String? address;
  final String? city;

  Product({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.precio, // ✅ AHORA ES OPCIONAL
    required this.categorias,
    this.imagenUrls, // ✅ LISTA DE IMÁGENES
    required this.userId,
    required this.createdAt,
    required this.latitud,
    required this.longitud,
    this.sellerId,
    this.moneda = 'CUP',
    this.disponible = true,
    this.address,
    this.city,
  });

  // ✅ CORREGIDO: Método fromMap con parsing robusto de fechas
  factory Product.fromMap(Map<String, dynamic> map) {
    // ✅ FUNCIÓN HELPER PARA PARSEAR FECHAS CON ZONA HORARIA
    DateTime parseDateTime(dynamic dateValue) {
      try {
        if (dateValue == null) return DateTime.now().toLocal();
        if (dateValue is DateTime) return dateValue.toLocal();
        if (dateValue is String) {
          // Si la cadena está vacía
          if (dateValue.isEmpty) return DateTime.now().toLocal();
          
          // Intentar parsear como UTC primero
          var dateTime = DateTime.parse(dateValue);
          
          // Si no tiene indicador de zona horaria, asumir UTC
          if (!dateValue.endsWith('Z') && !dateValue.contains('+')) {
            dateTime = dateTime.toUtc();
          }
          
          return dateTime.toLocal();
        }
        return DateTime.now().toLocal();
      } catch (e) {
        // ignore: avoid_print
        print('❌ Error parsing date: $e');
        return DateTime.now().toLocal();
      }
    }

    // ✅ CONVERTIR IMAGEN_URLS DE STRING A LISTA
    List<String>? imagenUrls = [];
    if (map['imagen_urls'] is List) {
      imagenUrls = List<String>.from(map['imagen_urls'] ?? []);
    } else if (map['imagen_url'] is String) {
      // ✅ COMPATIBILIDAD CON VERSIÓN ANTERIOR
      imagenUrls = [map['imagen_url']];
    }

    return Product(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      precio: map['precio'] != null 
          ? (map['precio'] is num ? map['precio'] : double.tryParse(map['precio']?.toString() ?? '0'))?.toDouble()
          : null,
      categorias: map['categorias']?.toString() ?? map['categoria']?.toString() ?? 'Otros',
      imagenUrls: imagenUrls, // ✅ LISTA DE IMÁGENES
      userId: map['user_id']?.toString() ?? '',
      createdAt: parseDateTime(map['created_at']), // ✅ USAR PARSER CORREGIDO
      latitud: (map['latitud'] is num ? map['latitud'] : double.tryParse(map['latitud']?.toString() ?? '0'))?.toDouble() ?? 0.0,
      longitud: (map['longitud'] is num ? map['longitud'] : double.tryParse(map['longitud']?.toString() ?? '0'))?.toDouble() ?? 0.0,
      sellerId: map['seller_id']?.toString(),
      moneda: map['moneda']?.toString() ?? 'CUP',
      disponible: map['disponible']?.toString() == 'true' || map['disponible'] == true,
      address: map['address']?.toString(),
      city: map['city']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio, // ✅ PUEDE SER NULL
      'categorias': categorias,
      'imagen_urls': imagenUrls, // ✅ LISTA DE IMÁGENES
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'latitud': latitud,
      'longitud': longitud,
      'seller_id': sellerId,
      'moneda': moneda,
      'disponible': disponible,
      'address': address,
      'city': city,
    };
  }

  // ✅ MÉTODO COPYWITH ACTUALIZADO
  Product copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    double? precio, // ✅ NULLABLE
    String? categorias,
    List<String>? imagenUrls, // ✅ LISTA DE IMÁGENES
    String? userId,
    DateTime? createdAt,
    double? latitud,
    double? longitud,
    String? sellerId,
    String? moneda,
    bool? disponible,
    String? address,
    String? city,
  }) {
    return Product(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      categorias: categorias ?? this.categorias,
      imagenUrls: imagenUrls ?? this.imagenUrls, // ✅ LISTA DE IMÁGENES
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      sellerId: sellerId ?? this.sellerId,
      moneda: moneda ?? this.moneda,
      disponible: disponible ?? this.disponible,
      address: address ?? this.address,
      city: city ?? this.city,
    );
  }

  // ✅ GETTER PARA IMAGEN PRINCIPAL (COMPATIBILIDAD)
  String? get imagenUrl => imagenUrls?.isNotEmpty == true ? imagenUrls!.first : null;

  String get precioFormateado {
    if (precio == null) {
      return 'Precio no especificado';
    }
    return '\$$precio ${moneda == 'USD' ? 'USD' : 'CUP'}';
  }

  bool get hasLocation => latitud != 0 && longitud != 0;

  String get formattedLocation {
    return address ?? 'Ubicación: $latitud, $longitud';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}