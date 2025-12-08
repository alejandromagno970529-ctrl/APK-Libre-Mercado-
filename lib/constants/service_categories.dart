// 1. ACTUALIZAR service_categories.dart
// Archivo: lib/constants/service_categories.dart

import 'package:flutter/material.dart';

class ServiceCategories {
  static List<Map<String, dynamic>> allCategories = [
    {
      'id': 'transporte',
      'name': 'Transporte',
      'icon': Icons.directions_car_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'restauracion',
      'name': 'Restauración',
      'icon': Icons.restaurant_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'alojamiento',
      'name': 'Alojamiento',
      'icon': Icons.hotel_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'decoracion',
      'name': 'Decoración',
      'icon': Icons.brush_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'construccion',
      'name': 'Construcción',
      'icon': Icons.engineering_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'educacion',
      'name': 'Educación',
      'icon': Icons.school_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'salud',
      'name': 'Salud',
      'icon': Icons.medical_services_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'tecnologia',
      'name': 'Tecnología',
      'icon': Icons.computer_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'belleza',
      'name': 'Belleza',
      'icon': Icons.spa_rounded,
      'color': 0xFF000000, // Negro
    },
    {
      'id': 'otros',
      'name': 'Otros',
      'icon': Icons.more_horiz_rounded,
      'color': 0xFF000000, // Negro
    },
  ];

  static List<String> get allCategoryNames {
    return allCategories.map((cat) => cat['name'] as String).toList();
  }

  static Map<String, dynamic>? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat['id'] == id);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? getCategoryByName(String name) {
    try {
      return allCategories.firstWhere((cat) => cat['name'] == name);
    } catch (e) {
      return null;
    }
  }
}