import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/services/location_service.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCategory = 'Tecnología';
  String _monedaSeleccionada = 'CUP';
  List<File> _selectedImages = []; // ✅ LISTA DE IMÁGENES
  bool _isLoading = false;
  bool _useLocation = true;
  Map<String, dynamic>? _locationData;
  String _locationStatus = 'No obtenida';
  String _uploadStatus = '';

  final int _maxImages = 25; // ✅ MÁXIMO 25 IMÁGENES
  final int _maxDescriptionWords = 5000; // ✅ MÁXIMO 5000 PALABRAS

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
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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

  // ✅ NUEVO MÉTODO: Seleccionar múltiples imágenes
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? selectedImages = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (selectedImages != null) {
        final int remainingSlots = _maxImages - _selectedImages.length;
        
        if (remainingSlots <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Máximo $_maxImages imágenes alcanzado')),
          );
          return;
        }

        final List<XFile> imagesToAdd = selectedImages.length > remainingSlots
            ? selectedImages.sublist(0, remainingSlots)
            : selectedImages;

        setState(() {
          _selectedImages.addAll(imagesToAdd.map((xfile) => File(xfile.path)).toList());
        });

        if (selectedImages.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Se agregaron $remainingSlots imágenes (máximo $_maxImages)')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imágenes: $e')),
      );
    }
  }

  // ✅ NUEVO MÉTODO: Eliminar imagen específica
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ✅ NUEVO MÉTODO: Contador de palabras
  int get _wordCount {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  // ✅ MÉTODO ACTUALIZADO PARA MÚLTIPLES IMÁGENES
  Future<void> _publishProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una imagen del producto')),
      );
      return;
    }

    // ✅ VALIDAR LÍMITE DE PALABRAS
    if (_wordCount > _maxDescriptionWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $_maxDescriptionWords palabras permitidas')),
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

      // ✅ SUBIR MÚLTIPLES IMÁGENES
      setState(() {
        _uploadStatus = 'Subiendo ${_selectedImages.length} imágenes...';
      });

      final imageUploadService = ImageUploadService(Supabase.instance.client);
      List<String> imageUrls = [];

      try {
        imageUrls = await imageUploadService.uploadMultipleProductImages(_selectedImages, currentUser.id);

        if (imageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error subiendo imágenes. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
            _uploadStatus = '';
          });
          return;
        }

        AppLogger.d('✅ ${imageUrls.length} imágenes subidas correctamente');

      } catch (uploadError) {
        AppLogger.e('❌ Error en subida de imágenes', uploadError);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error subiendo imágenes: $uploadError'),
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

      try {
        // ✅ LLAMADA CORREGIDA - usar imagenUrls en lugar de imagenUrl
        await productProvider.createProductWithLocation(
          titulo: _titleController.text.trim(),
          descripcion: _descriptionController.text.trim(),
          precio: double.parse(_priceController.text),
          categorias: _selectedCategory,
          moneda: _monedaSeleccionada,
          imagenUrls: imageUrls,  // ✅ CORREGIDO - lista de URLs
          locationData: locationData,
        );

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
          _selectedImages.clear();
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
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

  // ✅ NUEVO WIDGET: Grid de imágenes
  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              '0/$_maxImages imágenes',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

            // ✅ DESCRIPCIÓN MEJORADA
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Descripción *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$_wordCount/$_maxDescriptionWords palabras',
                      style: TextStyle(
                        color: _wordCount > _maxDescriptionWords ? Colors.red : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Describe tu producto... Puedes usar emojis 😊',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  maxLength: 25000, // ✅ APROX 5000 PALABRAS
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text('$currentLength/$maxLength caracteres');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'La descripción es obligatoria';
                    if (value.length < 10) return 'Mínimo 10 caracteres';
                    if (_wordCount > _maxDescriptionWords) {
                      return 'Máximo $_maxDescriptionWords palabras permitidas';
                    }
                    return null;
                  },
                ),
              ],
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
                    // ignore: deprecated_member_use
                    value: _monedaSeleccionada,
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
              // ignore: deprecated_member_use
              value: _selectedCategory,
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

            // ✅ IMÁGENES MEJORADAS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: Colors.black),
                        const SizedBox(width: 8),
                        const Text('Imágenes del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          '${_selectedImages.length}/$_maxImages',
                          style: TextStyle(
                            color: _selectedImages.length >= _maxImages ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImages.isEmpty
                          ? 'Agrega imágenes de tu producto'
                          : '${_selectedImages.length} imagen(es) seleccionada(s)',
                    ),
                    const SizedBox(height: 12),
                    
                    _buildImageGrid(),
                    
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedImages.length >= _maxImages ? null : _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Agregar Imágenes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => setState(() { _selectedImages.clear(); }),
                            icon: const Icon(Icons.delete),
                            label: const Text('Limpiar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 Puedes arrastrar las imágenes para cambiar el orden',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Producto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
      body: _buildProductForm(),
    );
  }
}