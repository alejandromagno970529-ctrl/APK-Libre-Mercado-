import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_editor_provider.dart';
import '../models/story_editing_models.dart';

class StoryEditorToolbar extends StatelessWidget {
  const StoryEditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StoryEditorProvider>(context);
    
    return Container(
      height: 80,
      color: Colors.grey[900],
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
            icon: Icons.dashboard,
            label: 'Plantillas',
            isSelected: false,
            onTap: () => _showTemplatesDialog(context),
          ),
        ],
      ),
    );
  }

  void _showTemplatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plantillas'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: Provider.of<StoryEditorProvider>(context).templates.length,
            itemBuilder: (context, index) {
              final template = Provider.of<StoryEditorProvider>(context).templates[index];
              return _TemplateItem(template: template);
            },
          ),
        ),
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
        width: 70,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final StoryTemplate template;

  const _TemplateItem({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Provider.of<StoryEditorProvider>(context, listen: false)
              .applyTemplate(template);
          Navigator.pop(context);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              template.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}