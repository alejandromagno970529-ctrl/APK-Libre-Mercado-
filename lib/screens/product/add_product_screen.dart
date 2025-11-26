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
import 'package:libre_mercado_final__app/constants/app_colors.dart';

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
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _useLocation = true;
  Map<String, dynamic>? _locationData;
  String _locationStatus = 'No obtenida';
  String _uploadStatus = '';

  final int _maxImages = 25;
  final int _maxDescriptionWords = 5000;

  // ✅ ACTUALIZADO: "Música y Películas" → "Alimentos y bebidas"
  final List<String> _categories = [
    'Tecnología', 'Electrodomésticos', 'Ropa y Accesorios', 'Hogar y Jardín',
    'Deportes', 'Videojuegos', 'Libros', 'Alimentos y bebidas', 'Salud y Belleza',
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ✅ MÉTODO MEJORADO: Reordenar imágenes con tema de la app
  void _showReorderDialog() {
    List<File> reorderedImages = List.from(_selectedImages);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Theme(
            data: Theme.of(context).copyWith(
              // ignore: deprecated_member_use
              dialogBackgroundColor: Colors.white,
              cardColor: Colors.white,
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Reordenar Imágenes',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setDialogState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final File image = reorderedImages.removeAt(oldIndex);
                      reorderedImages.insert(newIndex, image);
                    });
                  },
                  children: List.generate(reorderedImages.length, (index) {
                    return Container(
                      key: Key('$index'),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            reorderedImages[index],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          'Imagen ${index + 1}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.drag_handle,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedImages = List.from(reorderedImages);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Orden de imágenes actualizado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar Orden'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int get _wordCount {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) return 0;
    // ignore: deprecated_member_use
    return text.split(RegExp(r'\s+')).length;
  }

  Future<void> _publishProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una imagen del producto')),
      );
      return;
    }

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
        double? precio;
        if (_priceController.text.isNotEmpty) {
          precio = double.tryParse(_priceController.text);
          if (precio == null || precio <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor ingresa un precio válido')),
            );
            setState(() {
              _isLoading = false;
              _uploadStatus = '';
            });
            return;
          }
        }

        await productProvider.createProductWithLocation(
          titulo: _titleController.text.trim(),
          descripcion: _descriptionController.text.trim(),
          precio: precio,
          categorias: _selectedCategory,
          moneda: _monedaSeleccionada,
          imagenUrls: imageUrls,
          locationData: locationData,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto publicado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

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

  // ✅ MÉTODO CORREGIDO: Grid de imágenes SIN OVERFLOW
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

    // ✅ CALCULAR ALTURA DINÁMICA PARA EVITAR OVERFLOW
    final crossAxisCount = 3;
    final itemCount = _selectedImages.length;
    final rowCount = (itemCount / crossAxisCount).ceil();
    final gridHeight = (rowCount * 120.0) + (rowCount * 8); // 120px por item + spacing

    return SizedBox(
      height: gridHeight, // ✅ ALTURA FIJA CALCULADA
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), // ✅ DESACTIVAR SCROLL INTERNO
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
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey.shade400),
                            const SizedBox(height: 4),
                            Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.7),
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
      ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                      ? Colors.red[50] 
                      : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                          ? Colors.green[50] 
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                        ? Colors.red[100]!
                        : _uploadStatus.contains('OK') || _uploadStatus.contains('✅') 
                            ? Colors.green[100]!
                            : Colors.blue[100]!,
                  ),
                ),
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
            if (_uploadStatus.isNotEmpty) const SizedBox(height: 16),

            // TÍTULO DEL PRODUCTO
            const Text(
              'Título del Producto *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: iPhone 13 Pro Max 256GB',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.isEmpty) return 'El título es obligatorio';
                if (value.length < 5) return 'Mínimo 5 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DESCRIPCIÓN
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Descripción *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$_wordCount/$_maxDescriptionWords palabras',
                      style: TextStyle(
                        color: _wordCount > _maxDescriptionWords ? Colors.red : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Describe tu producto...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 6,
                  maxLength: 25000,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      '$currentLength/$maxLength caracteres',
                      style: const TextStyle(color: AppColors.textSecondary),
                    );
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
            const Text(
              'Precio (opcional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) return 'Precio válido requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _monedaSeleccionada,
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: _monedas.map((String moneda) {
                          return DropdownMenuItem<String>(
                            value: moneda,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(moneda),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _monedaSeleccionada = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CATEGORÍA
            const Text(
              'Categoría *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(category),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // UBICACIÓN
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        const Text(
                          'Ubicación', 
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
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
                    Text(
                      _useLocation ? _locationStatus : 'Ubicación desactivada',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (_locationData != null && _useLocation)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '📍 ${_locationData!['address']}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (_useLocation)
                      TextButton(
                        onPressed: _getCurrentLocation,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Actualizar Ubicación'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // IMÁGENES DEL PRODUCTO - SECCIÓN CORREGIDA
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        const Text(
                          'Imágenes del Producto', 
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedImages.length}/$_maxImages',
                          style: TextStyle(
                            color: _selectedImages.length >= _maxImages ? Colors.red : AppColors.textPrimary,
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
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    
                    // ✅ GRID DE IMÁGENES SIN OVERFLOW
                    _buildImageGrid(),
                    
                    const SizedBox(height: 16),
                    
                    // ✅ BOTONES CORREGIDOS - DISEÑO MINIMALISTA MEJORADO
                    Column(
                      children: [
                        // Botón principal - Agregar Imágenes
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _selectedImages.length >= _maxImages ? null : _pickImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_photo_alternate, size: 20),
                            label: const Text(
                              'Agregar Imágenes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          
                          // Botones secundarios en fila
                          Row(
                            children: [
                              // Botón Reordenar (solo si hay más de 1 imagen)
                              if (_selectedImages.length > 1) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showReorderDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.swap_vert, size: 18),
                                    label: const Text(
                                      'Reordenar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              // Botón Limpiar
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() { _selectedImages.clear(); }),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _selectedImages.length > 1 
                            ? '💡 Usa "Reordenar" para cambiar el orden de las imágenes'
                            : '💡 Agrega más imágenes para poder reordenarlas',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'PUBLICAR PRODUCTO',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Publicar Producto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
      body: _buildProductForm(),
    );
  }
}