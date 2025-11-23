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
  bool _showSendButton = false; // Controla si mostramos botón de enviar o micrófono

  @override
  void initState() {
    super.initState();
    // Listener para cambiar el icono de enviar dinámicamente
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

    // Cargar mensajes y acuerdos
    await chatProvider.loadChatMessages(widget.chatId);
    await agreementProvider.loadAgreementsForChat(widget.chatId);

    // Marcar como leídos si el usuario existe
    if (authProvider.currentUser != null) {
      chatProvider.markMessagesAsRead(widget.chatId, authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    // Importante: No cancelamos el stream global aquí para no romper la lista de chats,
    // pero limpiamos controladores locales.
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Como la lista es reverse: true, minScrollExtent es el "fondo" visual (inicio de la lista)
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
    } finally {
      if (mounted) {
        // nothing to do here; kept for symmetry with try/catch
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

    // 1. Obtener y combinar datos
    final messages = chatProvider.getMessages(widget.chatId);
    final agreements = agreementProvider.getAgreements(widget.chatId);
    final List<dynamic> allItems = [...messages, ...agreements];
    
    // 2. Ordenar por fecha descendente (lo más nuevo primero para reverse:true)
    allItems.sort((a, b) {
      DateTime dateA = a is Message ? a.createdAt : (a as TransactionAgreement).createdAt;
      DateTime dateB = b is Message ? b.createdAt : (b as TransactionAgreement).createdAt;
      return dateB.compareTo(dateA); 
    });

    return Scaffold(
      // Fondo crema estilo WhatsApp
      backgroundColor: const Color(0xFFEFE7DE), 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF075E54), // Verde WhatsApp clásico
        foregroundColor: Colors.white,
        titleSpacing: 0,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'En línea', // Aquí podrías conectar lógica real de presencia si la tuvieras
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Botón de Acuerdo (NO ELIMINADO)
          TransactionAgreementButton(
            chatId: widget.chatId,
            productId: widget.productId,
            buyerId: currentUser.id,
            sellerId: widget.otherUserId,
            onAgreementCreated: (agreement) {
              // El provider actualiza la lista automáticamente
            },
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Los chats empiezan de abajo hacia arriba
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                
                // Lógica de fechas y agrupación
                // Nota: en reverse list, index+1 es el elemento "anterior" en el tiempo
                //       index-1 es el elemento "siguiente" en el tiempo (más nuevo)
                
                bool isFirstOfDate = false;
                bool isFirstInSequence = true; // Primer mensaje del bloque (arriba visualmente)
                bool isLastInSequence = true;  // Último mensaje del bloque (abajo visualmente)

                if (item is Message) {
                  // Chequear fecha (comparando con el siguiente elemento de la lista, que es más viejo)
                  if (index < allItems.length - 1) {
                    final prevItem = allItems[index + 1];
                    final currentDate = item.createdAt;
                    final prevDate = prevItem is Message ? prevItem.createdAt : (prevItem as TransactionAgreement).createdAt;
                    
                    if (!_isSameDay(currentDate, prevDate)) {
                      isFirstOfDate = true;
                    }

                    // Chequear secuencia visual (si el mensaje anterior era del mismo usuario)
                    if (prevItem is Message && prevItem.fromId == item.fromId && !isFirstOfDate) {
                       isFirstInSequence = false;
                    }
                  } else {
                    isFirstOfDate = true; // Es el mensaje más antiguo cargado
                  }

                  // Chequear si el mensaje SIGUIENTE (index - 1, más nuevo) es del mismo usuario
                  if (index > 0) {
                    final nextItem = allItems[index - 1];
                    if (nextItem is Message && nextItem.fromId == item.fromId) {
                      isLastInSequence = false;
                    }
                  }
                } else if (item is TransactionAgreement) {
                   // Los acuerdos siempre rompen secuencia y muestran fecha si cambia
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

  // Widget optimizado de Input
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparente para ver el fondo
      ),
      child: SafeArea( // Protege contra gestos de iPhone/Android modernos
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                      onPressed: () {}, // Implementar selector luego
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
                      onPressed: () {}, // Implementar adjuntos luego
                      padding: const EdgeInsets.only(bottom: 10),
                    ),
                    if (!_showSendButton)
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                        onPressed: () {}, // Implementar cámara luego
                        padding: const EdgeInsets.only(bottom: 10),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showSendButton ? _sendMessage : null, // O acción de grabar audio
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF00897B), // Verde botón envío
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5FE), // Azul muy suave
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            // ignore: deprecated_member_use
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)
          ]
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w500),
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

// ==========================================
// WIDGET INTERNO DE BURBUJA DE CHAT (OPTIMIZADO)
// ==========================================
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
    // Configuración de bordes dinámicos para efecto WhatsApp
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
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Máximo 75% de ancho
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: isLastInSequence ? 6 : 2, // Menos margen entre mensajes seguidos
            left: isMe ? 0 : 4,
            right: isMe ? 4 : 0,
          ),
          child: Material(
            elevation: 1,
            color: isMe ? const Color(0xFFE7FFDB) : Colors.white, // Colores WhatsApp
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Stack(
                children: [
                  // Texto con relleno a la derecha e inferior para la hora
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0, right: 20.0),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  // Hora y ticks posicionados en la esquina
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.read ? Colors.blue : Colors.grey[500],
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