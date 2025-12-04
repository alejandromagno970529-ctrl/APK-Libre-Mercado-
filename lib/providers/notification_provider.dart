// lib/providers/notification_provider.dart - COMPLETAMENTE CORREGIDO
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

class NotificationProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  late final NotificationService _notificationService;
  
  final List<AppNotification> _notifications = [];
  final Map<String, StreamSubscription> _subscriptions = {};
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  NotificationProvider(this._supabase) {
    _notificationService = NotificationService(_supabase);
  }
  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // ✅ INICIALIZAR SUSCRIPCIONES EN TIEMPO REAL
  Future<void> initialize(String userId) async {
    try {
      _setLoading(true);
      
      // Cargar notificaciones existentes
      await loadNotifications(userId);
      
      // Suscribirse a nuevas notificaciones
      _subscribeToNotifications(userId);
      
      // Suscribirse a presencia
      _subscribeToPresence(userId);
      
      AppLogger.d('✅ NotificationProvider inicializado para: $userId');
    } catch (e) {
      AppLogger.e('❌ Error inicializando NotificationProvider: $e', e);
      _setError('Error inicializando notificaciones: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // ✅ CARGAR NOTIFICACIONES
  Future<void> loadNotifications(String userId) async {
    try {
      final notifications = await _notificationService.getUserNotifications(userId);
      _notifications.clear();
      _notifications.addAll(AppNotification.fromList(notifications));
      
      // Calcular no leídas
      _unreadCount = _notifications.where((n) => !n.read).length;
      
      notifyListeners();
      AppLogger.d('📨 ${notifications.length} notificaciones cargadas');
    } catch (e) {
      AppLogger.e('❌ Error cargando notificaciones: $e', e);
      _setError('Error cargando notificaciones: $e');
    }
  }
  
  // ✅ SUSCRIBIRSE A NUEVAS NOTIFICACIONES EN TIEMPO REAL
  void _subscribeToNotifications(String userId) {
    try {
      _subscriptions['notifications']?.cancel();
      
      final subscription = _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .listen((event) {
            try {
              if (event.isNotEmpty) {
                final newNotifications = AppNotification.fromList(
                  List<Map<String, dynamic>>.from(event)
                );
                
                // Agregar nuevas notificaciones al inicio
                for (final notification in newNotifications) {
                  if (!_notifications.any((n) => n.id == notification.id)) {
                    _notifications.insert(0, notification);
                    
                    // Incrementar contador si no está leída
                    if (!notification.read) {
                      _unreadCount++;
                    }
                  }
                }
                
                notifyListeners();
                AppLogger.d('🔄 Notificación nueva recibida en tiempo real');
              }
            } catch (e) {
              AppLogger.e('❌ Error procesando notificación en tiempo real: $e');
            }
          }, onError: (error) {
            AppLogger.e('❌ Error en suscripción a notificaciones: $error');
          });
      
      _subscriptions['notifications'] = subscription;
      AppLogger.d('✅ Suscrito a notificaciones en tiempo real');
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a notificaciones: $e');
    }
  }
  
  // ✅ SUSCRIBIRSE A PRESENCIA
  void _subscribeToPresence(String userId) {
    try {
      _subscriptions['presence']?.cancel();
      
      // Suscribirse a cambios de presencia de usuarios relevantes
      final subscription = _supabase
          .from('user_presence')
          .stream(primaryKey: ['id'])
          .listen((event) {
            try {
              if (event.isNotEmpty) {
                AppLogger.d('🔄 Cambio de presencia detectado');
                // Aquí podrías notificar a las pantallas que muestren presencia
                // Por ejemplo: actualizar indicadores en chats activos
              }
            } catch (e) {
              AppLogger.e('❌ Error procesando presencia: $e');
            }
          });
      
      _subscriptions['presence'] = subscription;
      AppLogger.d('✅ Suscrito a presencia en tiempo real');
    } catch (e) {
      AppLogger.e('❌ Error suscribiendo a presencia: $e');
    }
  }
  
  // ✅ MARCAR NOTIFICACIÓN COMO LEÍDA
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? '';
      await _notificationService.markNotificationsAsRead(
        userId,
        notificationId: notificationId,
      );
      
      // Actualizar estado local
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        
        // Actualizar contador
        _unreadCount = _notifications.where((n) => !n.read).length;
        
        notifyListeners();
        AppLogger.d('✅ Notificación marcada como leída: $notificationId');
      }
    } catch (e) {
      AppLogger.e('❌ Error marcando notificación como leída: $e', e);
      _setError('Error marcando como leída: $e');
    }
  }
  
  // ✅ MARCAR TODAS COMO LEÍDAS
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      await _notificationService.markNotificationsAsRead(userId, notificationId: '');
      
      // Actualizar estado local
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
      
      _unreadCount = 0;
      notifyListeners();
      AppLogger.d('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      AppLogger.e('❌ Error marcando todas como leídas: $e', e);
      _setError('Error marcando todas: $e');
    }
  }
  
  // ✅ ENVIAR NOTIFICACIÓN INTERNA
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic> metadata = const {},
    String? chatId,
    String? productId,
  }) async {
    try {
      await _notificationService.sendInAppNotification(
        toUserId: userId,
        title: title,
        message: message,
        type: type,
        metadata: metadata,
        chatId: chatId,
        productId: productId,
      );
      
      AppLogger.d('📤 Notificación enviada a: $userId');
    } catch (e) {
      AppLogger.e('❌ Error enviando notificación: $e', e);
      _setError('Error enviando notificación: $e');
    }
  }
  
  // ✅ ELIMINAR NOTIFICACIÓN
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Eliminar localmente
      _notifications.removeWhere((n) => n.id == notificationId);
      
      // Recalcular no leídas
      _unreadCount = _notifications.where((n) => !n.read).length;
      
      notifyListeners();
      AppLogger.d('🗑️ Notificación eliminada: $notificationId');
    } catch (e) {
      AppLogger.e('❌ Error eliminando notificación: $e', e);
      _setError('Error eliminando: $e');
    }
  }
  
  // ✅ ELIMINAR TODAS
  Future<int> deleteAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;
      
      final count = await _notificationService.deleteAllUserNotifications(userId);
      
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
      
      AppLogger.d('🗑️ $count notificaciones eliminadas');
      return count;
    } catch (e) {
      AppLogger.e('❌ Error eliminando todas las notificaciones: $e', e);
      _setError('Error eliminando todas: $e');
      return 0;
    }
  }
  
  // ✅ OBTENER NOTIFICACIONES NO LEÍDAS
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.read).toList();
  }
  
  // ✅ OBTENER NOTIFICACIONES POR TIPO
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }
  
  // ✅ MÉTODO CORREGIDO: Actualizar presencia del usuario
  Future<void> updateUserPresence(String status) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final presenceData = {
        'user_id': userId,
        'status': status,
        'last_seen': DateTime.now().toIso8601String(),
        'metadata': {'device': 'mobile', 'updated_at': DateTime.now().toIso8601String()}
      };
      
      await _supabase
          .from('user_presence')
          .upsert(presenceData, onConflict: 'user_id');
      
      AppLogger.d('👤 Presencia actualizada: $status');
    } catch (e) {
      AppLogger.e('❌ Error actualizando presencia: $e');
      // No lanzar excepción, solo registrar el error
    }
  }
  
  // ✅ MÉTODO COMPLETAMENTE CORREGIDO: Obtener presencia de usuario
  Future<Map<String, dynamic>?> getUserPresence(String userId) async {
    // ✅ Primero, verificar que el usuario esté autenticado
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      AppLogger.w('⚠️ Usuario no autenticado al obtener presencia');
      return {
        'status': 'offline',
        'last_seen': null,
        'error': 'not_authenticated'
      };
    }

    try {
      AppLogger.d('🔍 Buscando presencia para usuario: $userId');
      
      // ✅ Usar maybeSingle() que maneja automáticamente el caso de no encontrar registro
      final response = await _supabase
          .from('user_presence')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) {
        AppLogger.d('📭 No hay registro de presencia para: $userId, usando offline por defecto');
        return {
          'status': 'offline',
          'last_seen': null,
          'metadata': {}
        };
      }

      AppLogger.d('✅ Presencia encontrada para $userId: ${response['status']}');
      
      return {
        'status': response['status'] ?? 'offline',
        'last_seen': response['last_seen'] != null
            ? DateTime.parse(response['last_seen'])
            : null,
        'metadata': response['metadata'] ?? {},
      };
      
    } on TimeoutException {
      AppLogger.w('⏰ Timeout al obtener presencia para $userId');
      return {
        'status': 'offline',
        'last_seen': null,
        'error': 'timeout'
      };
    } catch (e) {
      AppLogger.e('❌ Error obteniendo presencia: $e');
      return {
        'status': 'offline',
        'last_seen': null,
        'error': e.toString()
      };
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ignore: annotate_overrides
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    AppLogger.d('✅ NotificationProvider disposado');
    super.dispose();
  }
}