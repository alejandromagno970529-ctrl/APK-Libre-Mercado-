import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/service_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/service_provider.dart';
import '../../../widgets/service_card.dart';

class ServiceSearchScreen extends StatefulWidget {
  static const String routeName = '/service-search';
  final String initialQuery;

  // ignore: use_super_parameters
  const ServiceSearchScreen({
    Key? key,
    required this.initialQuery,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ServiceSearchScreenState createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final provider = Provider.of<ServiceProvider>(context, listen: false);
      final results = await provider.searchServices(_searchController.text);
      setState(() => _searchResults = results);
    } catch (error) {
      // ignore: avoid_print
      print('Error searching services: $error');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar servicios...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchResults.clear());
              },
            ),
          ),
          onSubmitted: (_) => _performSearch(),
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron servicios',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intenta con otras palabras clave',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final service = _searchResults[index];
                    return ServiceCard(
                      service: service,
                      onTap: () => _navigateToServiceDetail(service.id),
                    );
                  },
                ),
    );
  }

  void _navigateToServiceDetail(String serviceId) {
    Navigator.pushNamed(
      context,
      '/service-detail',
      arguments: serviceId,
    );
  }
}