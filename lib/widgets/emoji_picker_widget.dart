// lib/widgets/emoji_picker_widget.dart - VERSIÓN CORREGIDA SIN DEPENDENCIAS EXTERNAS
import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final VoidCallback onBackspacePressed;

  const EmojiPickerWidget({
    super.key,
    required this.textEditingController,
    required this.onBackspacePressed,
  });

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  // Listas de emojis organizados por categorías
  final List<String> _recentEmojis = ['😀', '😂', '❤️', '👍', '🔥', '🎉', '🙏', '🥰'];
  
  final List<String> _smileysEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
    '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
    '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
    '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
    '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
    '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
    '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈'
  ];

  final List<String> _animalsEmojis = [
    '🐵', '🐒', '🦍', '🦧', '🐶', '🐕', '🦮', '🐕‍🦺', '🐩', '🐺',
    '🦊', '🦝', '🐱', '🐈', '🐈‍⬛', '🦁', '🐯', '🐅', '🐆', '🐴',
    '🐎', '🦄', '🦓', '🦌', '🐮', '🐂', '🐃', '🐄', '🐷', '🐖',
    '🐗', '🐽', '🐏', '🐑', '🐐', '🐪', '🐫', '🦙', '🦒', '🐘',
    '🦏', '🦛', '🐭', '🐁', '🐀', '🐹', '🐰', '🐇', '🐿️', '🦔',
    '🦇', '🐻', '🐻‍❄️', '🐨', '🐼', '🦥', '🦦', '🦨', '🦘', '🦡',
    '🐾', '🦃', '🐔', '🐓', '🐣', '🐤', '🐥', '🐦', '🐧', '🕊️',
    '🦅', '🦆', '🦢', '🦉', '🦤', '🪶', '🦩', '🦚', '🦜', '🐸',
    '🐊', '🐢', '🦎', '🐍', '🐲', '🐉', '🦕', '🦖', '🐳', '🐋',
    '🐬', '🦭', '🐟', '🐠', '🐡', '🦈', '🐙', '🐚', '🐌', '🦋',
    '🐛', '🐜', '🐝', '🪲', '🐞', '🦗', '🕷️', '🕸️', '🦂', '🦟'
  ];

  final List<String> _foodEmojis = [
    '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈',
    '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦',
    '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🫒', '🧄', '🧅', '🥔',
    '🍠', '🥐', '🥯', '🍞', '🥖', '🥨', '🧀', '🥚', '🍳', '🧈',
    '🥞', '🧇', '🥓', '🥩', '🍗', '🍖', '🦴', '🌭', '🍔', '🍟',
    '🍕', '🫓', '🥪', '🥙', '🧆', '🌮', '🌯', '🫔', '🥗', '🥘',
    '🫕', '🥫', '🍝', '🍜', '🍲', '🍛', '🍣', '🍱', '🥟', '🦪',
    '🍤', '🍙', '🍚', '🍘', '🍥', '🥠', '🥮', '🍢', '🍡', '🍧',
    '🍨', '🍦', '🥧', '🧁', '🍰', '🎂', '🍮', '🍭', '🍬', '🍫'
  ];

  final List<String> _activitiesEmojis = [
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
    '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🎿', '⛷️', '🏂',
    '🪂', '🏋️‍♀️', '🏋️', '🏋️‍♂️', '🤼‍♀️', '🤼', '🤼‍♂️', '🤸‍♀️', '🤸', '🤸‍♂️',
    '⛹️‍♀️', '⛹️', '⛹️‍♂️', '🤺', '🤾‍♀️', '🤾', '🤾‍♂️', '🏌️‍♀️', '🏌️', '🏌️‍♂️',
    '🏇', '🧘‍♀️', '🧘', '🧘‍♂️', '🏄‍♀️', '🏄', '🏄‍♂️', '🏊‍♀️', '🏊', '🏊‍♂️',
    '🤽‍♀️', '🤽', '🤽‍♂️', '🚣‍♀️', '🚣', '🚣‍♂️', '🧗‍♀️', '🧗', '🧗‍♂️', '🚵‍♀️',
    '🚵', '🚵‍♂️', '🚴‍♀️', '🚴', '🚴‍♂️', '🏆', '🥇', '🥈', '🥉', '🏅',
    '🎖️', '🏵️', '🎗️', '🎫', '🎟️', '🎪', '🤹‍♀️', '🤹', '🤹‍♂️', '🎭',
    '🩰', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🪘', '🎷',
    '🎺', '🎸', '🪕', '🎻', '🎲', '♟️', '🎯', '🎳', '🎮', '🎰'
  ];

  final List<String> _travelEmojis = [
    '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
    '🛻', '🚚', '🚛', '🚜', '🏍️', '🛵', '🚲', '🛴', '🛹', '🛼',
    '🚁', '🛩️', '✈️', '🛫', '🛬', '🪂', '💺', '🚀', '🛸', '🚉',
    '🚊', '🚝', '🚄', '🚅', '🚈', '🚂', '🚆', '🚇', '🚋', '🚌',
    '🚞', '🛶', '⛵', '🛳️', '🚢', '✈️', '🛰️', '🚀', '🛎️', '🧳',
    '⌛', '⏳', '⌚', '⏰', '⏱️', '⏲️', '🕰️', '🌍', '🌎', '🌏',
    '🗺️', '🧭', '🏔️', '⛰️', '🌋', '🗻', '🏕️', '🏖️', '🏜️', '🏝️',
    '🏞️', '🏟️', '🏛️', '🏗️', '🧱', '🪨', '🪵', '🛖', '🏘️', '🏚️'
  ];

  final List<String> _objectsEmojis = [
    '💡', '🔦', '🕯️', '🪔', '🧯', '🪓', '⛏️', '🪚', '🔨', '🪛',
    '🔧', '🪜', '⚗️', '🧪', '🧫', '🧬', '🔬', '🔭', '📡', '💉',
    '🩸', '💊', '🩹', '🩺', '🚪', '🪑', '🛋️', '🛏️', '🛌', '🧸',
    '🪆', '🖼️', '🪞', '🪟', '🛍️', '🛒', '🎁', '🎈', '🎏', '🎀',
    '🎊', '🎉', '🎎', '🏮', '🎐', '✉️', '📩', '📨', '📧', '💌',
    '📥', '📤', '📦', '🏷️', '📪', '📫', '📬', '📭', '📮', '📯',
    '📜', '📃', '📄', '📑', '🧾', '📊', '📈', '📉', '🗒️', '🗓️',
    '📆', '📅', '🗑️', '📇', '🗃️', '🗳️', '🗄️', '📋', '📁', '📂',
    '🗂️', '🗞️', '📰', '📓', '📔', '📒', '📕', '📗', '📘', '📙'
  ];

  final List<String> _symbolsEmojis = [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
    '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
    '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐',
    '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳',
    '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️',
    '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️',
    '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️'
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Recientes', 'icon': '🕒', 'emojis': []},
    {'name': 'Emoticonos', 'icon': '😀', 'emojis': []},
    {'name': 'Animales', 'icon': '🐻', 'emojis': []},
    {'name': 'Comida', 'icon': '🍕', 'emojis': []},
    {'name': 'Actividades', 'icon': '⚽', 'emojis': []},
    {'name': 'Viajes', 'icon': '🚗', 'emojis': []},
    {'name': 'Objetos', 'icon': '💡', 'emojis': []},
    {'name': 'Símbolos', 'icon': '❤️', 'emojis': []},
  ];

  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar las categorías con sus emojis
    _categories[0]['emojis'] = _recentEmojis;
    _categories[1]['emojis'] = _smileysEmojis;
    _categories[2]['emojis'] = _animalsEmojis;
    _categories[3]['emojis'] = _foodEmojis;
    _categories[4]['emojis'] = _activitiesEmojis;
    _categories[5]['emojis'] = _travelEmojis;
    _categories[6]['emojis'] = _objectsEmojis;
    _categories[7]['emojis'] = _symbolsEmojis;
  }

  void _addToRecent(String emoji) {
    if (!_recentEmojis.contains(emoji)) {
      setState(() {
        _recentEmojis.insert(0, emoji);
        if (_recentEmojis.length > 20) {
          _recentEmojis.removeLast();
        }
        _categories[0]['emojis'] = _recentEmojis;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmojis = _categories[_selectedCategoryIndex]['emojis'] as List<String>;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barra de categorías
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = index == _selectedCategoryIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.blue : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Grid de emojis
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.0,
                ),
                itemCount: currentEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = currentEmojis[index];
                  
                  return GestureDetector(
                    onTap: () {
                      widget.textEditingController.text += emoji;
                      _addToRecent(emoji);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Barra inferior con botón de borrar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.grey),
                  onPressed: widget.onBackspacePressed,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Cerrar el selector de emojis
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Listo',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}