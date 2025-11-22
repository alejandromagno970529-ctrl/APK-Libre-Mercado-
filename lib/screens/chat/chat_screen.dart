import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/agreement_provider.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/models/transaction_agreement.dart';
import 'package:libre_mercado_final__app/widgets/transaction_agreement_button.dart';
import 'package:libre_mercado_final__app/widgets/agreement_message_widget.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String productId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.productId,
    required this.otherUserId,
    this.otherUserName = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isSending = false;
  bool _isInitialized = false;
  // ignore: unused_field
  bool _shouldAutoScroll = true;

  // ✅ ESTADO PARA MODO SELECCIÓN
  bool _isSelectionMode = false;
  Set<String> _selectedMessages = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupScrollListener();
  }

  Future<void> _initializeChat() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final agreementProvider = context.read<AgreementProvider>();
      final authProvider = context.read<AuthProvider>();

      // ✅ VERIFICAR SI EL STREAM YA ESTÁ INICIALIZADO
      if (!chatProvider.getMessages(widget.chatId).isEmpty) {
        AppLogger.d('✅ Chat ya inicializado, omitiendo carga inicial');
        _isInitialized = true;
        if (mounted) setState(() {});
        return;
      }

      await chatProvider.loadChatMessages(widget.chatId);
      await agreementProvider.loadAgreementsForChat(widget.chatId);
      
      if (authProvider.currentUser != null) {
        await chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
      }

      _isInitialized = true;
      if (mounted) setState(() {});
      
    } catch (e) {
      AppLogger.e('Error inicializando chat', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      _shouldAutoScroll = (maxScroll - currentScroll) < 100;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ✅ MENÚ CONTEXTUAL PARA MENSAJES
  void _showMessageMenu(Message message, BuildContext context) {
    // ignore: unused_local_variable
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final isMyMessage = message.fromId == authProvider.currentUser?.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyMessage) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text('Enviado: ${_formatExactTime(message.createdAt)}'),
            ),
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

  // ✅ CONFIRMAR ELIMINACIÓN DE MENSAJE
  void _confirmDeleteMessage(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ ELIMINAR MENSAJE
  Future<void> _deleteMessage(Message message) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteMessage(message.id, widget.chatId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mensaje eliminado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar mensaje: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ ELIMINAR CHAT COMPLETO
  Future<void> _deleteChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta conversación completa? \n\nEsta acción eliminará todos los mensajes permanentemente y no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final chatProvider = context.read<ChatProvider>();
                await chatProvider.deleteChat(widget.chatId);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Conversación eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al eliminar conversación: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MODO SELECCIÓN
  void _enableSelectionMode() {
    setState(() {
      _selectedMessages = {};
      _isSelectionMode = true;
    });
  }

  void _disableSelectionMode() {
    setState(() {
      _selectedMessages.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }
      
      if (_selectedMessages.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  // ✅ ELIMINAR MENSAJES SELECCIONADOS
  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessages.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensajes'),
        content: Text('¿Estás seguro de que quieres eliminar ${_selectedMessages.length} mensaje(s) seleccionado(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final chatProvider = context.read<ChatProvider>();
                await chatProvider.deleteMultipleMessages(
                  _selectedMessages.toList(), 
                  widget.chatId
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ${_selectedMessages.length} mensaje(s) eliminado(s)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _disableSelectionMode();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al eliminar mensajes: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para enviar mensajes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: _messageController.text,
        fromId: currentUser.id,
      );
      
      _messageController.clear();
      _focusNode.requestFocus();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ✅ BURBUJA DE MENSAJE CON SELECCIÓN
  Widget _buildMessageBubble(Message message, bool isMe, bool isSystem, AuthProvider authProvider) {
    if (isSystem) {
      return _buildSystemMessage(message);
    }

    final isSelected = _selectedMessages.contains(message.id);
    final isSelectable = _isSelectionMode && isMe;

    return GestureDetector(
      onLongPress: () {
        if (isMe && !_isSelectionMode) {
          _enableSelectionMode();
          _toggleMessageSelection(message.id);
        } else if (isSelectable) {
          _toggleMessageSelection(message.id);
        } else if (!_isSelectionMode) {
          _showMessageMenu(message, context);
        }
      },
      onTap: () {
        if (_isSelectionMode && isSelectable) {
          _toggleMessageSelection(message.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue, width: 2),
              )
            : null,
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) 
              _buildAvatar(isMe: false),
            
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.blue[50]
                    : (isMe ? Colors.black : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatExactTime(message.createdAt),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.read ? Colors.blue : Colors.grey[400],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (isMe) 
              _buildAvatar(isMe: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isMe}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 8 : 0,
        right: isMe ? 0 : 8,
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isMe ? Colors.black : Colors.grey,
        child: Icon(Icons.person, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _isSending ? Colors.grey : Colors.black,
              shape: BoxShape.circle,
            ),
            child: _isSending
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
          ),
        ],
      ),
    );
  }

  List<_ChatItem> _combineMessagesAndAgreements(
    List<Message> messages, 
    List<TransactionAgreement> agreements
  ) {
    final allItems = <_ChatItem>[
      ...messages.map((message) => _ChatItem(message: message)),
      ...agreements.map((agreement) => _ChatItem(agreement: agreement)),
    ];

    allItems.sort((a, b) {
      final aTime = a.message?.createdAt ?? a.agreement!.createdAt;
      final bTime = b.message?.createdAt ?? b.agreement!.createdAt;
      return aTime.compareTo(bTime);
    });

    return allItems;
  }

  Widget _buildMessageList(ChatProvider chatProvider, AgreementProvider agreementProvider, AuthProvider authProvider) {
    final messages = chatProvider.getMessages(widget.chatId);
    final agreements = agreementProvider.getAgreements(widget.chatId);

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (messages.isEmpty && agreements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Inicia la conversación',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Coordina los detalles de la transacción aquí',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final allItems = _combineMessagesAndAgreements(messages, agreements);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        
        if (item.isMessage) {
          final message = item.message!;
          final isMe = message.fromId == authProvider.currentUser?.id;
          final isSystem = message.isSystemMessage;
          return _buildMessageBubble(message, isMe, isSystem, authProvider);
        } else {
          final agreement = item.agreement!;
          final isCurrentUser = authProvider.currentUser?.id == agreement.buyerId || 
                              authProvider.currentUser?.id == agreement.sellerId;
          return AgreementMessageWidget(
            agreement: agreement,
            isCurrentUser: isCurrentUser,
            onStatusUpdate: (agreement, newStatus) {
              _onAgreementStatusUpdate(agreement, newStatus);
            },
          );
        }
      },
    );
  }

  void _onAgreementCreated(TransactionAgreement agreement) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Acuerdo creado y enviado al otro usuario'),
          backgroundColor: Colors.green,
        ),
      );
    }

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendSystemMessage(
      chatId: widget.chatId,
      text: '📝 Se ha creado un nuevo acuerdo de transacción. Por favor revisa los detalles.',
    );
  }

  void _onAgreementStatusUpdate(TransactionAgreement agreement, String newStatus) async {
    try {
      final agreementProvider = context.read<AgreementProvider>();
      await agreementProvider.updateAgreementStatus(agreement.id, newStatus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Acuerdo $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error actualizando acuerdo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatExactTime(DateTime dateTime) {
    final chatProvider = context.read<ChatProvider>();
    return chatProvider.formatMessageTime(dateTime);
  }

  Widget _buildAgreementBanner(AgreementProvider agreementProvider) {
    final agreements = agreementProvider.getAgreements(widget.chatId);
    final pendingAgreements = agreements.where((a) => a.status == 'pending').toList();

    if (pendingAgreements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[50],
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Llegaron a un acuerdo? Crea un acuerdo formal de transacción',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latestAgreement = pendingAgreements.last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.handshake, size: 16, color: Colors.blue[800]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acuerdo pendiente de confirmación',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Precio: \$${latestAgreement.agreedPrice} • Lugar: ${latestAgreement.meetingLocation}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ APP BAR CON MODO SELECCIÓN
  PreferredSizeWidget _buildAppBar(AuthProvider authProvider) {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _disableSelectionMode,
        ),
        title: Text('${_selectedMessages.length} seleccionado(s)'),
        actions: [
          if (_selectedMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedMessages,
              tooltip: 'Eliminar seleccionados',
            ),
        ],
      );
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.otherUserName),
          Text(
            'Chat sobre producto',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete_chat') {
              _deleteChat();
            } else if (value == 'select_messages') {
              _enableSelectionMode();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_messages',
              child: Row(
                children: [
                  Icon(Icons.select_all, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Seleccionar mensajes'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_chat',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar conversación'),
                ],
              ),
            ),
          ],
        ),
        TransactionAgreementButton(
          chatId: widget.chatId,
          productId: widget.productId,
          buyerId: authProvider.currentUser!.id,
          sellerId: widget.otherUserId,
          onAgreementCreated: _onAgreementCreated,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final agreementProvider = context.watch<AgreementProvider>();

    if (authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('Debes iniciar sesión para usar el chat'),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(authProvider),
      body: Column(
        children: [
          _buildAgreementBanner(agreementProvider),
          Expanded(
            child: _buildMessageList(chatProvider, agreementProvider, authProvider),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.d('🧹 Dispose ChatScreen');
    
    final chatProvider = context.read<ChatProvider>();
    chatProvider.cancelChatStream(widget.chatId);
    
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    super.dispose();
  }
}

class _ChatItem {
  final Message? message;
  final TransactionAgreement? agreement;

  _ChatItem({this.message, this.agreement})
      : assert(message != null || agreement != null,
            'Debe proporcionar un mensaje o un acuerdo');

  bool get isMessage => message != null;
  bool get isAgreement => agreement != null;
}