import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';
import '../models/story_editing_models.dart';
import 'image_cropper.dart';

class StoryEditorToolbar extends StatelessWidget {
  const StoryEditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);
    
    return Container(
      height: 120, // ✅ Altura suficiente para todos los controles
      color: Colors.grey[900],
      child: Column(
        children: [
          // Barra de herramientas principal
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ToolbarButton(
                  icon: Icons.text_fields,
                  label: 'Texto',
                  isSelected: provider.selectedTool == StoryElementType.text,
                  onTap: () => provider.selectTool(StoryElementType.text),
                ),
                _ToolbarButton(
                  icon: Icons.emoji_emotions,
                  label: 'Stickers',
                  isSelected: provider.selectedTool == StoryElementType.sticker,
                  onTap: () => provider.selectTool(StoryElementType.sticker),
                ),
                _ToolbarButton(
                  icon: Icons.local_offer,
                  label: 'Descuento',
                  isSelected: provider.selectedTool == StoryElementType.discountTag,
                  onTap: () => provider.selectTool(StoryElementType.discountTag),
                ),
                _ToolbarButton(
                  icon: Icons.link,
                  label: 'CTA',
                  isSelected: provider.selectedTool == StoryElementType.cta,
                  onTap: () => provider.selectTool(StoryElementType.cta),
                ),
                _ToolbarButton(
                  icon: Icons.crop,
                  label: 'Recortar',
                  isSelected: false,
                  onTap: () => _startCropping(context),
                ),
                _ToolbarButton(
                  icon: Icons.dashboard,
                  label: 'Plantillas',
                  isSelected: false,
                  onTap: () => _showTemplatesDialog(context),
                ),
                // ✅ BOTONES DE ACCIÓN INTEGRADOS
                _ActionButton(
                  icon: Icons.delete,
                  label: 'Limpiar',
                  color: Colors.red,
                  onTap: () => _showClearConfirmation(context),
                ),
                _ActionButton(
                  icon: Icons.undo,
                  label: 'Reset',
                  color: Colors.orange,
                  onTap: () => provider.resetTool(),
                ),
              ],
            ),
          ),
          
          // ✅ PANEL INFORMATIVO INTEGRADO
          _buildInfoPanel(provider),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(StoryEditorProvider provider) {
    return Container(
      height: 40,
      color: Colors.grey[800],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Información de herramienta
          Text(
            _getToolInfo(provider),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          
          // Contador de elementos
          Text(
            'Elementos: ${provider.elements.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getToolInfo(StoryEditorProvider provider) {
    // ignore: unnecessary_null_comparison
    if (provider.selectedTool == null) {
      return 'Selecciona una herramienta';
    }
    
    switch (provider.selectedTool) {
      case StoryElementType.text:
        return 'Toca en la imagen para agregar texto';
      case StoryElementType.sticker:
        return 'Toca en la imagen para agregar stickers';
      case StoryElementType.discountTag:
        return 'Toca en la imagen para agregar descuento';
      case StoryElementType.cta:
        return 'Toca en la imagen para agregar CTA';
      case StoryElementType.shape:
        return 'Toca en la imagen para agregar formas';
    }
  }

  void _startCropping(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    final imageBytes = provider.backgroundImageBytes;
    
    if (imageBytes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropper(
            imageBytes: imageBytes,
            provider: provider,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una imagen')),
      );
    }
  }

  void _showTemplatesDialog(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Plantillas',
          style: TextStyle(color: Colors.black),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.templates.length,
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              return _TemplateItem(
                template: template,
                onTap: () {
                  provider.applyTemplate(template);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Editor'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los elementos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<StoryEditorProvider>(context, listen: false);
              provider.clearEditor();
              Navigator.pop(context);
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[300],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final StoryTemplate template;
  final VoidCallback onTap;

  const _TemplateItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, size: 36, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                template.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.category,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}