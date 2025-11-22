// lib/screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/constants/app_categories.dart';

class CategoriesScreen extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesScreen({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    // Asumimos que AppCategories.categories devuelve una lista de objetos Category
    final categories = AppCategories.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todas las Categorías',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0), // Padding externo ajustado
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // ✅ SOLUCIÓN DEL OVERFLOW:
            // Un valor menor a 1.0 hace la tarjeta más alta que ancha.
            // 0.75 da suficiente espacio vertical para icono + texto de 2 líneas.
            childAspectRatio: 0.75, 
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryItem(category);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category) {
    final color = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);

    return Card(
      elevation: 2,
      // ignore: deprecated_member_use
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          widget.onCategorySelected(category.name);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 DISEÑO MEJORADO: Estilo "Squircle" (Cuadrado redondeado)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16), // Bordes suaves
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 12), // Espacio vertical
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Mapeo de colores mejorado para coincidir con los nuevos iconos
  Color _getCategoryColor(String categoryName) {
    // Convertimos a minúsculas para hacer la búsqueda más robusta
    final name = categoryName.toLowerCase();

    if (name.contains('tecnolog')) return Colors.blue;
    if (name.contains('ropa') || name.contains('accesorios')) return Colors.pinkAccent;
    if (name.contains('hogar') || name.contains('jardín')) return Colors.green;
    if (name.contains('deporte')) return Colors.orange;
    if (name.contains('electro')) return Colors.purple;
    if (name.contains('videojuego') || name.contains('gaming')) return Colors.deepPurple;
    if (name.contains('aliment') || name.contains('bebida')) return Colors.redAccent;
    if (name.contains('libro')) return Colors.indigo;
    if (name.contains('herramienta')) return Colors.blueGrey;
    if (name.contains('juguete')) return Colors.amber;
    if (name.contains('belleza')) return Colors.pink;
    if (name.contains('salud')) return Colors.teal;
    if (name.contains('auto') || name.contains('coche')) return Colors.red;
    if (name.contains('moto')) return Colors.deepOrange;
    if (name.contains('bici')) return Colors.lightGreen;
    if (name.contains('servicio')) return Colors.blueGrey;
    if (name.contains('inmueble') || name.contains('propiedad')) return Colors.brown;
    if (name.contains('mascota')) return Colors.cyan;
    if (name.contains('agri')) return Colors.green[800]!;
    if (name.contains('arte')) return Colors.purpleAccent;

    return Colors.grey;
  }

  // 🎨 Mapeo de iconos mejorado
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('tecnolog')) return Icons.devices_other;
    if (name.contains('ropa') || name.contains('accesorios')) return Icons.checkroom;
    if (name.contains('hogar')) return Icons.chair_outlined; // Icono más moderno para hogar
    if (name.contains('deporte')) return Icons.sports_soccer;
    if (name.contains('electro')) return Icons.kitchen;
    if (name.contains('videojuego')) return Icons.sports_esports;
    if (name.contains('aliment')) return Icons.restaurant_menu;
    if (name.contains('libro')) return Icons.auto_stories;
    if (name.contains('herramienta')) return Icons.home_repair_service;
    if (name.contains('juguete')) return Icons.toys_outlined;
    if (name.contains('belleza')) return Icons.face_retouching_natural;
    if (name.contains('salud')) return Icons.medical_services_outlined;
    if (name.contains('auto')) return Icons.directions_car_filled;
    if (name.contains('moto')) return Icons.two_wheeler;
    if (name.contains('bici')) return Icons.pedal_bike;
    if (name.contains('servicio')) return Icons.handyman_outlined;
    if (name.contains('inmueble')) return Icons.apartment;
    if (name.contains('mascota')) return Icons.pets;
    if (name.contains('agri')) return Icons.agriculture;
    if (name.contains('arte')) return Icons.palette_outlined;

    return Icons.category_outlined;
  }
}