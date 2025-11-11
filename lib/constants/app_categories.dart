import '../constants.dart';

class AppCategories {
  static List<Category> get categories {
    return AppStrings.productCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      
      return Category(
        id: (index + 1).toString(),
        name: name,
      );
    }).toList();
  }

  // Método helper para obtener una categoría por nombre
  static Category? getCategoryByName(String name) {
    try {
      return categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  // Método helper para obtener una categoría por id
  static Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener categorías populares (primeras 8 para el home)
  static List<Category> get popularCategories {
    return categories.take(8).toList();
  }
}

class Category {
  final String id;
  final String name;

  const Category({
    required this.id,
    required this.name,
  });

  // Conversión a mapa para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Crear desde mapa
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}