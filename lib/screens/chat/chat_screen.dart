import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agreement_provider.dart';
import '../../models/message_model.dart';
import '../../models/transaction_agreement.dart';
import '../../widgets/transaction_agreement_button.dart';
import '../../widgets/agreement_message_widget.dart';

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
    this.otherUserName = '',
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSendButton = false;

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

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();
    final agreementProvider = context.read<AgreementProvider>();
    final authProvider = context.read<AuthProvider>();

    await chatProvider.loadChatMessages(widget.chatId);
    await agreementProvider.loadAgreementsForChat(widget.chatId);

    if (authProvider.currentUser != null) {
      chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
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
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    _messageController.clear();

    try {
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: text,
        fromId: currentUser.id,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final agreementProvider = context.watch<AgreementProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final messages = chatProvider.getMessages(widget.chatId);
    final agreements = agreementProvider.getAgreements(widget.chatId);
    final List<dynamic> allItems = [...messages, ...agreements];
    
    allItems.sort((a, b) {
      DateTime dateA = a is Message ? a.createdAt : (a as TransactionAgreement).createdAt;
      DateTime dateB = b is Message ? b.createdAt : (b as TransactionAgreement).createdAt;
      return dateB.compareTo(dateA); 
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
          borderRadius: BorderRadius.circular(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: Colors.black),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.otherUserAvatar != null 
                    ? NetworkImage(widget.otherUserAvatar!) 
                    : null,
                child: widget.otherUserAvatar == null 
                    ? const Icon(Icons.person, color: Colors.grey, size: 20) 
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'En línea',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TransactionAgreementButton(
            chatId: widget.chatId,
            productId: widget.productId,
            buyerId: currentUser.id,
            sellerId: widget.otherUserId,
            onAgreementCreated: (agreement) {
              // El provider actualiza la lista automáticamente
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                
                bool isFirstOfDate = false;
                bool isFirstInSequence = true;
                bool isLastInSequence = true;

                if (item is Message) {
                  if (index < allItems.length - 1) {
                    final prevItem = allItems[index + 1];
                    final currentDate = item.createdAt;
                    final prevDate = prevItem is Message ? prevItem.createdAt : (prevItem as TransactionAgreement).createdAt;
                    
                    if (!_isSameDay(currentDate, prevDate)) {
                      isFirstOfDate = true;
                    }

                    if (prevItem is Message && prevItem.fromId == item.fromId && !isFirstOfDate) {
                       isFirstInSequence = false;
                    }
                  } else {
                    isFirstOfDate = true;
                  }

                  if (index > 0) {
                    final nextItem = allItems[index - 1];
                    if (nextItem is Message && nextItem.fromId == item.fromId) {
                      isLastInSequence = false;
                    }
                  }
                } else if (item is TransactionAgreement) {
                   if (index < allItems.length - 1) {
                    final prevItem = allItems[index + 1];
                    final currentDate = item.createdAt;
                    final prevDate = prevItem is Message ? prevItem.createdAt : (prevItem as TransactionAgreement).createdAt;
                    if (!_isSameDay(currentDate, prevDate)) isFirstOfDate = true;
                   } else {
                     isFirstOfDate = true;
                   }
                }

                return Column(
                  children: [
                    if (isFirstOfDate) 
                      _buildDateChip(item is Message ? item.createdAt : (item as TransactionAgreement).createdAt),
                    
                    if (item is Message)
                      _ChatBubble(
                        message: item,
                        isMe: item.fromId == currentUser.id,
                        isFirstInSequence: isFirstInSequence,
                        isLastInSequence: isLastInSequence,
                      )
                    else if (item is TransactionAgreement)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AgreementMessageWidget(
                          agreement: item,
                          isCurrentUser: currentUser.id == item.buyerId || currentUser.id == item.sellerId,
                          currentUserName: currentUser.username, // ✅ CORREGIDO: name → username
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
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                      onPressed: () {},
                      padding: const EdgeInsets.only(bottom: 10),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Mensaje',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 6,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                      onPressed: () {},
                      padding: const EdgeInsets.only(bottom: 10),
                    ),
                    if (!_showSendButton)
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                        onPressed: () {},
                        padding: const EdgeInsets.only(bottom: 10),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showSendButton ? _sendMessage : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _showSendButton ? Colors.black : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showSendButton ? Icons.send : Icons.mic,
                  color: Colors.white, 
                  size: 24
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
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
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isFirstInSequence;
  final bool isLastInSequence;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    this.isFirstInSequence = true,
    this.isLastInSequence = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isMe 
          ? const Radius.circular(12) 
          : (isLastInSequence ? Radius.zero : const Radius.circular(12)),
      bottomRight: isMe 
          ? (isLastInSequence ? Radius.zero : const Radius.circular(12)) 
          : const Radius.circular(12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: isLastInSequence ? 6 : 2,
            left: isMe ? 0 : 4,
            right: isMe ? 4 : 0,
          ),
          child: Material(
            elevation: 0.5,
            color: isMe ? Colors.black : Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0, right: 20.0),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 16, 
                        color: isMe ? Colors.white : Colors.black87
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 11, 
                            color: isMe ? Colors.white70 : Colors.grey[600]
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read ? Icons.done_all : Icons.done,
                            size: 16,
                            color: isMe ? Colors.white70 : Colors.grey[500],
                          ),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}