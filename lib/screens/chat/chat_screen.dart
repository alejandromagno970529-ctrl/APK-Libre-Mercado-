import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/providers/chat_provider.dart';
import 'package:libre_mercado_final__app/providers/auth_provider.dart';
import 'package:libre_mercado_final__app/providers/agreement_provider.dart';
import 'package:libre_mercado_final__app/models/message_model.dart';
import 'package:libre_mercado_final__app/models/transaction_agreement.dart';
import 'package:libre_mercado_final__app/widgets/transaction_agreement_button.dart';
import 'package:libre_mercado_final__app/widgets/agreement_message_widget.dart';
import 'package:libre_mercado_final__app/services/file_upload_service.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';

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

  // Servicios - inicialización temporal
  late final FileUploadService _fileUploadService;
  // ignore: unused_field
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    // Inicializar servicios
    _fileUploadService = FileUploadService(ImageUploadService(Supabase.instance.client));

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

      await Future.wait([
        chatProvider.loadChatMessages(widget.chatId),
        agreementProvider.loadAgreementsForChat(widget.chatId),
      ]);

      if (authProvider.currentUser != null) {
        chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
      }

      _isInitialized = true;
      _scrollToBottom();
      
    } catch (e) {
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

  // Métodos para archivos
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Documento'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Imagen'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendFile() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
      }
      return;
    }

    try {
      final files = await _fileUploadService.pickFiles(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (files == null || files.isEmpty) return;

      final file = files.first;
      final filePath = file.path;
      if (filePath == null) return;

      final fileToSend = File(filePath);

      await chatProvider.sendFileMessage(
        chatId: widget.chatId,
        fromId: currentUser.id,
        fromName: currentUser.username,
        productTitle: 'Producto',
        toUserId: widget.otherUserId,
        file: fileToSend,
        fileName: file.name,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    try {
      final files = await _fileUploadService.pickFiles(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (files == null || files.isEmpty) return;

      final file = files.first;
      final filePath = file.path;
      if (filePath == null) return;

      final imageFile = File(filePath);

      await chatProvider.sendFileMessage(
        chatId: widget.chatId,
        fromId: currentUser.id,
        fromName: currentUser.username,
        productTitle: 'Producto',
        toUserId: widget.otherUserId,
        file: imageFile,
        fileName: file.name,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método temporal para manejar grabación (sin funcionalidad completa)
  void _handleAudioRecording() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidad de audio en desarrollo')),
      );
    }
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
              
            },
          ),
          
          // Botón adjuntar
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey[600]),
            onPressed: _showAttachmentOptions,
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
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón enviar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _showSendButton ? Colors.blue[500] : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _showSendButton ? Icons.send : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _showSendButton 
                  ? _sendMessage 
                  : _handleAudioRecording,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Usuario no autenticado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _messageController.clear();
    setState(() => _showSendButton = false);

    try {
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: text,
        fromId: currentUser.id,
        fromName: currentUser.username,
        productTitle: 'Producto',
        toUserId: widget.otherUserId,
      );
      
      _scrollToBottom();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          TransactionAgreementButton(
            chatId: widget.chatId,
            productId: widget.productId,
            buyerId: currentUser.id,
            sellerId: widget.otherUserId,
            onAgreementCreated: (agreement) {
              _scrollToBottom();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              
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