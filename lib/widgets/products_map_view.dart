// lib/widgets/products_map_view.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:libre_mercado_final_app/models/product_model.dart';
import 'package:libre_mercado_final_app/services/location_service.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class ProductsMapView extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product) onContactTap;
  final ScrollController scrollController;

  const ProductsMapView({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onContactTap,
    required this.scrollController,
  });

  @override
  State<ProductsMapView> createState() => _ProductsMapViewState();
}

class _ProductsMapViewState extends State<ProductsMapView> {
  bool _isLoading = true;
  String? _error;
  List<Product> _productsWithLocation = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didUpdateWidget(ProductsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ CORRECCIÓN CRÍTICA: Actualizar cuando cambian los productos
    if (oldWidget.products != widget.products) {
      _processProducts();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Cargar ubicación en segundo plano mientras procesamos productos
      final locationFuture = LocationService.getCoordinatesOnly();
      
      // Procesar productos con ubicación inmediatamente
      _processProducts();
      
      // Esperar la ubicación pero no bloquear la UI
      await locationFuture;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error inicializando ubicación: $e');
      setState(() {
        _error = 'Error obteniendo ubicación: $e';
        _isLoading = false;
      });
    }
  }

  void _processProducts() {
    // ✅ CORRECCIÓN: Usar widget.products (los productos filtrados)
    _productsWithLocation = widget.products.where((p) => p.hasLocation).toList();
    
    // Si ya tenemos productos, mostrar inmediatamente
    if (_productsWithLocation.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _showProductBottomSheet(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con precio y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.precioFormateado,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.disponible ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.disponible ? 'DISPONIBLE' : 'VENDIDO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Título
              Text(
                product.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Categoría
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  product.categorias,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ubicación
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product.formattedLocation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onProductTap(product);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'VER DETALLES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  if (product.disponible)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onContactTap(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'CONTACTAR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando ubicación de productos...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar ubicaciones',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeLocation,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_productsWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No hay productos en el mapa',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los productos se mostrarán aquí cuando tengan ubicación',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Indicador de productos cargados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                '${_productsWithLocation.length} productos con ubicación',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Lista de productos con ubicación
        Expanded(
          child: Scrollbar(
            controller: widget.scrollController,
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _productsWithLocation.length,
              itemBuilder: (context, index) {
                final product = _productsWithLocation[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: product.disponible ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      // ignore: prefer_const_constructors
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      product.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.precioFormateado),
                        Text(
                          product.formattedLocation,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    trailing: product.disponible 
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DISP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'VEND',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    onTap: () => _showProductBottomSheet(product),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return _buildProductList();
  }
}