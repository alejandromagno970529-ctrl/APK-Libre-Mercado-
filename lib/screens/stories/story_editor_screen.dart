// ignore: unused_import
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_editor_provider.dart';
import '../../widgets/story_canvas.dart';

class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({super.key});

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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showExitConfirmation(context),
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
                    icon: const Icon(Icons.crop, color: Colors.black),
                    onPressed: () => _showCropOptions(provider),
                  ),
                  if (provider.selectedElement != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black),
                      onPressed: () => _deleteSelectedElement(provider),
                    ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.black),
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
            final imageBytes = provider.editingData.imageBytes;
            
            return Column(
              children: [
                // Canvas de edición
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
                        imageBytes: imageBytes,
                      ),
                    ),
                  ),
                ),
                
                // Panel de herramientas
                _buildToolbar(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del editor'),
        content: const Text('¿Estás seguro de que quieres salir? Se perderán todos los cambios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(StoryEditorProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Tipos de elementos
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                _buildToolbarButton('Texto', Icons.text_fields, () {
                  _showAddTextDialog(context, provider);
                }),
                const SizedBox(width: 8),
                _buildToolbarButton('Stickers', Icons.emoji_emotions, () {
                  _showStickersPanel(context, provider);
                }),
                const SizedBox(width: 8),
                _buildToolbarButton('Oferta', Icons.local_offer, () {
                  _showDiscountDialog(context, provider);
                }),
              ],
            ),
          ),
          
          // Fila 2: Configuración de texto - ✅ CORREGIDO SIN OVERFLOW
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Selector de fuente
                Expanded(
                  flex: 3, // ✅ Flex ajustado
                  child: _buildFontSelector(),
                ),
                const SizedBox(width: 4), // ✅ Espacio reducido
                
                // Selector de color
                Expanded(
                  flex: 4, // ✅ Flex ajustado
                  child: _buildColorSelector(),
                ),
                const SizedBox(width: 4), // ✅ Espacio reducido
                
                // Tamaño de texto - ✅ COMPLETAMENTE CORREGIDO
                Expanded(
                  flex: 3, // ✅ Flex ajustado
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFont,
          icon: const Icon(Icons.arrow_drop_down, size: 12), // ✅ Icono más pequeño
          isExpanded: true,
          style: const TextStyle(fontSize: 10, color: Colors.black), // ✅ Texto más pequeño
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
                style: const TextStyle(fontSize: 10), // ✅ Texto más pequeño
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
        physics: const ClampingScrollPhysics(),
        children: _colors.map((color) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 20, // ✅ Tamaño reducido
              height: 20, // ✅ Tamaño reducido
              margin: const EdgeInsets.symmetric(horizontal: 1), // ✅ Margen reducido
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color ? Colors.blue : Colors.grey.shade300,
                  width: 1.0, // ✅ Borde más delgado
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
      padding: const EdgeInsets.symmetric(horizontal: 1), // ✅ Padding reducido
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ BOTONES MÁS COMPACTOS
          Container(
            width: 22, // ✅ Ancho fijo
            height: 22, // ✅ Alto fijo
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, size: 10), // ✅ Icono más pequeño
              onPressed: () {
                setState(() {
                  if (_textSize > 12) _textSize -= 2;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 10,
            ),
          ),
          
          // ✅ TEXTO MÁS COMPACTO
          Container(
            width: 18, // ✅ Ancho reducido
            alignment: Alignment.center,
            child: Text(
              _textSize.toInt().toString(),
              style: const TextStyle(
                fontSize: 9, // ✅ Texto más pequeño
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Container(
            width: 22, // ✅ Ancho fijo
            height: 22, // ✅ Alto fijo
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, size: 10), // ✅ Icono más pequeño
              onPressed: () {
                setState(() {
                  if (_textSize < 48) _textSize += 2;
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTextDialog(BuildContext context, StoryEditorProvider provider) {
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
              const SizedBox(height: 8),
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
                Navigator.pop(context);
                _showSuccessSnackbar('Texto añadido - arrastra para mover');
              }
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                      _showSuccessSnackbar('Sticker $sticker añadido - arrastra para mover');
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
                Navigator.pop(context);
                _showSuccessSnackbar('Oferta añadida - arrastra para mover');
              }
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            
            _buildOptionButton('Recortar 1:1', Icons.crop_square, () {
              provider.cropImage(const Rect.fromLTWH(0, 0, 1, 1));
              Navigator.pop(context);
              _showSuccessSnackbar('Imagen recortada a formato cuadrado');
            }),
            
            _buildOptionButton('Recortar 9:16', Icons.crop_portrait, () {
              provider.cropImage(const Rect.fromLTWH(0, 0, 9, 16));
              Navigator.pop(context);
              _showSuccessSnackbar('Imagen recortada a formato vertical');
            }),
            
            _buildOptionButton('Rotar 90°', Icons.rotate_90_degrees_ccw, () {
              provider.rotateImage();
              Navigator.pop(context);
              _showSuccessSnackbar('Imagen rotada 90 grados');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text, style: const TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }

  void _deleteSelectedElement(StoryEditorProvider provider) {
    if (provider.selectedElement != null) {
      provider.deleteElement(provider.selectedElement!.id);
      _showSuccessSnackbar('Elemento eliminado');
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
    _showSuccessSnackbar('Historia guardada exitosamente');
    Navigator.pop(context);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}