import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/story_provider.dart';
import 'package:libre_mercado_final__app/services/location_service.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';
import 'package:libre_mercado_final__app/models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _storyTextController = TextEditingController();
  
  String _selectedCategory = 'Tecnología';
  String _monedaSeleccionada = 'CUP';
  File? _selectedImage;
  File? _selectedStoryImage;
  bool _isLoading = false;
  bool _useLocation = true;
  Map<String, dynamic>? _locationData;
  String _locationStatus = 'No obtenida';
  String _uploadStatus = '';
  String? _selectedProductId;

  final List<String> _categories = [
    'Tecnología', 'Electrodomésticos', 'Ropa y Accesorios', 'Hogar y Jardín',
    'Deportes', 'Videojuegos', 'Libros', 'Música y Películas', 'Salud y Belleza',
    'Juguetes', 'Herramientas', 'Automóviles', 'Motos', 'Bicicletas', 'Mascotas',
    'Arte y Coleccionables', 'Inmuebles', 'Empleos', 'Servicios', 'Otros'
  ];

  final List<String> _monedas = ['CUP', 'USD'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _storyTextController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!_useLocation) return;

    setState(() {
      _locationStatus = 'Obteniendo ubicación...';
    });

    try {
      final location = await LocationService.getCoordinatesOnly();
      
      if (location['success'] == true) {
        setState(() {
          _locationData = location;
          _locationStatus = 'Ubicación obtenida ✅';
        });
      } else {
        setState(() {
          _locationStatus = 'Error: ${location['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: $e';
      });
    }
  }

  Future<void> _pickImage({bool forStory = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (forStory) {
            _selectedStoryImage = File(image.path);
          } else {
            _selectedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imagen: $e')),
      );
    }
  }

  void _removeImage({bool forStory = false}) {
    setState(() {
      if (forStory) {
        _selectedStoryImage = null;
      } else {
        _selectedImage = null;
      }
    });
  }

  // ✅ MÉTODO SIMPLIFICADO PARA PUBLICAR PRODUCTO
  Future<void> _publishProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una imagen del producto')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparando...';
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
        return;
      }

      // SUBIR IMAGEN
      setState(() {
        _uploadStatus = 'Subiendo imagen...';
      });

      final imageUploadService = ImageUploadService(Supabase.instance.client);
      String? imageUrl;

      try {
        imageUrl = await imageUploadService.uploadProductImage(_selectedImage!, currentUser.id);

        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error subiendo imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
            _uploadStatus = '';
          });
          return;
        }

        AppLogger.d('✅ Imagen subida correctamente: $imageUrl');

      } catch (uploadError) {
        AppLogger.e('❌ Error en subida de imagen', uploadError);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error subiendo imagen: $uploadError'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
        return;
      }

      setState(() {
        _uploadStatus = 'Publicando producto...';
      });

      // Crear locationData de forma segura
      final Map<String, dynamic> locationData;
      if (_useLocation && _locationData != null) {
        locationData = {
          'address': _locationData!['address']?.toString() ?? 'Ubicación no disponible',
          'city': _locationData!['city']?.toString() ?? 'Holguín',
          'latitude': _locationData!['latitude'] is double
              ? _locationData!['latitude']
              : (_locationData!['latitude'] is int
                  ? (_locationData!['latitude'] as int).toDouble()
                  : 20.8887),
          'longitude': _locationData!['longitude'] is double
              ? _locationData!['longitude']
              : (_locationData!['longitude'] is int
                  ? (_locationData!['longitude'] as int).toDouble()
                  : -76.2573),
        };
      } else {
        locationData = {
          'address': 'Ubicación no especificada',
          'city': 'Holguín',
          'latitude': 20.8887,
          'longitude': -76.2573,
        };
      }

      // CREAR PRODUCTO
      final error = await productProvider.createProductWithLocation(
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        precio: double.parse(_priceController.text),
        categorias: _selectedCategory,
        moneda: _monedaSeleccionada,
        imagenUrl: imageUrl,
        locationData: locationData,
      );

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto publicado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiar formulario
        _formKey.currentState!.reset();
        setState(() {
          _selectedImage = null;
          _selectedCategory = 'Tecnología';
          _monedaSeleccionada = 'CUP';
          _locationData = null;
          _locationStatus = 'No obtenida';
          _uploadStatus = '';
        });

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      AppLogger.e('Error crítico en _publishProduct', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error crítico: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  // ✅ MÉTODO PARA CREAR HISTORIA
  Future<void> _createStory() async {
    if (_selectedStoryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una imagen para la historia')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Creando historia...';
    });

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
        return;
      }

      // SUBIR IMAGEN DE LA HISTORIA
      setState(() {
        _uploadStatus = 'Subiendo imagen...';
      });

      final imageUploadService = ImageUploadService(Supabase.instance.client);
      String? imageUrl;

      try {
        // Usamos el mismo método de subida para historias
        imageUrl = await imageUploadService.uploadProductImage(_selectedStoryImage!, currentUser.id);

        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error subiendo imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
            _uploadStatus = '';
          });
          return;
        }

        AppLogger.d('✅ Imagen de historia subida correctamente: $imageUrl');

      } catch (uploadError) {
        AppLogger.e('❌ Error en subida de imagen de historia', uploadError);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error subiendo imagen: $uploadError'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
        return;
      }

      setState(() {
        _uploadStatus = 'Publicando historia...';
      });

      // CREAR HISTORIA - Usando el método que existe en StoryProvider
      // Primero necesitamos obtener el username del usuario
      final username = currentUser.username;
      
      final error = await storyProvider.addStory(
        imageUrl: imageUrl,
        text: _storyTextController.text.trim().isNotEmpty ? _storyTextController.text.trim() : null,
        productId: _selectedProductId,
        userId: currentUser.id,
        username: username,
      );

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Historia publicada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiar formulario de historia
        setState(() {
          _selectedStoryImage = null;
          _storyTextController.clear();
          _selectedProductId = null;
          _uploadStatus = '';
        });

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      AppLogger.e('Error crítico en _createStory', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error crítico: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Widget _buildProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESTADO DE SUBIDA
            if (_uploadStatus.isNotEmpty)
              Card(
                color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                    ? Colors.red[50] 
                    : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                        ? Colors.green[50] 
                        : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                            ? Icons.error 
                            : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                ? Icons.check_circle 
                                : Icons.cloud_upload,
                        color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                            ? Colors.red 
                            : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                ? Colors.green 
                                : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadStatus,
                          style: TextStyle(
                            color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                                ? Colors.red 
                                : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                    ? Colors.green 
                                    : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_uploadStatus.isNotEmpty) const SizedBox(height: 16),

            // TÍTULO DEL PRODUCTO
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Producto *',
                border: OutlineInputBorder(),
                hintText: 'Ej: iPhone 13 Pro Max 256GB',
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.isEmpty) return 'El título es obligatorio';
                if (value.length < 5) return 'Mínimo 5 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DESCRIPCIÓN
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                border: OutlineInputBorder(),
                hintText: 'Describe tu producto...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.isEmpty) return 'La descripción es obligatoria';
                if (value.length < 10) return 'Mínimo 10 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // PRECIO Y MONEDA
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      border: OutlineInputBorder(),
                      hintText: '0.00',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'El precio es obligatorio';
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) return 'Precio válido requerido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _monedaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Moneda *',
                      border: OutlineInputBorder(),
                    ),
                    items: _monedas.map((String moneda) {
                      return DropdownMenuItem<String>(
                        value: moneda,
                        child: Text(moneda),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _monedaSeleccionada = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CATEGORÍA
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),

            // UBICACIÓN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black),
                        const SizedBox(width: 8),
                        const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _useLocation,
                          onChanged: (value) {
                            setState(() {
                              _useLocation = value;
                            });
                            if (value) _getCurrentLocation();
                          },
                          activeTrackColor: Colors.grey[400],
                          thumbColor: const WidgetStatePropertyAll<Color>(Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_useLocation ? _locationStatus : 'Ubicación desactivada'),
                    if (_locationData != null && _useLocation)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('📍 ${_locationData!['address']}'),
                        ],
                      ),
                    if (_useLocation)
                      TextButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Actualizar Ubicación', style: TextStyle(color: Colors.black)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // IMAGEN DEL PRODUCTO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Imagen del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedImage != null ? '1/1 imagen seleccionada' : '0/1 imagen seleccionada'),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removeImage(forStory: false),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedImage != null ? null : () => _pickImage(forStory: false),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Agregar Imagen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN PUBLICAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publishProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('PUBLICAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryForm() {
    return FutureBuilder<List<Product>>(
      future: _getUserProducts(),
      builder: (context, snapshot) {
        final userProducts = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ESTADO DE SUBIDA
              if (_uploadStatus.isNotEmpty)
                Card(
                  color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                      ? Colors.red[50] 
                      : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                          ? Colors.green[50] 
                          : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                              ? Icons.error 
                              : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                  ? Icons.check_circle 
                                  : Icons.cloud_upload,
                          color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                              ? Colors.red 
                              : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                  ? Colors.green 
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _uploadStatus,
                            style: TextStyle(
                              color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                                  ? Colors.red 
                                  : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                                      ? Colors.green 
                                      : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_uploadStatus.isNotEmpty) const SizedBox(height: 16),

              // IMAGEN DE LA HISTORIA
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.photo, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Imagen de la Historia *', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_selectedStoryImage != null ? 'Imagen seleccionada' : 'No hay imagen seleccionada'),
                      const SizedBox(height: 12),
                      if (_selectedStoryImage != null)
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 200,
                                height: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_selectedStoryImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(forStory: true),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedStoryImage != null ? null : () => _pickImage(forStory: true),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Seleccionar Imagen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TEXTO DE LA HISTORIA (OPCIONAL)
              TextFormField(
                controller: _storyTextController,
                decoration: const InputDecoration(
                  labelText: 'Texto (Opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Agrega un texto a tu historia...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              // VINCULAR PRODUCTO (OPCIONAL)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Vincular Producto (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const CircularProgressIndicator()
                      else if (userProducts.isEmpty)
                        const Text(
                          'No tienes productos publicados. Publica un producto primero para vincularlo.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Selecciona un producto',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Sin producto vinculado'),
                            ),
                            ...userProducts.map((Product product) {
                              return DropdownMenuItem<String>(
                                value: product.id,
                                child: Text(
                                  product.titulo.length > 30 
                                      ? '${product.titulo.substring(0, 30)}...' 
                                      : product.titulo,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedProductId = newValue;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BOTÓN CREAR HISTORIA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('CREAR HISTORIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              // INFORMACIÓN ADICIONAL
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Sobre las Historias',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Las historias duran 24 horas\n• Puedes vincular un producto existente\n• La imagen es obligatoria\n• El texto es opcional (máx. 200 caracteres)',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Método para obtener productos del usuario
  Future<List<Product>> _getUserProducts() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return [];
      
      // Obtener todos los productos y filtrar por usuario actual
      await productProvider.fetchProducts();
      return productProvider.products
          .where((product) => product.userId == currentUser.id)
          .toList();
    } catch (e) {
      AppLogger.e('Error obteniendo productos del usuario', e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Contenido'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Publicar Producto'),
            Tab(text: 'Crear Historia'),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductForm(),
          _buildStoryForm(),
        ],
      ),
    );
  }
}