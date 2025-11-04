class Product {
  final String id;
  final String titulo;
  final String? descripcion;
  final double precio;
  final String categorias;
  final String? imagenUrl;
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
    required this.precio,
    required this.categorias,
    this.imagenUrl,
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

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString(),
      precio: (map['precio'] is num ? map['precio'] : double.tryParse(map['precio']?.toString() ?? '0'))?.toDouble() ?? 0.0,
      categorias: map['categorias']?.toString() ?? map['categoria']?.toString() ?? 'Otros',
      imagenUrl: map['imagen_url']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
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
      'precio': precio,
      'categorias': categorias,
      'imagen_url': imagenUrl,
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

  String get precioFormateado {
    return '\$$precio ${moneda == 'USD' ? 'USD' : 'CUP'}';
  }

  bool get hasLocation => latitud != 0 && longitud != 0;

  String get formattedLocation {
    return address ?? 'Ubicación: $latitud, $longitud';
  }
}