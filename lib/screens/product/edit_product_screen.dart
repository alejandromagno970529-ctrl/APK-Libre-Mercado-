import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/constants/app_colors.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = 'Otros';
  String _selectedCurrency = 'CUP';
  bool _isLoading = false;

  // ✅ NUEVO: Variables para manejar imágenes
  List<File> _newImages = [];
  List<String> _existingImages = [];
  List<String> _imagesToDelete = [];
  String _uploadStatus = '';
  final int _maxImages = 25;

  // ✅ CORREGIDO: Lista completa de categorías (igual que add_product_screen)
  final List<String> _categories = [
    'Tecnología', 'Electrodomésticos', 'Ropa y Accesorios', 'Hogar y Jardín',
    'Deportes', 'Videojuegos', 'Libros', 'Música y Películas', 'Salud y Belleza',
    'Juguetes', 'Herramientas', 'Automóviles', 'Motos', 'Bicicletas', 'Mascotas',
    'Arte y Coleccionables', 'Inmuebles', 'Empleos', 'Servicios', 'Otros'
  ];

  // Monedas disponibles
  final List<String> _currencies = ['CUP', 'USD'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.product.titulo;
    _descriptionController.text = widget.product.descripcion ?? '';
    // ✅ PRECIO AHORA PUEDE SER NULL
    _priceController.text = widget.product.precio?.toStringAsFixed(2) ?? '';
    _selectedCategory = widget.product.categorias;
    _selectedCurrency = widget.product.moneda;

    // ✅ INICIALIZAR IMÁGENES EXISTENTES
    _existingImages = widget.product.imagenUrls ?? [];

    // ✅ VERIFICAR SI LA CATEGORÍA EXISTE, SINO USAR 'Otros'
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Otros';
      AppLogger.w('Categoría "${widget.product.categorias}" no encontrada, usando "Otros"');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Método para seleccionar nuevas imágenes
  Future<void> _pickNewImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? selectedImages = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (selectedImages != null) {
        final int totalImages = _existingImages.length + _newImages.length;
        final int remainingSlots = _maxImages - totalImages;
        
        if (remainingSlots <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Máximo 25 imágenes alcanzado')),
          );
          return;
        }

        final List<XFile> imagesToAdd = selectedImages.length > remainingSlots
            ? selectedImages.sublist(0, remainingSlots)
            : selectedImages;

        setState(() {
          _newImages.addAll(imagesToAdd.map((xfile) => File(xfile.path)).toList());
        });

        if (selectedImages.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Se agregaron $remainingSlots imágenes (máximo 25)')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imágenes: $e')),
      );
    }
  }

  // ✅ NUEVO: Eliminar imagen existente
  void _removeExistingImage(int index) {
    setState(() {
      _imagesToDelete.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  // ✅ NUEVO: Eliminar nueva imagen
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  // ✅ NUEVO: Widget para mostrar sección de imágenes
  Widget _buildImageSection() {
    final allImages = [..._existingImages, ..._newImages.map((e) => e.path)];
    
    if (allImages.isEmpty) {
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
              'Sin imágenes',
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
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        final isExisting = index < _existingImages.length;
        final imagePath = allImages[index];
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: isExisting 
                      ? NetworkImage(imagePath) as ImageProvider
                      : FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => isExisting 
                    ? _removeExistingImage(index)
                    : _removeNewImage(index - _existingImages.length),
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
            if (isExisting)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EXISTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isExisting)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NUEVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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

  // ✅ MÉTODO ACTUALIZADO: Actualizar producto con imágenes
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Procesando...';
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final imageUploadService = ImageUploadService(Supabase.instance.client);
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

      List<String> finalImageUrls = List.from(_existingImages);

      // ✅ SUBIR NUEVAS IMÁGENES SI LAS HAY
      if (_newImages.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Subiendo ${_newImages.length} nuevas imágenes...';
        });

        final newUrls = await imageUploadService.uploadMultipleProductImages(_newImages, currentUser.id);
        
        if (newUrls.isNotEmpty) {
          finalImageUrls.addAll(newUrls);
          AppLogger.d('✅ ${newUrls.length} nuevas imágenes subidas');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error subiendo nuevas imágenes'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { 
            _isLoading = false;
            _uploadStatus = '';
          });
          return;
        }
      }

      // ✅ ELIMINAR IMÁGENES MARCADAS PARA BORRAR
      if (_imagesToDelete.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Eliminando ${_imagesToDelete.length} imágenes...';
        });

        for (final imageUrl in _imagesToDelete) {
          await imageUploadService.deleteImage(imageUrl);
        }
        AppLogger.d('✅ ${_imagesToDelete.length} imágenes eliminadas');
      }

      // ✅ ACTUALIZAR LISTA DE IMÁGENES EN LA BASE DE DATOS
      if (_newImages.isNotEmpty || _imagesToDelete.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Actualizando imágenes del producto...';
        });

        await productProvider.updateProductImages(widget.product.id, finalImageUrls);
      }

      // ✅ OBTENER PRECIO (OPCIONAL) - NUEVA FUNCIONALIDAD
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

      // ✅ ACTUALIZAR EL RESTO DE LA INFORMACIÓN DEL PRODUCTO
      setState(() {
        _uploadStatus = 'Actualizando información del producto...';
      });

      final result = await productProvider.updateProduct(
        productId: widget.product.id,
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        precio: precio, // ✅ AHORA PUEDE SER NULL
        categorias: _selectedCategory,
        moneda: _selectedCurrency,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Producto actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error updating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedCategory,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedCurrency,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: _currencies.map((currency) {
          return DropdownMenuItem(
            value: currency,
            child: Text(
              currency,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCurrency = value!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Editar Producto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ESTADO DE CARGA DE IMÁGENES
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

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TÍTULO
                        const Text(
                          'Título del producto',
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
                            hintText: 'Ej: iPhone 12 en perfecto estado',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ✅ DESCRIPCIÓN - TEXTO MODIFICADO
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe tu producto...', // ✅ TEXTO MODIFICADO
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 20),

                        // ✅ PRECIO - AHORA ES OPCIONAL
                        const Text(
                          'Precio (opcional)', // ✅ TEXTO MODIFICADO
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
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                style: const TextStyle(color: AppColors.textPrimary),
                                // ✅ VALIDACIÓN MODIFICADA - AHORA ES OPCIONAL
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final price = double.tryParse(value);
                                    if (price == null || price <= 0) {
                                      return 'Precio inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: _buildCurrencyDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // CATEGORÍA
                        const Text(
                          'Categoría',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 20),

                        // ✅ NUEVA SECCIÓN: IMÁGENES DEL PRODUCTO
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
                                      '${_existingImages.length + _newImages.length}/25',
                                      style: TextStyle(
                                        color: (_existingImages.length + _newImages.length) >= 25 ? Colors.red : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_existingImages.length} existente(s), ${_newImages.length} nueva(s)',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 12),
                                
                                _buildImageSection(),
                                
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _pickNewImages,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('Agregar Más Imágenes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if (_existingImages.isNotEmpty || _newImages.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '💡 Toca la X para eliminar imágenes. Las imágenes marcadas como "EXISTE" se eliminarán permanentemente.',
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
                        const SizedBox(height: 20),

                        // INFORMACIÓN ADICIONAL
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, size: 20, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Información adicional',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• La ubicación no se puede modificar\n• Las imágenes eliminadas se borran permanentemente\n• El producto se actualizará inmediatamente',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTÓN ACTUALIZAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                            'ACTUALIZAR PRODUCTO',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}