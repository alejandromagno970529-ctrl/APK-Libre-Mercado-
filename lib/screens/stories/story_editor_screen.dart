import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:libre_mercado_final__app/models/story_editing_models.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/story_editor_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/story_canvas.dart';
import '../../widgets/story_editor_toolbar.dart'; // ✅ Solo una barra de herramientas
import '../home_screen.dart';

class StoryEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  
  const StoryEditorScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StoryEditorProvider>(context, listen: false);
      provider.setBackgroundImage(widget.imageBytes);
    });
  }

  Future<void> _publishStory() async {
    if (_isPublishing) return;
    
    try {
      setState(() => _isPublishing = true);

      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final editorProvider = Provider.of<StoryEditorProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar('Usuario no autenticado');
        return;
      }

      final Uint8List? imageBytes = editorProvider.backgroundImageBytes;
      if (imageBytes == null) {
        _showErrorSnackbar('No hay imagen para publicar');
        return;
      }

      // Subir imagen
      final imageUploadService = ImageUploadService(Supabase.instance.client);
      final String? imageUrl = await imageUploadService.uploadStoryImageFromBytes(
        imageBytes, 
        currentUser.id
      );

      if (imageUrl == null) {
        _showErrorSnackbar('Error subiendo imagen');
        return;
      }

      // Crear historia con elementos editados
      final success = await storyProvider.addEditedStory(
        imageBytes: imageBytes,
        userId: currentUser.id,
        username: currentUser.username,
        text: _generateStoryText(editorProvider.elements),
        productId: editorProvider.productId,
      );

      if (success) {
        _showSuccessSnackbar('✅ Historia publicada exitosamente');
        editorProvider.clearEditor();
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showErrorSnackbar('Error: ${storyProvider.error ?? "Error desconocido"}');
      }

    } catch (e) {
      _showErrorSnackbar('Error crítico al publicar: $e');
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  String _generateStoryText(List<StoryElement> elements) {
    if (elements.isEmpty) return "Mi historia editada";
    
    final textElements = elements.where((element) => element.type == StoryElementType.text);
    if (textElements.isNotEmpty) {
      return textElements.map((e) => e.content).join(' • ');
    }
    
    return "📸 Historia con ${elements.length} elementos";
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        title: const Text(
          'Editor de Historias',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Contador de elementos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.elements.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (_isPublishing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: provider.hasImage ? _publishStory : null,
              tooltip: 'Publicar historia',
            ),
        ],
      ),
      body: Column(
        children: [
          // ✅ SOLO UNA BARRA DE HERRAMIENTAS UNIFICADA
          const StoryEditorToolbar(),
          
          // Canvas principal
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: StoryCanvas(
                  imageBytes: provider.backgroundImageBytes,
                  elements: provider.elements,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirmation() async {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    final hasChanges = provider.hasElements;
    
    if (!hasChanges) {
      provider.clearEditor();
      Navigator.of(context).pop();
      return;
    }

    final bool? shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del editor'),
        content: const Text('¿Estás seguro de que quieres salir? Se perderán los cambios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    
    if (shouldExit == true && mounted) {
      provider.clearEditor();
      Navigator.of(context).pop();
    }
  }
}