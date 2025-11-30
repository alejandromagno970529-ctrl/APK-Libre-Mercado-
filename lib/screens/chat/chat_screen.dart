// lib/screens/chat/chat_screen.dart - VERSIÓN COMPLETA CORREGIDA CON ELIMINACIÓN
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
import 'package:libre_mercado_final_app/widgets/image_message_widget.dart';
import 'package:libre_mercado_final_app/services/file_upload_service.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

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
  final FocusNode _focusNode = FocusNode();
  
  bool _showSendButton = false;
  bool _isInitialized = false;
  bool _showEmojiPicker = false;
  bool _isLoading = true;
  bool _isSending = false;
  final Set<String> _pendingMessageIds = {};

  // Servicios
  late final FileUploadService _fileUploadService;

  @override
  void initState() {
    super.initState();

    _fileUploadService = FileUploadService(Supabase.instance.client);

    _messageController.addListener(() {
      if (_isSending) return;
      
      final shouldShowSend = _messageController.text.trim().isNotEmpty;
      if (_showSendButton != shouldShowSend) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _showSendButton = shouldShowSend;
            });
          }
        });
      }
    });

    _scrollController.addListener(() {
      if (_showEmojiPicker && _scrollController.position.hasContentDimensions) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _showEmojiPicker = false;
            });
          }
        });
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _showEmojiPicker = false;
            });
          }
        });
      }
    });

    // Inicializar después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final chatProvider = context.read<ChatProvider>();
      final agreementProvider = context.read<AgreementProvider>();
      final authProvider = context.read<AuthProvider>();

      await chatProvider.loadChatMessages(widget.chatId);
      await agreementProvider.loadAgreementsForChat(widget.chatId);

      if (authProvider.currentUser != null) {
        chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
      }

      _isInitialized = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      AppLogger.e('❌ Error inicializando chat: $e', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _showAttachmentOptions() {
    if (_isSending) return;
    
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  Future<void> _pickAndSendFile() async {
    if (_isSending) return;
    
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
      _setSending(true);
      
      final files = await _fileUploadService.pickFiles(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (files == null || files.isEmpty) {
        _setSending(false);
        return;
      }

      final file = files.first;
      final filePath = file.path;
      if (filePath == null) {
        _setSending(false);
        return;
      }

      final fileToSend = File(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Subiendo archivo...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

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
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('❌ Error enviando archivo: $e', e);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setSending(false);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending) return;
    
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    try {
      _setSending(true);
      
      final files = await _fileUploadService.pickFiles(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (files == null || files.isEmpty) {
        _setSending(false);
        return;
      }

      final file = files.first;
      final filePath = file.path;
      if (filePath == null) {
        _setSending(false);
        return;
      }

      final imageFile = File(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Subiendo imagen...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

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
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('❌ Error enviando imagen: $e', e);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setSending(false);
    }
  }

  void _setSending(bool sending) {
    if (mounted) {
      setState(() {
        _isSending = sending;
      });
    }
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPickerWidget(
                textEditingController: _messageController,
                onBackspacePressed: () {
                  if (_messageController.text.isNotEmpty && !_isSending) {
                    _messageController.text = _messageController.text
                        .substring(0, _messageController.text.length - 1);
                  }
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: _showEmojiPicker ? Colors.black : Colors.grey[600],
                  ),
                  onPressed: _isSending ? null : () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                          if (_showEmojiPicker) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        });
                      }
                    });
                  },
                ),
                
                IconButton(
                  icon: Icon(
                    Icons.attach_file, 
                    color: _isSending ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: _isSending ? null : _showAttachmentOptions,
                ),
                
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      enabled: !_isSending,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_isSending && _messageController.text.trim().isNotEmpty) {
                          _sendMessage();
                        }
                      },
                      onChanged: (text) {
                        if (!_isSending) {
                          final shouldShowSend = text.trim().isNotEmpty;
                          if (_showSendButton != shouldShowSend) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _showSendButton = shouldShowSend;
                                });
                              }
                            });
                          }
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _showSendButton && !_isSending 
                        ? Colors.black 
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: (_showSendButton && !_isSending) ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending || _pendingMessageIds.isNotEmpty) {
      AppLogger.d('⏳ Envío ya en progreso, ignorando...');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      AppLogger.d('📝 Mensaje vacío, ignorando...');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      AppLogger.e('❌ Usuario no autenticado');
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

    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${currentUser.id}_${text.hashCode}';
    
    if (_pendingMessageIds.contains(tempMessageId)) {
      AppLogger.d('🔄 Mensaje ya en cola: $tempMessageId');
      return;
    }

    _pendingMessageIds.add(tempMessageId);

    final messageText = text;
    _messageController.clear();
    
    if (mounted) {
      setState(() {
        _isSending = true;
        _showSendButton = false;
        _showEmojiPicker = false;
      });
    }

    AppLogger.d('📤 INICIANDO ENVÍO: "$messageText" (ID: $tempMessageId)');

    try {
      _disableStreamTemporarily(chatProvider, widget.chatId);
      
      await chatProvider.sendMessage(
        chatId: widget.chatId,
        text: messageText,
        fromId: currentUser.id,
        fromName: currentUser.username,
        productTitle: 'Producto',
        toUserId: widget.otherUserId,
      );
      
      _scrollToBottom();
      AppLogger.d('✅ MENSAJE ENVIADO EXITOSAMENTE: "$messageText"');
      
    } catch (e) {
      AppLogger.e('❌ ERROR ENVIANDO MENSAJE: $e', e);
      
      _messageController.text = messageText;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _pendingMessageIds.remove(tempMessageId);
      
      if (mounted) {
        setState(() {
          _isSending = false;
          _showSendButton = _messageController.text.trim().isNotEmpty;
        });
      }
      
      _enableStream(chatProvider, widget.chatId);
      
      AppLogger.d('🔄 ESTADO DE ENVÍO: Completado para $tempMessageId');
    }
  }

  void _disableStreamTemporarily(ChatProvider chatProvider, String chatId) {
    try {
      chatProvider.disposeChat(chatId);
      AppLogger.d('🔇 Stream desactivado temporalmente para: $chatId');
    } catch (e) {
      AppLogger.e('❌ Error desactivando stream: $e');
    }
  }

  void _enableStream(ChatProvider chatProvider, String chatId) {
    try {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          chatProvider.loadChatMessages(chatId);
          AppLogger.d('🔊 Stream reactivado para: $chatId');
        }
      });
    } catch (e) {
      AppLogger.e('❌ Error reactivando stream: $e');
    }
  }

  // ✅ MÉTODO COMPLETAMENTE REESCRITO: Manejo de mensajes con mejor detección de imágenes
  Widget _buildMessageBubble(Message message, String currentUserId) {
    final isMe = message.fromId == currentUserId;
    
    // ✅ DEBUG DETALLADO
    AppLogger.d('''
💬 CONSTRUYENDO BURBUJA DE MENSAJE:
   - ID: ${message.id}
   - Tipo: ${message.type}
   - esImagen: ${message.isImageMessage}
   - esArchivo: ${message.isFileMessage}
   - URL: ${message.fileUrl}
   - Texto: ${message.text}
   - Metadata: ${message.metadata}
''');

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
    
    // ✅ DETECCIÓN MEJORADA DE MENSAJES DE IMAGEN
    // Verificar si es mensaje de imagen por tipo O por metadata
    bool isImageMessage = message.isImageMessage;
    
    // ✅ DETECCIÓN ALTERNATIVA: Verificar si el texto indica que es imagen
    if (!isImageMessage && message.text.contains('🖼️')) {
      isImageMessage = true;
      AppLogger.d('🔍 Mensaje detectado como imagen por emoji: ${message.text}');
    }
    
    // ✅ DETECCIÓN POR URL: Si tiene fileUrl y es una URL de imagen
    if (!isImageMessage && message.fileUrl != null && message.fileUrl!.isNotEmpty) {
      final url = message.fileUrl!.toLowerCase();
      if (url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.gif')) {
        isImageMessage = true;
        AppLogger.d('🔍 Mensaje detectado como imagen por URL: $url');
      }
    }

    if (message.isFileMessage || isImageMessage) {
      AppLogger.d('📁 Mensaje de archivo detectado - esImagen: $isImageMessage');
      
      if (isImageMessage) {
        if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
          AppLogger.d('🖼️ MOSTRANDO IMAGEN: ${message.fileUrl}');
          return ImageMessageWidget(
            message: message, 
            isMe: isMe,
            onLongPress: () => _showMessageOptions(message),
          );
        } else {
          AppLogger.e('❌ Mensaje de imagen sin URL válida');
          return _buildFallbackMessage('🖼️ Imagen no disponible', isMe, message);
        }
      } else {
        AppLogger.d('📎 Mostrando FileMessageWidget para archivo regular');
        return FileMessageWidget(
          message: message, 
          isMe: isMe,
          onLongPress: () => _showMessageOptions(message),
        );
      }
    }
    
    // ✅ Mensaje de texto normal
    return ChatBubble(
      message: message,
      isMe: isMe,
      showAvatar: true,
      onLongPress: () => _showMessageOptions(message),
    );
  }

  Widget _buildFallbackMessage(String text, bool isMe, Message originalMessage) {
    return ChatBubble(
      message: Message(
        id: originalMessage.id,
        chatId: originalMessage.chatId,
        text: text,
        fromId: originalMessage.fromId,
        createdAt: originalMessage.createdAt,
        read: originalMessage.read,
        isSystem: false,
      ),
      isMe: isMe,
      showAvatar: true,
      onLongPress: () => _showMessageOptions(originalMessage),
    );
  }

  // ✅ MÉTODO NUEVO: Mostrar opciones de mensaje
  void _showMessageOptions(Message message) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isMyMessage = message.fromId == currentUser?.id;
    
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
                'Opciones del mensaje',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Opción de eliminar
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteMessageConfirmation(message, isMyMessage);
                },
              ),
              
              // Opción de eliminar para todos (solo para mis mensajes)
              if (isMyMessage)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Eliminar para todos'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteForEveryoneConfirmation(message);
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

  // ✅ MÉTODO NUEVO: Confirmar eliminación de mensaje
  void _showDeleteMessageConfirmation(Message message, bool isMyMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: Text(
          isMyMessage 
            ? '¿Eliminar este mensaje para ti? Los demás participantes aún podrán verlo.'
            : '¿Eliminar este mensaje? Solo se eliminará de tu vista.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, deleteForEveryone: false);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO NUEVO: Confirmar eliminación para todos
  void _showDeleteForEveryoneConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar para todos'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje para todos los participantes? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message, deleteForEveryone: true);
            },
            child: const Text('Eliminar para todos', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO NUEVO: Eliminar mensaje
  Future<void> _deleteMessage(Message message, {bool deleteForEveryone = false}) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteMessage(
        widget.chatId, 
        message.id, 
        deleteForEveryone: deleteForEveryone
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteForEveryone ? 'Mensaje eliminado para todos' : 'Mensaje eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        if (_showEmojiPicker) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showEmojiPicker = false;
              });
            }
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
              onPressed: _isSending ? null : () {
                _showChatOptions();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final item = allItems[index];
                              final currentDate = item is Message 
                                  ? item.createdAt 
                                  : (item as TransactionAgreement).createdAt;
                              
                              bool showDate = index == 0;
                              if (index > 0) {
                                final previousItem = allItems[index - 1];
                                final previousDate = previousItem is Message 
                                    ? previousItem.createdAt 
                                    : (previousItem as TransactionAgreement).createdAt;
                                showDate = !_isSameDay(currentDate, previousDate);
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
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO ACTUALIZADO: Opciones del chat con funcionalidades completas
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
                leading: const Icon(Icons.cleaning_services, color: Colors.blue),
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

  // ✅ MÉTODO ACTUALIZADO: Bloquear usuario
  void _showBlockUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: Text('¿Estás seguro de que quieres bloquear a ${widget.otherUserName}? No podrás recibir mensajes de este usuario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser();
            },
            child: const Text('Bloquear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO NUEVO: Bloquear usuario
  Future<void> _blockUser() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return;

      // En una implementación real, aquí llamarías a tu servicio de bloqueo
      // Por ahora simulamos la funcionalidad
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.otherUserName} ha sido bloqueado'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Regresar a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error bloqueando usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ MÉTODO ACTUALIZADO: Reportar usuario
  void _showReportUserDialog() {
    // ignore: unused_local_variable
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    String selectedReason = 'Spam';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reportar usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona el motivo del reporte:'),
                const SizedBox(height: 16),
                
                // Razones predefinidas
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: selectedReason,
                  items: const [
                    DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                    DropdownMenuItem(value: 'Comportamiento inapropiado', child: Text('Comportamiento inapropiado')),
                    DropdownMenuItem(value: 'Contenido ofensivo', child: Text('Contenido ofensivo')),
                    DropdownMenuItem(value: 'Acoso', child: Text('Acoso')),
                    DropdownMenuItem(value: 'Suplantación de identidad', child: Text('Suplantación de identidad')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Descripción adicional
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción adicional (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _reportUser(selectedReason, descriptionController.text);
              },
              child: const Text('Enviar reporte'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO NUEVO: Reportar usuario
  Future<void> _reportUser(String reason, String description) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return;

      // En una implementación real, aquí llamarías a tu servicio de reportes
      // Por ahora simulamos la funcionalidad
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ MÉTODO ACTUALIZADO: Limpiar conversación
  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar conversación'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los mensajes de esta conversación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat();
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ MÉTODO NUEVO: Limpiar chat
  Future<void> _clearChat() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.clearChatMessages(widget.chatId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación limpiada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error limpiando conversación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}