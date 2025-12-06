// lib/services/message_retry_service.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
// ignore: unused_import
import '../models/message_model.dart';
import '../utils/logger.dart';

/// Cola de mensajes pendientes de envío con sistema de reintentos
class MessageRetryService extends ChangeNotifier {
  // Cola FIFO para mensajes pendientes
  final Queue<PendingMessage> _messageQueue = Queue();
  
  // Mapa para tracking de mensajes por ID
  final Map<String, PendingMessage> _pendingMessages = {};
  
  // Timer para procesamiento periódico
  Timer? _processingTimer;
  
  // Estado del servicio
  bool _isProcessing = false;
  bool _isPaused = false;
  
  // Configuración
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(seconds: 30);
  static const Duration processingInterval = Duration(milliseconds: 500);

  MessageRetryService() {
    _startProcessing();
  }

  /// Agregar mensaje a la cola de reintentos
  void addMessage({
    required String messageId,
    required String chatId,
    required Function sendFunction,
    Map<String, dynamic>? metadata,
  }) {
    if (_pendingMessages.containsKey(messageId)) {
      AppLogger.d('⏳ Mensaje ya en cola: $messageId');
      return;
    }

    final pendingMessage = PendingMessage(
      messageId: messageId,
      chatId: chatId,
      sendFunction: sendFunction,
      metadata: metadata,
      addedAt: DateTime.now(),
    );

    _messageQueue.add(pendingMessage);
    _pendingMessages[messageId] = pendingMessage;
    
    AppLogger.d('➕ Mensaje agregado a cola: $messageId (Total: ${_messageQueue.length})');
    notifyListeners();
  }

  /// Remover mensaje de la cola
  void removeMessage(String messageId) {
    final message = _pendingMessages[messageId];
    if (message != null) {
      _messageQueue.remove(message);
      _pendingMessages.remove(messageId);
      AppLogger.d('➖ Mensaje removido de cola: $messageId');
      notifyListeners();
    }
  }

  /// Marcar mensaje como exitoso
  void markAsSuccess(String messageId) {
    removeMessage(messageId);
    AppLogger.d('✅ Mensaje enviado exitosamente: $messageId');
  }

  /// Iniciar procesamiento de la cola
  void _startProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(processingInterval, (_) {
      if (!_isPaused && !_isProcessing) {
        _processQueue();
      }
    });
  }

  /// Procesar cola de mensajes
  Future<void> _processQueue() async {
    if (_messageQueue.isEmpty || _isProcessing || _isPaused) return;

    _isProcessing = true;

    try {
      final message = _messageQueue.first;
      
      // Verificar si es momento de reintentar
      final nextRetryTime = _calculateNextRetryTime(message);
      if (DateTime.now().isBefore(nextRetryTime)) {
        _isProcessing = false;
        return;
      }

      // ignore: unnecessary_brace_in_string_interps
      AppLogger.d('🔄 Procesando mensaje: ${message.messageId} (Intento ${message.retryCount + 1}/${maxRetries})');

      try {
        // Ejecutar función de envío
        await message.sendFunction();
        
        // Si llega aquí, el envío fue exitoso
        markAsSuccess(message.messageId);
        AppLogger.d('✅ Mensaje procesado exitosamente: ${message.messageId}');
        
      } catch (e) {
        AppLogger.e('❌ Error procesando mensaje ${message.messageId}: $e');
        
        // Incrementar contador de reintentos
        message.retryCount++;
        message.lastRetryAt = DateTime.now();
        
        if (message.retryCount >= maxRetries) {
          // Máximo de reintentos alcanzado
          AppLogger.e('❌ Máximo de reintentos alcanzado para: ${message.messageId}');
          _handleFailedMessage(message, e);
          removeMessage(message.messageId);
        } else {
          // Mover al final de la cola para reintentar después
          _messageQueue.removeFirst();
          _messageQueue.add(message);
          
          final nextDelay = _calculateDelay(message.retryCount);
          AppLogger.d('⏰ Reintentando en ${nextDelay.inSeconds}s');
        }
      }
    } catch (e) {
      AppLogger.e('❌ Error crítico procesando cola: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Calcular delay con backoff exponencial
  Duration _calculateDelay(int retryCount) {
    final delaySeconds = initialDelay.inSeconds * (1 << retryCount); // 2^retryCount
    final clampedSeconds = delaySeconds.clamp(
      initialDelay.inSeconds,
      maxDelay.inSeconds,
    );
    return Duration(seconds: clampedSeconds);
  }

  /// Calcular próximo tiempo de reintento
  DateTime _calculateNextRetryTime(PendingMessage message) {
    if (message.lastRetryAt == null) {
      return message.addedAt;
    }
    
    final delay = _calculateDelay(message.retryCount);
    return message.lastRetryAt!.add(delay);
  }

  /// Manejar mensaje que falló definitivamente
  void _handleFailedMessage(PendingMessage message, dynamic error) {
    AppLogger.e('💥 Mensaje falló permanentemente: ${message.messageId}');
    // Aquí podrías guardar en una base de datos local
    // o notificar al usuario de alguna forma
    notifyListeners();
  }

  /// Pausar procesamiento de cola
  void pause() {
    _isPaused = true;
    AppLogger.d('⏸️ Cola de mensajes pausada');
  }

  /// Reanudar procesamiento de cola
  void resume() {
    _isPaused = false;
    AppLogger.d('▶️ Cola de mensajes reanudada');
  }

  /// Limpiar cola completa
  void clearQueue() {
    _messageQueue.clear();
    _pendingMessages.clear();
    AppLogger.d('🗑️ Cola de mensajes limpiada');
    notifyListeners();
  }

  /// Obtener estadísticas de la cola
  Map<String, dynamic> getStats() {
    return {
      'total_pending': _messageQueue.length,
      'is_processing': _isProcessing,
      'is_paused': _isPaused,
      'messages_by_retry': _getMessagesByRetryCount(),
    };
  }

  Map<int, int> _getMessagesByRetryCount() {
    final Map<int, int> stats = {0: 0, 1: 0, 2: 0, 3: 0};
    for (final message in _messageQueue) {
      stats[message.retryCount] = (stats[message.retryCount] ?? 0) + 1;
    }
    return stats;
  }

  /// Obtener mensajes pendientes para un chat específico
  List<PendingMessage> getPendingMessagesForChat(String chatId) {
    return _messageQueue
        .where((message) => message.chatId == chatId)
        .toList();
  }

  /// Verificar si un mensaje está pendiente
  bool isMessagePending(String messageId) {
    return _pendingMessages.containsKey(messageId);
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    clearQueue();
    super.dispose();
  }

  void initialize() {}
}

/// Clase para representar un mensaje pendiente
class PendingMessage {
  final String messageId;
  final String chatId;
  final Function sendFunction;
  final Map<String, dynamic>? metadata;
  final DateTime addedAt;
  
  int retryCount = 0;
  DateTime? lastRetryAt;

  PendingMessage({
    required this.messageId,
    required this.chatId,
    required this.sendFunction,
    this.metadata,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'retryCount': retryCount,
      'addedAt': addedAt.toIso8601String(),
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}