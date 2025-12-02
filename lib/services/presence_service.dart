// lib/services/presence_service.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../models/chat_model.dart';

class PresenceService {
  final SupabaseClient _supabase;
  Timer? _presenceTimer;
  // ignore: prefer_final_fields
  Map<String, RealtimeChannel> _presenceChannels = {};

  PresenceService() : _supabase = Supabase.instance.client;

  // ✅ Actualizar presencia del usuario actual
  Future<void> updateUserPresence({required String userId, bool online = true}) async {
    try {
      await _supabase
          .from('user_presence')
          .upsert({
            'user_id': userId,
            'is_online': online,
            'last_seen_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      AppLogger.d('✅ Presencia actualizada para usuario: $userId (online: $online)');
    } catch (e) {
      AppLogger.e('Error actualizando presencia: $e');
    }
  }

  // ✅ Obtener presencia de un usuario - CORREGIDO: usar maybeSingle() en lugar de catchError
  Future<Map<String, dynamic>> getUserPresence(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // ✅ CORRECCIÓN: maybeSingle en lugar de single().catchError

      if (response != null) {
        return {
          'online': response['is_online'] ?? false,
          'last_seen': response['last_seen_at'] != null
              ? DateTime.parse(response['last_seen_at'])
              : null,
          'updated_at': response['updated_at'] != null
              ? DateTime.parse(response['updated_at'])
              : null,
        };
      }

      // Si no hay registro, crear uno por defecto
      return {
        'online': false,
        'last_seen': null,
        'updated_at': null,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo presencia: $e');
      return {
        'online': false,
        'last_seen': null,
        'updated_at': null,
      };
    }
  }

  // ✅ Obtener presencia de múltiples usuarios
  Future<Map<String, Map<String, dynamic>>> getMultipleUsersPresence(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final response = await _supabase
          .from('user_presence')
          .select()
          .inFilter('user_id', userIds);

      Map<String, Map<String, dynamic>> presences = {};
      for (var row in response) {
        presences[row['user_id']] = {
          'online': row['is_online'] ?? false,
          'last_seen': row['last_seen_at'] != null
              ? DateTime.parse(row['last_seen_at'])
              : null,
          'updated_at': row['updated_at'] != null
              ? DateTime.parse(row['updated_at'])
              : null,
        };
      }

      // Para los usuarios que no tienen registro, devolver valores por defecto
      for (var userId in userIds) {
        if (!presences.containsKey(userId)) {
          presences[userId] = {
            'online': false,
            'last_seen': null,
            'updated_at': null,
          };
        }
      }

      return presences;
    } catch (e) {
      AppLogger.e('Error obteniendo presencia múltiple: $e');
      return {};
    }
  }

  // ✅ Stream de presencia de un usuario
  Stream<Map<String, dynamic>> streamUserPresence(String userId) {
    final controller = StreamController<Map<String, dynamic>>();
    
    // Enviar estado inicial
    getUserPresence(userId).then((presence) {
      if (!controller.isClosed) {
        controller.add(presence);
      }
    });

    // Suscribirse a cambios en tiempo real usando RealtimeChannel
    final channel = _supabase
        .channel('presence_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            if (payload.newRecord['user_id'] == userId) {
              final presence = {
                'online': payload.newRecord['is_online'] ?? false,
                'last_seen': payload.newRecord['last_seen_at'] != null
                    ? DateTime.parse(payload.newRecord['last_seen_at'])
                    : null,
                'updated_at': payload.newRecord['updated_at'] != null
                    ? DateTime.parse(payload.newRecord['updated_at'])
                    : null,
              };
              controller.add(presence);
            }
          },
        )
        .subscribe();

    _presenceChannels[userId] = channel;

    controller.onCancel = () {
      channel.unsubscribe();
      _presenceChannels.remove(userId);
    };

