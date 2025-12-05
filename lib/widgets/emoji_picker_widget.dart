// lib/widgets/emoji_picker_widget.dart - VERSIÓN CORREGIDA SIN OVERFLOW
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
  final List<String> _recentEmojis = ['😀', '😂', '❤️', '👋', '💕', '🎉', '🍕', '☕'];
  
  final List<String> _smileysEmojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥲', '☺️',
    '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗',
    '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓',
    '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕',
    '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤',
    '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰',
    '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑',
    '😬', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤',
    '😪', '😵', '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕',
    '🤑', '🤠', '😈', '👿', '👹', '👺', '🤡', '💩', '👻', '💀',
    '☠️', '👽', '👾', '🤖', '🎃', '😺', '😸', '😹', '😻', '😼',
    '😽', '🙀', '😿', '😾'
  ];

  final List<String> _animalsEmojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
    '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇',
    '🐺', '🐗', '🐴', '🦄', '🐝', '🪲', '🐛', '🦋', '🐌', '🐞',
    '🐜', '🪰', '🪱', '🦟', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍',
    '🦎', '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡', '🐠',
    '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅', '🐆', '🦓', '🦍',
    '🦧', '🦣', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🦬',
    '🐃', '🐂', '🐄', '🐎', '🐖', '🐏', '🐑', '🦙', '🐐', '🦌',
    '🐕', '🐩', '🦮', '🐕‍🦺', '🐈', '🐈‍⬛', '🪶', '🐓', '🦃', '🦤',
    '🦚', '🦜', '🦢', '🦩', '🕊️', '🐇', '🦝', '🦨', '🦡', '🦫',
    '🦦', '🦥', '🐁', '🐀', '🐿️', '🦔', '🐾', '🐉', '🐲', '🌵',
    '🎄', '🌲', '🌳', '🌴', '🪵', '🌱', '🌿', '☘️', '🍀', '🎍',
    '🪴', '🎋', '🍃', '🍂', '🍁', '🪺', '🪹', '🍄', '🐚', '🪸'
  ];

  final List<String> _foodEmojis = [
    '🍇', '🍈', '🍉', '🍊', '🍋', '🍌', '🍍', '🥭', '🍎', '🍏',
    '🍐', '🍑', '🍒', '🍓', '🫐', '🥝', '🍅', '🫒', '🥥', '🥑',
    '🍆', '🥔', '🥕', '🌽', '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄',
    '🧅', '🍄', '🥜', '🌰', '🍞', '🥐', '🥖', '🫓', '🥨', '🥯',
    '🥞', '🧇', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕',
    '🌭', '🥪', '🌮', '🌯', '🫔', '🥙', '🧆', '🥚', '🍳', '🥘',
    '🍲', '🫕', '🥣', '🥗', '🍿', '🧈', '🧂', '🥫', '🍱', '🍘',
    '🍙', '🍚', '🍛', '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥',
    '🥮', '🍡', '🥟', '🥠', '🥡', '🦪', '🍦', '🍧', '🍨', '🍩',
    '🍪', '🎂', '🍰', '🧁', '🥧', '🍫', '🍬', '🍭', '🍮', '🍯',
    '🍼', '🥛', '☕', '🫖', '🍵', '🍶', '🍾', '🍷', '🍸', '🍹',
    '🍺', '🍻', '🥂', '🥃', '🫗', '🥤', '🧋', '🧃', '🧉', '🧊'
  ];

  final List<String> _activitiesEmojis = [
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
    '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳',
    '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛶',
    '🎿', '⛷️', '🏂', '🪂', '🏋️', '🤼', '🤸', '⛹️', '🤺', '🤾',
    '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽', '🚣', '🧗', '🚴', '🚵',
    '🎯', '🪀', '🎮', '🎰', '🎲', '🧩', '♟️', '🎨', '🎭', '🎤',
    '🎧', '🎼', '🎹', '🥁', '🪘', '🎷', '🎺', '🎸', '🪕', '🎻',
    '🪗', '🎬', '🏆', '🎪', '🎟️', '🎫', '🎖️', '🏅', '🥇', '🥈',
    '🥉', '🎭', '🎨', '🖼️', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷',
    '🎺', '🎸', '🎻', '🪕', '🎬', '🎮', '👾', '🕹️', '🎲', '♟️'
  ];

  final List<String> _travelEmojis = [
    '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
    '🚚', '🚛', '🚜', '🛴', '🚲', '🛵', '🏍️', '🛺', '🚨', '🚔',
    '🚍', '🚘', '🚖', '🚡', '🚠', '🚟', '🚃', '🚋', '🚞', '🚝',
    '🚄', '🚅', '🚈', '🚂', '🚆', '🚇', '🚊', '🚉', '✈️', '🛫',
    '🛬', '🛩️', '💺', '🛰️', '🚀', '🛸', '🚁', '🛶', '⛵', '🚤',
    '🛥️', '🛳️', '⛴️', '🚢', '⚓', '🛟', '🌋', '🗻', '🏕️', '🏖️',
    '🏜️', '🏝️', '🏞️', '🏟️', '🏛️', '🏗️', '🧱', '🪨', '🪵', '🛖',
    '🏘️', '🏚️', '🏠', '🏡', '🏢', '🏣', '🏤', '🏥', '🏦', '🏨',
    '🏩', '🏪', '🏫', '🏬', '🏭', '🏯', '🏰', '💒', '🗼', '🗽'
  ];

  final List<String> _objectsEmojis = [
    '⌚', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️',
    '🗜️', '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹', '🎥',
    '📽️', '🎞️', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙️', '🎚️',
    '🎛️', '🧭', '⏱️', '⏲️', '⏰', '🕰️', '⌛', '⏳', '📡', '🔋',
    '🪫', '🔌', '💡', '🔦', '🕯️', '🪔', '🧯', '🛢️', '💸', '💵',
    '💴', '💶', '💷', '🪙', '💰', '💳', '💎', '⚖️', '🪜', '🧰',
    '🪛', '🔧', '🔨', '⚒️', '🛠️', '⛏️', '🪚', '🔩', '⚙️', '🪤',
    '🧱', '🪨', '🪵', '🧲', '🪜', '🧪', '🧫', '🧬', '🔬', '🔭',
    '📡', '💉', '🩸', '💊', '🩹', '🩺', '🩻', '🚪', '🛗', '🪞'
  ];

  final List<String> _symbolsEmojis = [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️',
    '☦️', '🛐', '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎',
    '♏', '♐', '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️',
    '📴', '📳', '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚', '💮',
    '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎',
    '🆑', '🅾️', '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯'
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Recientes', 'icon': '🕒', 'emojis': []},
    {'name': 'Emoticonos', 'icon': '😀', 'emojis': []},
    {'name': 'Animales', 'icon': '🐶', 'emojis': []},
    {'name': 'Comida', 'icon': '🍕', 'emojis': []},
    {'name': 'Actividades', 'icon': '⚽', 'emojis': []},
    {'name': 'Viajes', 'icon': '🚗', 'emojis': []},
    {'name': 'Objetos', 'icon': '⌚', 'emojis': []},
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
      height: 240, // ✅ REDUCIDO DE 300 A 240 (60px menos)
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de categorías - REDUCIDA
          SizedBox(
            height: 40, // ✅ REDUCIDO DE 50 A 40
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon'],
                          style: const TextStyle(fontSize: 16), // ✅ REDUCIDO
                        ),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 8, // ✅ MUY PEQUEÑO
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

          // Grid de emojis - AJUSTADO PARA NO OVERFLOW
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  childAspectRatio: 1.0, // ✅ CUADRADO PERFECTO
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
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20), // ✅ REDUCIDO
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Barra inferior - MÁS COMPACTA
          Container(
            height: 40, // ✅ REDUCIDO DE 50 A 40
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.grey, size: 18),
                  onPressed: widget.onBackspacePressed,
                  padding: const EdgeInsets.all(4),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}