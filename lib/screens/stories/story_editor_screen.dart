import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_editor_provider.dart';
import '../../widgets/story_canvas.dart';

class StoryEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const StoryEditorScreen({super.key, required this.imageBytes});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  String _selectedFont = 'Normal';
  Color _selectedColor = Colors.white;
  double _textSize = 24.0;

  final List<String> _fonts = ['Normal', 'Negrita', 'Cursiva'];
  final List<Color> _colors = [
    Colors.white, 
    Colors.black, 
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow
  ];

  @override
  void dispose() {
    _textController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Historia',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<StoryEditorProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.crop),
                    onPressed: () => _showCropOptions(provider),
                  ),
                  if (provider.selectedElement != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSelectedElement(provider),
                    ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _saveStory(provider),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<StoryEditorProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Canvas de edición - MEJORADO PARA EVITAR OVERFLOW
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: StoryCanvas(
                        imageBytes: widget.imageBytes,
                      ),
                    ),
                  ),
                ),
                
                // Panel de herramientas - MEJORADO LAYOUT
                _buildToolbar(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(StoryEditorProvider provider) {
    return Container(
      width: double.infinity, // ✅ EVITA OVERFLOW HORIZONTAL
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ EVITA OVERFLOW VERTICAL
        children: [
          // Fila 1: Tipos de elementos - MEJORADO CON SCROLL HORIZONTAL
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                const SizedBox(width: 8),
                _buildToolbarButton('Texto', Icons.text_fields, () {
                  _showAddTextDialog(context, provider);
                }),
                const SizedBox(width: 12),
                _buildToolbarButton('Stickers', Icons.emoji_emotions, () {
                  _showStickersPanel(context, provider);
                }),
                const SizedBox(width: 12),
                _buildToolbarButton('Oferta', Icons.local_offer, () {
                  _showDiscountDialog(context, provider);
                }),
                const SizedBox(width: 12),
                _buildToolbarButton('Plantillas', Icons.grid_view, () {
                  _showTemplatesPanel(context, provider);
                }),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Fila 2: Configuración de texto - MEJORADO LAYOUT
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Selector de fuente
                Expanded(
                  flex: 2,
                  child: _buildFontSelector(),
                ),
                const SizedBox(width: 8),
                
                // Selector de color
                Expanded(
                  flex: 3,
                  child: _buildColorSelector(),
                ),
                const SizedBox(width: 8),
                
                // Tamaño de texto
                Expanded(
                  flex: 2,
                  child: _buildTextSizeSelector(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFont,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: const TextStyle(fontSize: 12, color: Colors.black),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFont = newValue;
              });
            }
          },
          items: _fonts.map((String font) {
            return DropdownMenuItem<String>(
              value: font,
              child: Text(
                font,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: _colors.map((color) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color ? Colors.blue : Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextSizeSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              setState(() {
                if (_textSize > 12) _textSize -= 2;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30),
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              _textSize.toInt().toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              setState(() {
                if (_textSize < 48) _textSize += 2;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30),
          ),
        ],
      ),
    );
  }

  void _showAddTextDialog(BuildContext context, StoryEditorProvider provider) {
    // ✅ MEJORADO: Cerrar teclado antes de abrir diálogo
    FocusScope.of(context).unfocus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Añadir Texto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu texto...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildTextPreview(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _textController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                final textStyle = _createTextStyle();
                
                provider.addTextElement(
                  _textController.text.trim(),
                  const Offset(150, 150),
                  style: textStyle,
                );
                _textController.clear();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Añadir Texto'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _textController.text.isEmpty ? 'Vista previa' : _textController.text,
        style: _createTextStyle(),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showStickersPanel(BuildContext context, StoryEditorProvider provider) {
    final List<String> stickers = [
      '🔥', '⭐', '💥', '🎯', '💎', '🚀', '📱', '🛒',
      '💰', '🎁', '👑', '⚡', '❤️', '👍', '👀', '🕒',
      '🎨', '✨', '🌟', '🎉', '🏆', '💡', '📸', '🎊'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Stickers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  return GestureDetector(
                    onTap: () {
                      provider.addStickerElement(sticker, const Offset(150, 150));
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Center(
                        child: Text(
                          sticker,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, StoryEditorProvider provider) {
    // ✅ MEJORADO: Cerrar teclado antes de abrir diálogo
    FocusScope.of(context).unfocus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Etiqueta de Descuento',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _discountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 50',
                suffixText: '%',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _discountController.text.isEmpty ? '50%' : '${_discountController.text}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _discountController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_discountController.text.isNotEmpty) {
                provider.addDiscountTag(
                  '${_discountController.text}%',
                  const Offset(50, 50),
                );
                _discountController.clear();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Añadir Oferta'),
          ),
        ],
      ),
    );
  }

  void _showTemplatesPanel(BuildContext context, StoryEditorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Plantillas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: provider.templates.length,
                itemBuilder: (context, index) {
                  final template = provider.templates[index];
                  return GestureDetector(
                    onTap: () {
                      provider.applyTemplate(template);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plantilla "${template.name}" aplicada'),
                          backgroundColor: Colors.black,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCropOptions(StoryEditorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opciones de Imagen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOptionButton('Recortar Imagen', Icons.crop, () {
              Navigator.pop(context);
              _showCropDialog(provider);
            }),
            _buildOptionButton('Rotar Imagen', Icons.rotate_90_degrees_ccw, () {
              provider.rotateImage();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Imagen rotada'),
                  backgroundColor: Colors.black,
                ),
              );
            }),
            _buildOptionButton('Ajustar Brillo', Icons.brightness_6, () {
              _showBrightnessDialog(provider);
              Navigator.pop(context);
            }),
            _buildOptionButton('Ajustar Contraste', Icons.contrast, () {
              _showContrastDialog(provider);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _showCropDialog(StoryEditorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Recortar Imagen',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Selecciona el área que deseas conservar. Esta función te permite ajustar el encuadre de tu imagen.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.cropImage(const Rect.fromLTWH(0, 0, 100, 100));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Imagen recortada'),
                  backgroundColor: Colors.black,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recortar'),
          ),
        ],
      ),
    );
  }

  void _showBrightnessDialog(StoryEditorProvider provider) {
    double brightnessValue = 0.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Ajustar Brillo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: brightnessValue,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      brightnessValue = value;
                    });
                  },
                ),
                Text('Brillo: ${brightnessValue.toStringAsFixed(1)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.adjustBrightness(brightnessValue);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Brillo ajustado a ${brightnessValue.toStringAsFixed(1)}'),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContrastDialog(StoryEditorProvider provider) {
    double contrastValue = 1.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Ajustar Contraste'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: contrastValue,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (value) {
                    setState(() {
                      contrastValue = value;
                    });
                  },
                ),
                Text('Contraste: ${contrastValue.toStringAsFixed(1)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.adjustContrast(contrastValue);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contraste ajustado a ${contrastValue.toStringAsFixed(1)}'),
                      backgroundColor: Colors.black,
                    ),
                  );
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSelectedElement(StoryEditorProvider provider) {
    if (provider.selectedElement != null) {
      provider.deleteElement(provider.selectedElement!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elemento eliminado'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  TextStyle _createTextStyle() {
    return TextStyle(
      color: _selectedColor,
      fontSize: _textSize,
      fontWeight: _selectedFont == 'Negrita' ? FontWeight.bold : FontWeight.normal,
      fontStyle: _selectedFont == 'Cursiva' ? FontStyle.italic : FontStyle.normal,
      shadows: _selectedColor == Colors.white ? [
        const Shadow(
          blurRadius: 10,
          color: Colors.black,
          offset: Offset(2, 2),
        ),
      ] : null,
    );
  }

  void _saveStory(StoryEditorProvider provider) {
    final editedImage = provider.finalImage;
    Navigator.pop(context, editedImage);
  }
}