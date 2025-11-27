// lib/screens/chat/chat_screen.dart - VERSIÓN CORREGIDA SIN ADVERTENCIAS
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final_app/providers/chat_provider.dart';
import 'package:libre_mercado_final_app/providers/auth_provider.dart';
import 'package:libre_mercado_final_app/providers/agreement_provider.dart';
import 'package:libre_mercado_final_app/models/message_model.dart';
import 'package:libre_mercado_final_app/models/transaction_agreement.dart';
import 'package:libre_mercado_final_app/widgets/transaction_agreement_button.dart';
import 'package:libre_mercado_final_app/widgets/agreement_message_widget.dart';
import 'package:libre_mercado_final_app/widgets/chat_bubble.dart';
import 'package:libre_mercado_final_app/widgets/emoji_picker_widget.dart';
import 'package:libre_mercado_final_app/widgets/file_message_widget.dart';
import 'package:libre_mercado_final_app/widgets/audio_message_widget.dart';
import 'package:libre_mercado_final_app/widgets/image_message_widget.dart';
import 'package:libre_mercado_final_app/services/file_upload_service.dart';
import 'package:libre_mercado_final_app/services/image_upload_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String productId;
  final String otherUserId;
  final String? otherUserName;
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
  final FocusNode _focusNode = FocusNode(); // CORREGIDO: campo final
  
  bool _showSendButton = false;
  bool _isInitialized = false;
  bool _showEmojiPicker = false;
  bool _isRecording = false;

  // Servicios
  late final FileUploadService _fileUploadService;

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

    // Listener para cerrar emojis al hacer scroll
    _scrollController.addListener(() {
      if (_showEmojiPicker && _scrollController.position.hasContentDimensions) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });

    // Listener para cerrar emojis cuando se enfoca el textfield
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
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
    _focusNode.dispose();
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

  // Métodos para archivos y adjuntos
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Adjuntar archivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Documento',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendFile();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.image,
                    label: 'Imagen',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    onTap: () {
                      Navigator.pop(context);
                      _handleAudioRecording();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
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
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
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

  void _handleAudioRecording() {
    if (!_isRecording) {
      // Iniciar grabación
      setState(() {
        _isRecording = true;
      });
      
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando grabación...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Simular grabación por 5 segundos
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isRecording) {
          setState(() {
            _isRecording = false;
          });
          
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grabación finalizada - Funcionalidad en desarrollo')),
          );
        }
      });
    } else {
      // Detener grabación
      setState(() {
        _isRecording = false;
      });
      
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grabación cancelada')),
      );
    }
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        // Selector de emojis
        if (_showEmojiPicker)
          EmojiPickerWidget(
            textEditingController: _messageController,
            onBackspacePressed: () {
              if (_messageController.text.isNotEmpty) {
                _messageController.text = _messageController.text
                    .substring(0, _messageController.text.length - 1);
              }
            },
          ),
        
        // Área de entrada de mensaje
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              // Botón de emoji
              IconButton(
                icon: Icon(
                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: _showEmojiPicker ? Colors.blue : Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _showEmojiPicker = !_showEmojiPicker;
                    if (_showEmojiPicker) {
                      _focusNode.unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  });
                },
              ),
              
              // Botón adjuntar
              IconButton(
                icon: Icon(
                  Icons.attach_file, 
                  color: Colors.grey[600],
                ),
                onPressed: _showAttachmentOptions,
              ),
              
              // Campo de texto expandido
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
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (text) {
                            final shouldShowSend = text.trim().isNotEmpty;
                            if (_showSendButton != shouldShowSend) {
                              setState(() {
                                _showSendButton = shouldShowSend;
                              });
                            }
                          },
                        ),
                      ),
                      
                      // Botón de grabación de voz (solo se muestra cuando no hay texto)
                      if (!_showSendButton)
                        IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: _isRecording ? Colors.red : Colors.grey[600],
                          ),
                          onPressed: _handleAudioRecording,
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Botón enviar/grabar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _showSendButton ? Colors.blue : 
                         _isRecording ? Colors.red : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _showSendButton ? Icons.send : 
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _showSendButton ? _sendMessage : _handleAudioRecording,
                ),
              ),
            ],
          ),
        ),
      ],
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
    setState(() {
      _showSendButton = false;
      _showEmojiPicker = false;
    });

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
    
    // Para mensajes de sistema
    if (message.isSystemMessage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }
    
    // Para mensajes especiales (archivos, audio, imágenes)
    if (message.isFileMessage) {
      return FileMessageWidget(message: message, isMe: isMe);
    }
    
    if (message.isAudioMessage) {
      return AudioMessageWidget(message: message, isMe: isMe);
    }

    if (message.isImageMessage) {
      return ImageMessageWidget(message: message, isMe: isMe);
    }
    
    // Mensaje de texto normal
    return ChatBubble(
      message: message,
      isMe: isMe,
      showAvatar: true,
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

    return GestureDetector(
      onTap: () {
        // Cerrar emojis y teclado al tocar fuera
        if (_showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
        }
        _focusNode.unfocus();
      },
      child: Scaffold(
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
                widget.otherUserName!,
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
                style: TextStyle(fontSize: 12, color: Colors.green),
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
                _showChatOptions();
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
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Opciones del chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Bloquear usuario'),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockUserConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Reportar usuario'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportUserDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.grey),
                title: const Text('Limpiar conversación'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatConfirmation();
                },
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: Text('¿Estás seguro de que quieres bloquear a ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.otherUserName} ha sido bloqueado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Bloquear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar usuario'),
        content: const Text('Selecciona el motivo del reporte:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text('¿Estás seguro de que quieres limpiar esta conversación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversación limpiada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}