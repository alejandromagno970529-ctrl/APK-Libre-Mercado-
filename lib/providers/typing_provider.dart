// CONTENIDO COMPLETO - Copiar y pegar en nuevo archivo
// lib/providers/typing_provider.dart - NUEVO
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class TypingProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  final Map<String, String?> _typingUsers = {}; // chatId -> userId
  final Map<String, Timer> _typingTimers = {};
  
  TypingProvider(this._supabase);
  
  Map<String, String?> get typingUsers => _typingUsers;
  
  // ✅ ACTUALIZAR ESTADO DE TYPING
  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      if (isTyping) {
        // Configurar timer para auto-remover (3 segundos)
        _typingTimers[chatId]?.cancel();
        _typingTimers[chatId] = Timer(const Duration(seconds: 3), () {
          _removeTypingStatus(chatId);
        });
        
        // Enviar a Supabase
        await _supabase
            .from('typing_events')
            .upsert({
              'chat_id': chatId,
              'user_id': userId,
              'is_typing': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
        
        // Actualizar estado local
        _typingUsers[chatId] = userId;
        notifyListeners();
        
        AppLogger.d('✍️ Usuario $userId está escribiendo en chat $chatId');
      } else {
        _removeTypingStatus(chatId);
      }
    } catch (e) {
      AppLogger.e('❌ Error actualizando estado typing: $e');
    }
  }
  
  // ✅ REMOVER ESTADO DE TYPING
  void _removeTypingStatus(String chatId) async {
    try {
      final userId = _typingUsers[chatId];
      if (userId != null) {
        await _supabase
            .from('typing_events')
            .delete()
            .eq('chat_id', chatId)
            .eq('user_id', userId);
      }
      
      _typingUsers.remove(chatId);
      _typingTimers[chatId]?.cancel();
      _typingTimers.remove(chatId);
      
      notifyListeners();
      AppLogger.d('🗑️ Typing removido para chat $chatId');
    } catch (e) {
      AppLogger.e('❌ Error removiendo typing status: $e');
    }
  }
  
  // ✅ SUSCRIBIRSE A TYPING EVENTS DE UN CHAT
  StreamSubscription? subscribeToTypingEvents(String chatId, Function(String?) callback) {
    try {
      return _supabase
          .from('typing_events')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .listen((event) {
            try {
              if (event.isNotEmpty) {
                final typingEvent = event.first;
                final userId = typingEvent['user_id'] as String?;
                final isTyping = typingEvent['is_typing'] as bool? ?? false;
                
                if (isTyping) {
                  _typingUsers[chatId] = userId;
                  // ignore: unnecessary_null_comparison
                  if (callback != null) callback(userId);
                } else {
                  _typingUsers.remove(chatId);
                  // ignore: unnecessary_null_comparison
                  if (callback != null) callback(null);
                }
                
                AppLogger.d('🔄 Typing event recibido para chat $chatId: $userId - $isTyping');
              }
            } catch (e) {
              AppLogger.e('❌ Error procesando typing event: $e');
            }
          }, onError: (error) {
            AppLogger.e('❌ Error en suscripción typing: $error');
          });
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a typing events: $e');
      return null;
    }
  }
  
  // ✅ OBTENER QUIÉN ESTÁ ESCRIBIENDO EN UN CHAT
  String? getTypingUser(String chatId) {
    return _typingUsers[chatId];
  }
  
  // ✅ LIMPIAR TODOS LOS TIMERS
  // ignore: must_call_super, annotate_overrides
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _typingUsers.clear();
    AppLogger.d('✅ TypingProvider disposado');
  }
}