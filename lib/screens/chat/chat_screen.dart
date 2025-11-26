// lib/screens/chat/chat_screen.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.productId,
    required this.otherUserId,
    this.otherUserName = 'Usuario',
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSendButton = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final shouldShowSend = _messageController.text.trim().isNotEmpty;
      if (_showSendButton != shouldShowSend) {
        setState(() {
          _showSendButton = shouldShowSend;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    try {
      final chatProvider = context.read<ChatProvider>();
      final agreementProvider = context.read<AgreementProvider>();
      final authProvider = context.read<AuthProvider>();

      // Cargar mensajes y acuerdos
      await Future.wait([
        chatProvider.loadChatMessages(widget.chatId),
        agreementProvider.loadAgreementsForChat(widget.chatId),
      ]);

      // Marcar mensajes como leídos
      if (authProvider.currentUser != null) {
        chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
      }

      _isInitialized = true;
      
      // Scroll al final después de cargar
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error inicializando chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Limpiar controlador inmediatamente
    _messageController.clear();
    setState(() => _showSendButton = false);

    try {
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: text,
        fromId: currentUser.id,
        fromName: currentUser.username,
        productTitle: 'Producto', // ✅ Deberías obtener esto del producto real
        toUserId: widget.otherUserId,
      );
      
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Restaurar mensaje en caso de error
      _messageController.text = text;
      setState(() => _showSendButton = true);
    }
  }

  Widget _buildMessageBubble(Message message, String currentUserId) {
    final isMe = message.fromId == currentUserId;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[500] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isMe ? Colors.white70 : Colors.grey[500],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Botón de emoji (placeholder)
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
            onPressed: () {
              // 
            },
          ),
          
          // Campo de texto
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  // Botón adjuntar
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                    onPressed: () {
                      // 
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón enviar/grabar
          GestureDetector(
            onTap: _showSendButton ? _sendMessage : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _showSendButton ? Colors.blue[500] : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showSendButton ? Icons.send : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Hoy';
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final agreementProvider = context.watch<AgreementProvider>();

    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Usuario no autenticado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = chatProvider.getMessages(widget.chatId);
    final agreements = agreementProvider.getAgreements(widget.chatId);

    // Combinar y ordenar mensajes y acuerdos
    final List<dynamic> allItems = [...messages, ...agreements];
    allItems.sort((a, b) {
      final DateTime aDate = a is Message ? a.createdAt : (a as TransactionAgreement).createdAt;
      final DateTime bDate = b is Message ? b.createdAt : (b as TransactionAgreement).createdAt;
      return aDate.compareTo(bDate);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: Colors.black),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.otherUserAvatar != null 
                    ? NetworkImage(widget.otherUserAvatar!) 
                    : null,
                child: widget.otherUserAvatar == null 
                    ? const Icon(Icons.person, color: Colors.grey, size: 16) 
                    : null,
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.black
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'En línea',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Botón de acuerdo de transacción
          TransactionAgreementButton(
            chatId: widget.chatId,
            productId: widget.productId,
            buyerId: currentUser.id,
            sellerId: widget.otherUserId,
            onAgreementCreated: (agreement) {
              // El provider actualiza la lista automáticamente
              _scrollToBottom();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: chatProvider.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : allItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay mensajes aún',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sé el primero en enviar un mensaje',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final currentDate = item is Message 
                              ? item.createdAt 
                              : (item as TransactionAgreement).createdAt;
                          
                          // Verificar si es el primer elemento del día
                          bool showDate = index == allItems.length - 1;
                          if (index < allItems.length - 1) {
                            final nextItem = allItems[index + 1];
                            final nextDate = nextItem is Message 
                                ? nextItem.createdAt 
                                : (nextItem as TransactionAgreement).createdAt;
                            showDate = !_isSameDay(currentDate, nextDate);
                          }
                          
                          return Column(
                            children: [
                              if (showDate) _buildDateSeparator(currentDate),
                              if (item is Message)
                                _buildMessageBubble(item, currentUser.id)
                              else if (item is TransactionAgreement)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: AgreementMessageWidget(
                                    agreement: item,
                                    isCurrentUser: currentUser.id == item.buyerId || 
                                                  currentUser.id == item.sellerId,
                                    onStatusUpdate: (agreement, status) {
                                      agreementProvider.updateAgreementStatus(agreement.id, status);
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
          
          // Área de entrada
          _buildInputArea(),
        ],
      ),
    );
  }
}