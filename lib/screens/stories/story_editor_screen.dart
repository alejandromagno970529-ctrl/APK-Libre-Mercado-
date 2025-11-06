import 'dart:typed_data'; // ✅ Añadir esta importación
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_editor_provider.dart';
import '../../widgets/story_editor_toolbar.dart';
import '../../widgets/story_elements_panel.dart'; // ✅ Ahora existe
import '../../widgets/story_canvas.dart';

class StoryEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const StoryEditorScreen({super.key, required this.imageBytes});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  late StoryEditorProvider _editorProvider;

  @override
  void initState() {
    super.initState();
    _editorProvider = StoryEditorProvider(widget.imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _editorProvider,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Editar Historia',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _saveStory,
            ),
          ],
        ),
        body: Column(
          children: [
            // Canvas de edición
            Expanded(
              child: StoryCanvas(
                imageBytes: widget.imageBytes,
              ),
            ),
            
            // Panel de herramientas
            const StoryEditorToolbar(),
            
            // Panel de elementos específicos
            const StoryElementsPanel(),
          ],
        ),
      ),
    );
  }

  void _saveStory() {
    // Implementar guardado de la historia editada
    final editedImage = _editorProvider.finalImage;
    // Navegar de vuelta con la imagen editada
    Navigator.pop(context, editedImage);
  }
}