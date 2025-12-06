import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final_app/providers/chat_provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/providers/typing_provider.dart';
import 'package:libre_mercado_final_app/widgets/chat_badge_indicator.dart';
import 'package:libre_mercado_final_app/screens/chat/chat_screen.dart';
import 'package:libre_mercado_final_app/models/chat_model.dart';
import 'package:libre_mercado_final_app/services/presence_service.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late PresenceService _presenceService;
  final Map<String, Map<String, dynamic>> _userPresence = {};
  final Map<String, Timer> _presenceTimers = {};
  final Map<String, StreamSubscription> _typingSubscriptions = {};
  
  @override
  void initState() {
    super.initState();
    _presenceService = PresenceService();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }

  @override
  void dispose() {
    _cleanupTimersAndSubscriptions();
    super.dispose();
  }

  void _cleanupTimersAndSubscriptions() {
    // Limpiar timers de presencia
    for (final timer in _presenceTimers.values) {
      timer.cancel();
    }
    _presenceTimers.clear();
    
    // Limpiar suscripciones de typing
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();
  }

  Future<void> _loadChats() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    if (authProvider.currentUser != null) {
      try {
        await chatProvider.loadUserChats(authProvider.currentUser!.id);
        
        // Configurar timers de presencia para cada chat
        _setupPresenceTimers(chatProvider.chatsList, authProvider.currentUser!.id);
        
        // Configurar suscripciones de typing
        _setupTypingSubscriptions(chatProvider.chatsList);
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando chats: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _setupPresenceTimers(List<Chat> chats, String currentUserId) {
    // Limpiar timers anteriores
    _cleanupTimersAndSubscriptions();
    
    // Configurar timer de presencia para cada chat (actualizar cada 60 segundos)
    for (final chat in chats) {
      _presenceTimers[chat.id] = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) {
          _updatePresenceForChat(chat, currentUserId);
        }
      });
      
      // Cargar presencia inicial
      _updatePresenceForChat(chat, currentUserId);
    }
  }

  void _setupTypingSubscriptions(List<Chat> chats) {
    final typingProvider = context.read<TypingProvider>();
    
    for (final chat in chats) {
      final subscription = typingProvider.subscribeToTypingEvents(chat.id, (userId) {
        if (mounted) {
          setState(() {
            // La UI se actualizará automáticamente porque el TypingProvider notifica
          });
        }
      });
      
      // ignore: unnecessary_null_comparison
      if (subscription != null) {
        _typingSubscriptions[chat.id] = subscription;
      }
    }
  }

  Future<void> _updatePresenceForChat(Chat chat, String currentUserId) async {
    try {
      final otherUserId = chat.getOtherUserId(currentUserId);
      final presence = await _presenceService.getUserPresence(otherUserId);
      
      if (mounted) {
        setState(() {
          // ignore: unnecessary_null_comparison
          if (presence != null) {
            _userPresence[chat.id] = presence;
          // ignore: dead_code
          } else {
            // Datos por defecto
            _userPresence[chat.id] = {
              'online': false,
              'last_seen': chat.updatedAt.toIso8601String(),
            };
          }
        });
      }
    } catch (e) {
      // Silenciar error de presencia
    }
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Desconectado';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'En línea';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 2) return 'Ayer';
    
    return DateFormat('d MMM').format(lastSeen);
  }

  Future<void> _confirmDeleteChat(Chat chat, ChatProvider chatProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el chat con ${chat.otherUserName ?? 'Usuario'}? '
          '\n\nEsta acción eliminará todos los mensajes permanentemente.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat(chat.id, chatProvider);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String chatId, ChatProvider chatProvider) async {
    try {
      await chatProvider.deleteChat(chatId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat eliminado completamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChatMenu(Chat chat, ChatProvider chatProvider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar conversación'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chat, chatProvider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatus(bool isOnline, DateTime? lastSeen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isOnline ? 'En línea' : 'Últ. vez ${_formatLastSeen(lastSeen)}',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? Colors.green : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(Chat chat, ChatProvider chatProvider, String currentUserId) {
    final presence = _userPresence[chat.id];
    final isOnline = presence?['online'] == true;
    
    // Manejo robusto de tipos para last_seen
    DateTime? lastSeen;
    final lastSeenData = presence?['last_seen'];
    
    if (lastSeenData != null) {
      if (lastSeenData is DateTime) {
        lastSeen = lastSeenData;
      } else if (lastSeenData is String) {
        lastSeen = DateTime.tryParse(lastSeenData);
      }
    }

    return Consumer<TypingProvider>(
      builder: (context, typingProvider, _) {
        final typingUserId = typingProvider.getTypingUser(chat.id);
        final isOtherUserTyping = typingUserId != null && typingUserId != currentUserId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onLongPress: () {
              _showChatMenu(chat, chatProvider, context);
            },
            onTap: () {
              if (chat.productAvailable == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Este producto ya no está disponible'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chat.id,
                    productId: chat.productId,
                    otherUserId: chat.getOtherUserId(currentUserId),
                    otherUserName: chat.otherUserName ?? 'Usuario',
                    otherUserAvatar: chat.otherUserAvatar,
                  ),
                ),
              ).then((_) {
                _loadChats();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar con badge de notificaciones y typing
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipOval(
                          child: chat.otherUserAvatar != null && chat.otherUserAvatar!.isNotEmpty
                              ? Image.network(
                                  chat.otherUserAvatar!,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, size: 28, color: Colors.grey[600]);
                                  },
                                )
                              : Icon(Icons.person, size: 28, color: Colors.grey[600]),
                        ),
                      ),
                      
                      // Badge de notificaciones/typing
                      Positioned(
                        top: 0,
                        right: 0,
                        child: ChatBadgeIndicator(
                          unreadCount: chat.unreadCount,
                          isTyping: isOtherUserTyping,
                          size: chat.unreadCount > 0 ? 20 : 16,
                        ),
                      ),
                      
                      // Indicador de estado en línea
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Nombre del usuario
                            Expanded(
                              child: Text(
                                chat.otherUserName ?? 'Usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // Tiempo del último mensaje
                            Text(
                              _formatLastMessageTime(chat.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Estado en línea/última vez
                        _buildOnlineStatus(isOnline, lastSeen),
                        
                        const SizedBox(height: 4),
                        
                        // Información del producto
                        Text(
                          chat.productTitle ?? 'Producto',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Indicador de typing
                        if (isOtherUserTyping) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTypingDots(),
                              const SizedBox(width: 6),
                              Text(
                                'escribiendo...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ] else if (chat.lastMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            chat.lastMessage!,
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            // Precio del producto
                            if (chat.productPrice != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '\$${chat.productPrice!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            
                            const Spacer(),
                            
                            // Estado del producto
                            if (chat.productAvailable == false)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Vendido',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 36,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedDot(0),
          _buildAnimatedDot(1),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600 + (index * 200)),
        curve: Curves.easeInOut,
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.blue[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider, String userId) {
    final chats = chatProvider.chatsList;

    if (chatProvider.isLoading && chats.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (chatProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${chatProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes mensajes',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando contactes a un vendedor,\ntus conversaciones aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: Colors.black,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatItem(chat, chatProvider, userId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _loadChats(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: authProvider.currentUser == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Inicia sesión para ver tus mensajes',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _buildChatList(chatProvider, authProvider.currentUser!.id),
    );
  }
}