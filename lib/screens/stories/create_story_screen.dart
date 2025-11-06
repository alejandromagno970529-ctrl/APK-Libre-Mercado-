import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ✅ RUTAS CORRECTAS
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';
import 'story_editor_screen.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryEditorScreen(imageBytes: bytes),
            ),
          );

          if (result != null && result is Uint8List && mounted) {
            await _publishStory(result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _publishStory(Uint8List imageBytes) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // ✅ USAR AppUser DE TU AUTH PROVIDER
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // ✅ OBTENER USERNAME - AJUSTA SEGÚN TU MODELO AppUser
      final username = _getUsername(currentUser);

      // ✅ IMAGEN TEMPORAL (en producción usarías ImageUploadService)
      final imageUrl = 'https://picsum.photos/400/800?random=${DateTime.now().millisecondsSinceEpoch}';

      // Publicar la historia
      final success = await storyProvider.addStory(
        imageUrl: imageUrl,
        userId: currentUser.id,
        username: username,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Historia publicada!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al publicar la historia')),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ✅ MÉTODO PARA OBTENER USERNAME DE AppUser
  String _getUsername(dynamic currentUser) {
    try {
      // Opción 1: Si tu AppUser tiene propiedad 'name'
      if (currentUser.name != null && currentUser.name.isNotEmpty) {
        return currentUser.name;
      }
      
      // Opción 2: Si tu AppUser tiene propiedad 'username'  
      if (currentUser.username != null && currentUser.username.isNotEmpty) {
        return currentUser.username;
      }
      
      // Opción 3: Si tu AppUser tiene propiedad 'email'
      if (currentUser.email != null && currentUser.email.isNotEmpty) {
        return currentUser.email.split('@').first;
      }
      
      // Opción 4: Del ID del usuario
      return 'Usuario_${currentUser.id.substring(0, 6)}';
    } catch (e) {
      return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Historia'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Crear Historia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona una imagen para editar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Seleccionar Imagen'),
                  ),
          ],
        ),
      ),
    );
  }
}