    return controller.stream;
  }

  // ✅ Iniciar monitor de presencia (llamar cuando el usuario inicie sesión)
  void startPresenceMonitor(String userId) {
    // Actualizar como online
    updateUserPresence(userId: userId, online: true);
    
    // Configurar heartbeat cada 30 segundos
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      updateUserPresence(userId: userId, online: true);
    });

    AppLogger.d('🚀 Monitor de presencia iniciado para: $userId');
  }

  // ✅ Detener monitor de presencia (llamar cuando el usuario cierre sesión)
  void stopPresenceMonitor(String userId) async {
    // Marcar como offline
    await updateUserPresence(userId: userId, online: false);
    
    // Cancelar timer
    _presenceTimer?.cancel();
    _presenceTimer = null;
    
    // Cancelar todas las suscripciones
    for (final channel in _presenceChannels.values) {
      channel.unsubscribe();
    }
    _presenceChannels.clear();

    AppLogger.d('🛑 Monitor de presencia detenido para: $userId');
  }

  // ✅ Método de limpieza
  void dispose() {
    _presenceTimer?.cancel();
    for (final channel in _presenceChannels.values) {
      channel.unsubscribe();
    }
    _presenceChannels.clear();
  }

  // ✅ Verificar si usuario está online
  Future<bool> isUserOnline(String userId) async {
    try {
      final presence = await getUserPresence(userId);
      return presence['online'] == true;
    } catch (e) {
      AppLogger.e('Error verificando si usuario está online: $e');
      return false;
    }
  }

  // ✅ Obtener última vez visto formateada
  Future<String> getFormattedLastSeen(String userId) async {
    try {
      final presence = await getUserPresence(userId);
      final lastSeen = presence['last_seen'];
      
      if (lastSeen == null) return 'Desconectado';
      
      final now = DateTime.now();
      final difference = now.difference(lastSeen);
      
      if (difference.inMinutes < 1) return 'En línea';
      if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
      if (difference.inDays < 7) return 'Hace ${difference.inDays} d';
      
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    } catch (e) {
      AppLogger.e('Error obteniendo last seen formateado: $e');
      return 'Desconectado';
    }
  }

  // ✅ Método MEJORADO: Obtener presencia optimizada para chat_list_screen
  Future<Map<String, Map<String, dynamic>>> getChatUsersPresence(List<Chat> chats, String currentUserId) async {
    try {
      final userIds = <String>[];
      
      for (final chat in chats) {
        final otherUserId = chat.getOtherUserId(currentUserId);
        // ignore: unnecessary_null_comparison
        if (otherUserId != null && !userIds.contains(otherUserId)) {
          userIds.add(otherUserId);
        }
      }
      
      if (userIds.isEmpty) return {};
      
      return await getMultipleUsersPresence(userIds);
    } catch (e) {
      AppLogger.e('Error obteniendo presencia de chats: $e');
      return {};
    }
  }

  // ✅ NUEVO MÉTODO: Crear registro de presencia si no existe
  Future<void> ensurePresenceRecord(String userId) async {
    try {
      final existing = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase
            .from('user_presence')
            .insert({
              'user_id': userId,
              'is_online': false,
              'last_seen_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        
        AppLogger.d('✅ Registro de presencia creado para: $userId');
      }
    } catch (e) {
      AppLogger.e('Error asegurando registro de presencia: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Verificar si tabla existe
  Future<bool> checkPresenceTableExists() async {
    try {
      await _supabase
          .from('user_presence')
          .select('count(*)')
          .limit(1);
      return true;
    } catch (e) {
      AppLogger.e('Tabla user_presence no existe: $e');
      return false;
    }
  }

  // ✅ NUEVO MÉTODO: Inicializar tabla si no existe
  Future<void> initializePresenceTable() async {
    try {
      final tableExists = await checkPresenceTableExists();
      if (!tableExists) {
        AppLogger.w('⚠️ Tabla user_presence no existe, creándola...');
        await _createPresenceTable();
      }
    } catch (e) {
      AppLogger.e('Error inicializando tabla de presencia: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Crear tabla (para SQL manual)
  Future<void> _createPresenceTable() async {
    AppLogger.d('''
📋 CREA LA TABLA user_presence MANUALMENTE EN SUPABASE SQL EDITOR:

Ejecuta estos comandos SQL:

-- 1. Crear tabla
CREATE TABLE IF NOT EXISTS user_presence (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 2. Habilitar RLS
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- 3. Políticas RLS
CREATE POLICY "Users can view all presence" ON user_presence FOR SELECT USING (true);
CREATE POLICY "Users can update own presence" ON user_presence FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own presence" ON user_presence FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Índices
CREATE INDEX idx_user_presence_user_id ON user_presence(user_id);
CREATE INDEX idx_user_presence_is_online ON user_presence(is_online);
''');
  }
}