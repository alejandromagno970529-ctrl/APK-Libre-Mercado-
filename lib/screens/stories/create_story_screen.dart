import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = []; // ✅ CAMBIO: Lista de imágenes
  bool _isUploading = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        imageQuality: 90, // ✅ Mejor calidad
        maxWidth: 1080, // ✅ Resolución óptima
      );

      if (images != null && images.isNotEmpty && mounted) {
        // Limitar a máximo 5 imágenes
        final List<File> newImages = images.take(5).map((xfile) => File(xfile.path)).toList();
        
        setState(() {
          _selectedImages.addAll(newImages);
          // Si exceden 5, mantener solo las primeras 5
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _publishStory() async {
    if (_selectedImages.isEmpty) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('Usuario no autenticado');
        return;
      }

      // ✅ USAR NUEVO MÉTODO para múltiples imágenes
      final success = await storyProvider.createStoryWithMultipleImages(
        _selectedImages,
        currentUser.id,
        currentUser.username,
      );

      if (success && mounted) {
        _showSuccessSnackbar('✅ Historia con ${_selectedImages.length} imágenes publicada exitosamente');
        Navigator.of(context).pop();
      } else if (mounted) {
        _showErrorSnackbar('Error: ${storyProvider.error ?? "Error desconocido"}');
      }

    } catch (e) {
      _showErrorSnackbar('Error al publicar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
        title: Text(
          _selectedImages.isEmpty ? 'Crear Historia' : 'Vista Previa (${_selectedImages.length}/5)',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isUploading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Publicando historia...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedImages.isNotEmpty) {
      return Column(
        children: [
          // ✅ VISTA PREVIA MEJORADA: Mostrar carrusel de imágenes
          Expanded(
            child: PageView.builder(
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildImagePreview(_selectedImages[index], index);
              },
            ),
          ),
          
          // ✅ INDICADORES DE IMÁGENES
          if (_selectedImages.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_selectedImages.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ignore: deprecated_member_use
                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                    ),
                  );
                }),
              ),
            ),

          // ✅ BOTONES DE ACCIÓN
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Botón para agregar más imágenes
                if (_selectedImages.length < 5)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _pickImages,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'AGREGAR MÁS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_selectedImages.length < 5) const SizedBox(width: 12),
                // Botón de publicar
                Expanded(
                  flex: _selectedImages.length < 5 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _publishStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'PUBLICAR (${_selectedImages.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Vista cuando no hay imágenes seleccionadas
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 50,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Título
            const Text(
              'Crear Historia',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Descripción
            const Text(
              'Selecciona hasta 5 imágenes para compartir en tu historia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            
            // Botón de seleccionar imágenes
            ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'SELECCIONAR IMÁGENES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File imageFile, int index) {
    return Stack(
      children: [
        // Imagen principal
        Container(
          width: double.infinity,
          color: Colors.black,
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        // Botón de eliminar (solo mostrar si hay más de una imagen)
        if (_selectedImages.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}