// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/agreement_provider.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/models/transaction_agreement.dart';
import 'package:libre_mercado_final__app/widgets/transaction_agreement_button.dart';
import 'package:libre_mercado_final__app/widgets/agreement_message_widget.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String productId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.productId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageStream();
    _markMessagesAsRead();
    _loadAgreements();
  }

  void _loadMessages() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadChatMessages(widget.chatId);
  }

  void _setupMessageStream() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.getMessageStream(widget.chatId).listen((messages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        _markMessagesAsRead();
      });
    });
  }

  void _loadAgreements() {
    final agreementProvider = context.read<AgreementProvider>();
    agreementProvider.loadAgreementsForChat(widget.chatId);
  }

  void _markMessagesAsRead() {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    if (authProvider.currentUser != null) {
      chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
    }
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

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
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _onAgreementCreated(TransactionAgreement agreement) {
    // El acuerdo ya se guardó en la BD a través del provider
    // Podemos mostrar un mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Acuerdo creado y enviado al otro usuario'),
        backgroundColor: Colors.green,
      ),
    );

    // Enviar mensaje de sistema sobre el nuevo acuerdo
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
      
      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Acuerdo $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error actualizando acuerdo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSellerId() {
    context.read<AuthProvider>();
    
    // Si el currentUser es el vendedor, el otherUserId es el comprador y viceversa
    // Por simplicidad, asumimos que el otherUserId es el vendedor
    // En una implementación real, deberías obtener esta info de la base de datos
    return widget.otherUserId;
  }

  String _getBuyerId() {
    final authProvider = context.read<AuthProvider>();
    return authProvider.currentUser!.id;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final agreementProvider = context.watch<AgreementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        actions: [
          // Botón de acuerdo de transacción
          TransactionAgreementButton(
            chatId: widget.chatId,
            productId: widget.productId,
            buyerId: _getBuyerId(),
            sellerId: _getSellerId(),
            onAgreementCreated: _onAgreementCreated,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de acuerdo de transacción
          _buildAgreementBanner(agreementProvider),
          Expanded(
            child: _buildMessageList(chatProvider, agreementProvider, authProvider),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAgreementBanner(AgreementProvider agreementProvider) {
    final agreements = agreementProvider.getAgreements(widget.chatId);
    final pendingAgreements = agreements.where((a) => a.status == 'pending').toList();

    if (pendingAgreements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.amber[50],
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Llegaron a un acuerdo? Crea un acuerdo formal de transacción',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si hay acuerdos pendientes, mostrar el más reciente
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

  Widget _buildMessageList(ChatProvider chatProvider, AgreementProvider agreementProvider, AuthProvider authProvider) {
    final messages = chatProvider.getMessages(widget.chatId);
    final agreements = agreementProvider.getAgreements(widget.chatId);

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

    // Combinar mensajes y acuerdos para mostrar en orden cronológico
    final allItems = _combineMessagesAndAgreements(messages, agreements);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        
        if (item.isMessage) {
          final message = item.message!;
          final isMe = message.fromId == authProvider.currentUser?.id;
          final isSystem = message.fromId == 'system';
          return _buildMessageBubble(message, isMe, isSystem);
        } else {
          final agreement = item.agreement!;
          final isCurrentUser = authProvider.currentUser?.id == agreement.buyerId || 
                              authProvider.currentUser?.id == agreement.sellerId;
          return AgreementMessageWidget(
            agreement: agreement,
            isCurrentUser: isCurrentUser,
            onStatusUpdate: _onAgreementStatusUpdate,
          );
        }
      },
    );
  }

  List<_ChatItem> _combineMessagesAndAgreements(List<Message> messages, List<TransactionAgreement> agreements) {
    final allItems = <_ChatItem>[
      ...messages.map((message) => _ChatItem(message: message)),
      ...agreements.map((agreement) => _ChatItem(agreement: agreement)),
    ];

    // Ordenar por fecha de creación
    allItems.sort((a, b) {
      final aTime = a.message?.createdAt ?? a.agreement!.createdAt;
      final bTime = b.message?.createdAt ?? b.agreement!.createdAt;
      return aTime.compareTo(bTime);
    });

    return allItems;
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool isSystem) {
    if (isSystem) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.amber : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isMe ? Colors.black54 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.read ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
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
          CircleAvatar(
            backgroundColor: _isSending ? Colors.grey : Colors.amber,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.black87),
                    onPressed: _sendMessage,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Helper class para combinar mensajes y acuerdos
class _ChatItem {
  final Message? message;
  final TransactionAgreement? agreement;

  _ChatItem({this.message, this.agreement})
      : assert(message != null || agreement != null,
            'Debe proporcionar un mensaje o un acuerdo');

  bool get isMessage => message != null;
  bool get isAgreement => agreement != null;
}