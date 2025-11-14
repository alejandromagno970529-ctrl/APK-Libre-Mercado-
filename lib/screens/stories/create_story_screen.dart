import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  // ✅ LISTA DE ASISTENTES IA DISPONIBLES
  final List<Map<String, dynamic>> _aiAssistants = [
    {
      'name': 'Qwen AI',
      'url': 'https://chat.qwen.ai/',
      'icon': Icons.auto_awesome,
      'color': Colors.black,
      'description': 'Editor de imágenes con IA',
    },
    {
      'name': 'Google Gemini',
      'url': 'https://gemini.google.com/',
      'icon': Icons.graphic_eq,
      'color': Colors.black,
      'description': 'Asistente de Google',
    },
    {
      'name': 'ChatGPT',
      'url': 'https://chat.openai.com/',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.black,
      'description': 'Chatbot de OpenAI',
    },
    {
      'name': 'Grok',
      'url': 'https://grok.com/',
      'icon': Icons.rocket_launch,
      'color': Colors.black,
      'description': 'Asistente IA de xAI',
    },
  ];

  // ✅ MÉTODO: ABRIR ASISTENTE IA
  void _openAIAssistant(String url) async {
    try {
      // ignore: deprecated_member_use
      if (await canLaunch(url)) {
        // ignore: deprecated_member_use
        await launch(url);
      } else {
        _showErrorSnackbar('No se puede abrir el asistente IA');
      }
    } catch (e) {
      _showErrorSnackbar('Error al abrir el asistente: $e');
    }
  }

  // ✅ MÉTODO: CONSTRUIR SECCIÓN VPN COMPACTA
  Widget _buildVPNRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_lock, color: Colors.orange[700], size: 14),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Problemas de acceso con algunos editores',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Si algún editor no está disponible:',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 1),
          const Text(
            '• Activa VPN en tu dispositivo',
            style: TextStyle(fontSize: 9, color: Colors.black54),
          ),
          const Text(
            '• Luego regresa a la app',
            style: TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ✅ MOSTRAR MENÚ DE ASISTENTES IA
  void _showAIAssistantsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editores con IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selecciona un asistente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _aiAssistants.length,
                    itemBuilder: (context, index) {
                      final assistant = _aiAssistants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              assistant['icon'],
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            assistant['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            assistant['description'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _openAIAssistant(assistant['url']);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'CERRAR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 1080,
      );

      if (images != null && images.isNotEmpty && mounted) {
        final List<File> newImages = images.take(5).map((xfile) => File(xfile.path)).toList();
        
        setState(() {
          _selectedImages.addAll(newImages);
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
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _selectedImages.isNotEmpty ? [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _isUploading ? null : _publishStory,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
              ),
              icon: _isUploading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
            ),
          ),
        ] : null,
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
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
            SizedBox(height: 12),
            Text(
              'Publicando historia...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_selectedImages.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildImagePreview(_selectedImages[index], index);
              },
            ),
          ),
          
          if (_selectedImages.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_selectedImages.length, (index) {
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                  );
                }),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAIAssistantsMenu,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
                icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 16),
                label: const Text(
                  'EDITAR CON IA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _selectedImages.length < 5 
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickImages,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      child: const Text(
                        'AGREGAR MÁS',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      );
    }

    // ✅ VISTA INICIAL CORREGIDA - SIN PROBLEMAS DE VISIBILIDAD
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.photo_library_outlined, size: 32, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Crear Historia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 8),
          
          const Text(
            'Selecciona hasta 5 imágenes para compartir en tu historia',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Mejora tus fotos con IA',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Usa editores IA avanzados para mejorar la calidad de tus imágenes',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ✅ SECCIÓN VPN
          _buildVPNRecommendation(),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'SELECCIONAR IMÁGENES',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showAIAssistantsMenu,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Colors.black),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.black, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'VER EDITORES IA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        if (_selectedImages.length > 1)
          Positioned(
            top: 50,
            right: 10,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}