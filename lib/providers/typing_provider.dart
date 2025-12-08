// lib/providers/typing_provider.dart - VERSIÓN SIMPLIFICADA
import 'dart:async';
import 'package:flutter/foundation.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:supabase/src/supabase_client.dart';
import '../utils/logger.dart';

class TypingProvider with ChangeNotifier {
  // Mapa simple: chatId -> userId del que está escribiendo
  final Map<String, String> _typingUsers = {};
  final Map<String, Timer> _typingTimers = {};

  TypingProvider(SupabaseClient client);

  get typingUsers => null;

  // Obtener usuario que está escribiendo en un chat
  String? getTypingUser(String chatId) {
    return _typingUsers[chatId];
  }

  // Verificar si alguien está escribiendo en un chat
  bool isUserTyping(String chatId, String userId) {
    return _typingUsers[chatId] == userId;
  }

  // Establecer estado de typing
  void setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) {
    try {
      // Cancelar timer existente
      _typingTimers[chatId]?.cancel();
      _typingTimers.remove(chatId);

      if (isTyping) {
        // Configurar timer para auto-remover (3 segundos)
        _typingTimers[chatId] = Timer(const Duration(seconds: 3), () {
          _removeTypingStatus(chatId);
        });

        // Actualizar estado local
        _typingUsers[chatId] = userId;
        AppLogger.d('✍️ Usuario $userId está escribiendo en chat $chatId');
      } else {
        _removeTypingStatus(chatId);
      }

      notifyListeners();
    } catch (e) {
      AppLogger.e('❌ Error actualizando estado typing: $e');
    }
  }

  // Remover estado de typing
  void _removeTypingStatus(String chatId) {
    _typingUsers.remove(chatId);
    _typingTimers[chatId]?.cancel();
    _typingTimers.remove(chatId);
    notifyListeners();
    AppLogger.d('🗑️ Typing removido para chat $chatId');
  }

  // Para compatibilidad con chat_list_screen
  StreamSubscription<dynamic>? subscribeToTypingEvents(
    String chatId,
    Function(String?) callback,
  ) {
    // Versión simplificada - no usa streams reales
    return null;
  }

  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _typingUsers.clear();
    AppLogger.d('✅ TypingProvider disposado');
    super.dispose();
  }

  // ignore: body_might_complete_normally_nullable
  Object? getTypingUsers(String chatId) {}
}