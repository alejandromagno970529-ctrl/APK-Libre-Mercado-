import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:libre_mercado_final__app/models/product_model.dart';
import 'package:libre_mercado_final__app/providers/product_provider.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  
  String _selectedCategory = 'Tecnología';
  String _monedaSeleccionada = 'CUP';
  File? _selectedImage;
  bool _isLoading = false;
  String _uploadStatus = '';

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
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.product.titulo;
    _descriptionController.text = widget.product.descripcion!;
    _priceController.text = widget.product.precio.toStringAsFixed(2);
    _selectedCategory = widget.product.categorias;
    _monedaSeleccionada = widget.product.moneda;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imagen: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Actualizando producto...';
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // ✅ CORREGIDO: Null safety para imageUrl
      String? imageUrl = widget.product.imagenUrl;

      // Si se seleccionó una nueva imagen, subirla
      if (_selectedImage != null) {
        _uploadStatus = 'Subiendo nueva imagen...';
        
        final imageUploadService = ImageUploadService(Supabase.instance.client);
        final newImageUrl = await imageUploadService.uploadProductImage(
          _selectedImage!, 
          widget.product.userId
        );

        if (newImageUrl != null) {
          imageUrl = newImageUrl;
          AppLogger.d('✅ Nueva imagen subida: $imageUrl');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error subiendo nueva imagen'),
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

      _uploadStatus = 'Guardando cambios...';

      final error = await productProvider.updateProduct(
        productId: widget.product.id,
        titulo: _titleController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        precio: double.parse(_priceController.text),
        categorias: _selectedCategory,
        moneda: _monedaSeleccionada,
      );

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      AppLogger.e('Error crítico en _updateProduct', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error crítico: ${e.toString()}'),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ESTADO DE ACTUALIZACIÓN
              if (_uploadStatus.isNotEmpty)
                Card(
                  color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                      ? Colors.red[50] 
                      : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                              ? Icons.error 
                              : Icons.cloud_upload,
                          color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                              ? Colors.red 
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _uploadStatus,
                            style: TextStyle(
                              color: _uploadStatus.contains('Error') || _uploadStatus.contains('❌') 
                                  ? Colors.red 
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
                      // ✅ CORREGIDO: initialValue en lugar de value deprecated
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
                // ✅ CORREGIDO: initialValue en lugar de value deprecated
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

              // IMAGEN DEL PRODUCTO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.photo, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Imagen del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_selectedImage != null 
                          ? 'Nueva imagen seleccionada' 
                          : 'Imagen actual mantendrá'),
                      const SizedBox(height: 12),
                      
                      // VISTA PREVIA DE IMAGEN
                      Center(
                        child: _selectedImage != null
                            ? Stack(
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
                                      onTap: _removeImage,
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
                              )
                            : widget.product.imagenUrl != null
                                ? Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(widget.product.imagenUrl!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Sin imagen', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Cambiar Imagen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BOTÓN ACTUALIZAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black87))
                      : const Text('ACTUALIZAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}