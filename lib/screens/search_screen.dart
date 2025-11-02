import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/screens/map_screen.dart';
// ✅ IMPORTAR la clase real ProductListScreen
import 'package:libre_mercado_final__app/screens/product/product_list_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = ['bicicleta', 'reloj', 'teléfono', 'laptop'];
  final List<String> _popularSearches = ['iPhone', 'zapatos', 'muebles', 'carro', 'casa'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Agregar a búsquedas recientes
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }

      // ✅ CORREGIDO: Usar la clase real ProductListScreen importada
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductListScreen(
            // Si ProductListScreen acepta parámetros de búsqueda, pasarlos aquí
            // searchQuery: query,
          ),
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRA DE BÚSQUEDA PRINCIPAL
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: Colors.amber, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onSubmitted: _performSearch,
            ),

            const SizedBox(height: 24),

            // MAPA DE OFERTAS
            _buildMapSection(),

            const SizedBox(height: 24),

            // BÚSQUEDAS RECIENTES
            if (_recentSearches.isNotEmpty) _buildRecentSearches(),

            const SizedBox(height: 24),

            // BÚSQUEDAS POPULARES
            _buildPopularSearches(),

            const SizedBox(height: 24),

            // CATEGORÍAS POPULARES
            _buildPopularCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(Colors.blue.withAlpha(25), Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Icon(Icons.map, size: 30, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mapa de Ofertas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ver productos cerca de ti',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(Colors.blue.withAlpha(25), Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Próximamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Búsquedas Recientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((search) {
            return ActionChip(
              label: Text(search),
              onPressed: () {
                _searchController.text = search;
                _performSearch(search);
              },
              backgroundColor: Colors.grey[100],
              labelStyle: const TextStyle(color: Colors.black87),
              avatar: const Icon(Icons.history, size: 16),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (_recentSearches.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
              child: const Text(
                'Limpiar historial',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPopularSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Búsquedas Populares',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearches.map((search) {
            return FilterChip(
              label: Text(search),
              onSelected: (selected) {
                _searchController.text = search;
                _performSearch(search);
              },
              backgroundColor: Color.alphaBlend(Colors.amber.withAlpha(25), Colors.white),
              selectedColor: Colors.amber,
              labelStyle: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularCategories() {
    final categories = [
      {'name': 'Tecnología', 'icon': Icons.computer, 'color': Colors.blue},
      {'name': 'Ropa', 'icon': Icons.shopping_bag, 'color': Colors.pink},
      {'name': 'Hogar', 'icon': Icons.home, 'color': Colors.green},
      {'name': 'Deportes', 'icon': Icons.sports_soccer, 'color': Colors.orange},
      {'name': 'Vehiculos', 'icon': Icons.directions_car, 'color': Colors.purple},
      {'name': 'Servicios', 'icon': Icons.build, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorías Populares',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(
                        // Si ProductListScreen acepta parámetros de categoría, pasarlos aquí
                        // category: category['name'] as String,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend((category['color'] as Color).withAlpha(25), Colors.white),
                        Color.alphaBlend((category['color'] as Color).withAlpha(12), Colors.white),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 30,
                        color: category['color'] as Color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: category['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}