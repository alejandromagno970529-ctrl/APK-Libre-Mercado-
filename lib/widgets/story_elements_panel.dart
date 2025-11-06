import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';
import '../models/story_editing_models.dart';

class StoryElementsPanel extends StatelessWidget {
  const StoryElementsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);
    
    // Mostrar panel diferente según la herramienta seleccionada
    switch (provider.selectedTool) {
      case StoryElementType.text:
        return _TextEditorPanel(provider: provider);
      case StoryElementType.sticker:
        return _StickersPanel(provider: provider);
      case StoryElementType.discountTag:
        return _DiscountPanel(provider: provider);
      case StoryElementType.cta:
        return _CTAPanel(provider: provider);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TextEditorPanel extends StatelessWidget {
  final StoryEditorProvider provider;

  const _TextEditorPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey[800],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selector de fuentes
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FontOption(
                  fontFamily: 'Roboto',
                  isSelected: true,
                  onTap: () {},
                ),
                _FontOption(
                  fontFamily: 'OpenSans',
                  isSelected: false,
                  onTap: () {},
                ),
                _FontOption(
                  fontFamily: 'Montserrat',
                  isSelected: false,
                  onTap: () {},
                ),
                _FontOption(
                  fontFamily: 'Poppins',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Selector de colores
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ColorOption(color: Colors.white, isSelected: true, onTap: () {}),
                _ColorOption(color: Colors.black, isSelected: false, onTap: () {}),
                _ColorOption(color: Colors.red, isSelected: false, onTap: () {}),
                _ColorOption(color: Colors.blue, isSelected: false, onTap: () {}),
                _ColorOption(color: Colors.green, isSelected: false, onTap: () {}),
                _ColorOption(color: Colors.yellow, isSelected: false, onTap: () {}),
                _ColorOption(color: Colors.purple, isSelected: false, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickersPanel extends StatelessWidget {
  final StoryEditorProvider provider;

  const _StickersPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.grey[800],
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: provider.availableStickers.length,
        itemBuilder: (context, index) {
          final sticker = provider.availableStickers[index];
          return GestureDetector(
            onTap: () {
              // El sticker se añadirá al hacer tap en el canvas
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  sticker,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscountPanel extends StatelessWidget {
  final StoryEditorProvider provider;

  const _DiscountPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.grey[800],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Ej: 50%',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  // El descuento se añadirá al hacer tap en el canvas
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CTAPanel extends StatelessWidget {
  final StoryEditorProvider provider;

  const _CTAPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.grey[800],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Texto del CTA (Ej: Comprar ahora)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'URL de destino',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontOption extends StatelessWidget {
  final String fontFamily;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontOption({
    required this.fontFamily,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            'Aa',
            style: TextStyle(
              fontFamily: fontFamily,
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}