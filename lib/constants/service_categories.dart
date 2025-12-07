import 'package:flutter/material.dart';

class ServiceCategories {
  // Definimos los íconos como Material Icons en lugar de emojis
  static const Map<String, Map<String, dynamic>> categories = {
    'transport': {
      'id': 'transport',
      'name': 'Transporte',
      'icon': Icons.directions_car,  // Material Icon en lugar de emoji
      'description': 'Servicios de movilidad y envíos',
      'color': 0xFF4CAF50, // Verde
      'subcategories': ['Taxi', 'Delivery', 'Mensajería', 'Mudanzas', 'Traslados'],
    },
    'food': {
      'id': 'food',
      'name': 'Comida',
      'icon': Icons.restaurant,  // Material Icon
      'description': 'Restaurantes y servicios de comida',
      'color': 0xFFF44336, // Rojo
      'subcategories': ['Restaurante', 'Catering', 'Chef a domicilio', 'Repostería'],
    },
    'decoration': {
      'id': 'decoration',
      'name': 'Decoración',
      'icon': Icons.brush,  // Material Icon
      'description': 'Diseño y decoración de espacios',
      'color': 0xFF9C27B0, // Morado
      'subcategories': ['Interior', 'Exterior', 'Eventos', 'Jardinería'],
    },
    'construction': {
      'id': 'construction',
      'name': 'Construcción',
      'icon': Icons.handyman,  // Material Icon
      'description': 'Reparaciones y construcciones',
      'color': 0xFFFF9800, // Naranja
      'subcategories': ['Albañilería', 'Carpintería', 'Electricidad', 'Plomería'],
    },
    'beauty': {
      'id': 'beauty',
      'name': 'Belleza',
      'icon': Icons.spa,  // Material Icon
      'description': 'Cuidado personal y estética',
      'color': 0xFFE91E63, // Rosa
      'subcategories': ['Peluquería', 'Estética', 'Manicure', 'Barbería'],
    },
    'education': {
      'id': 'education',
      'name': 'Educación',
      'icon': Icons.school,  // Material Icon
      'description': 'Clases y tutorías',
      'color': 0xFF2196F3, // Azul
      'subcategories': ['Clases', 'Tutorías', 'Cursos', 'Idiomas'],
    },
    'technology': {
      'id': 'technology',
      'name': 'Tecnología',
      'icon': Icons.computer,  // Material Icon
      'description': 'Servicios tecnológicos',
      'color': 0xFF3F51B5, // Azul oscuro
      'subcategories': ['Reparación', 'Desarrollo', 'Soporte', 'Instalación'],
    },
    'events': {
      'id': 'events',
      'name': 'Eventos',
      'icon': Icons.celebration,  // Material Icon
      'description': 'Organización de eventos',
      'color': 0xFF00BCD4, // Cyan
      'subcategories': ['Fotografía', 'Música', 'Animación', 'Organización'],
    },
    'health': {
      'id': 'health',
      'name': 'Salud',
      'icon': Icons.medical_services,  // Material Icon
      'description': 'Servicios de salud y bienestar',
      'color': 0xFF009688, // Verde agua
      'subcategories': ['Masajes', 'Fisioterapia', 'Nutrición', 'Yoga'],
    },
    'cleaning': {
      'id': 'cleaning',
      'name': 'Limpieza',
      'icon': Icons.cleaning_services,  // Material Icon
      'description': 'Servicios de limpieza',
      'color': 0xFF795548, // Café
      'subcategories': ['Limpieza doméstica', 'Limpieza industrial', 'Lavandería'],
    },
  };

  static List<Map<String, dynamic>> get allCategories {
    return categories.values.toList();
  }

  static List<String> get allCategoryNames {
    return categories.values.map((cat) => cat['name'] as String).toList();
  }

  static Map<String, dynamic>? getCategoryById(String id) {
    return categories[id];
  }

  static List<String> getSubcategories(String categoryId) {
    return categories[categoryId]?['subcategories'] ?? [];
  }
}