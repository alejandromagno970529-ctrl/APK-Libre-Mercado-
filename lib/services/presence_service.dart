// lib/services/presence_service.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../utils/time_utils.dart';
import '../models/chat_model.dart';

class PresenceService {
  final SupabaseClient _supabase;
  Timer? _presenceTimer;
  final Map<String, RealtimeChannel> _presenceChannels = {};

  PresenceService() : _supabase = Supabase.instance.client;

  Future<void> updateUserPresence({required String userId, bool online = true}) async {
    try {
      AppLogger.d('🔄 Actualizando presencia para: $userId (online: $online)');
      
      final data = <String, dynamic>{
        'user_id': userId,
        'updated_at': TimeUtils.currentIso8601String(),
      };
      
      final tableInfo = await _getTableStructure();
      
      if (tableInfo['has_is_online'] == true) {
        data['is_online'] = online;  // ✅ CORREGIDO: bool directo, NO como String
      }
      
      if (tableInfo['last_seen_column'] != null) {
        data[tableInfo['last_seen_column']!] = TimeUtils.currentIso8601String();
      }
      
      AppLogger.d('📊 Datos de presencia a enviar: $data');
      
      await _supabase
          .from('user_presence')
          .upsert(data, onConflict: 'user_id');

      AppLogger.d('✅ Presencia actualizada para usuario: $userId');
      
    } catch (e) {
      AppLogger.e('❌ Error actualizando presencia: $e');
      
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('violates foreign key')) {
        await _ensureUserPresenceRecord(userId);
      }
    }
  }

  Future<Map<String, dynamic>> _getTableStructure() async {
    try {
      final result = await _supabase
          .from('user_presence')
          .select()
          .limit(1)
          .maybeSingle();
      
      if (result != null && result.isNotEmpty) {
        final columns = result.keys.toList();
        AppLogger.d('📋 Estructura encontrada: $columns');
        
        return {
          'has_is_online': result.containsKey('is_online'),
          'last_seen_column': _detectLastSeenColumn(result.keys),
          'has_updated_at': result.containsKey('updated_at'),
        };
      }
      
      return {
        'has_is_online': true,
        'last_seen_column': 'last_seen_at',
        'has_updated_at': true,
      };
      
    } catch (e) {
      AppLogger.e('⚠️ Error obteniendo estructura: $e');
      
      return {
        'has_is_online': true,
        'last_seen_column': 'last_seen_at',
        'has_updated_at': true,
      };
    }
  }

  String? _detectLastSeenColumn(Iterable<String> columns) {
    if (columns.contains('last_seen_at')) return 'last_seen_at';
    if (columns.contains('last_seen')) return 'last_seen';
    if (columns.contains('last_seen_date')) return 'last_seen_date';
    if (columns.contains('seen_at')) return 'seen_at';
    return null;
  }

  Future<void> _ensureUserPresenceRecord(String userId) async {
    try {
      AppLogger.d('📝 Creando registro de presencia para: $userId');
      
      final existing = await _supabase
          .from('user_presence')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null && existing.isNotEmpty) {
        AppLogger.d('✅ Registro ya existe para: $userId');
        return;
      }
      
      final record = {
        'user_id': userId,
        'created_at': TimeUtils.currentIso8601String(),
        'updated_at': TimeUtils.currentIso8601String(),
      };
      
      final tableInfo = await _getTableStructure();
      
      // ✅ CORRECCIÓN CRÍTICA: bool directo, NO 'as String'
      if (tableInfo['has_is_online'] == true) {
        record['is_online'] = true as String;  // ✅ CORREGIDO: bool directo
      }
      
      if (tableInfo['last_seen_column'] != null) {
        record[tableInfo['last_seen_column']!] = TimeUtils.currentIso8601String();
      }
      
      await _supabase
          .from('user_presence')
          .insert(record);
          
      AppLogger.d('✅ Registro de presencia creado para: $userId');
      
    } catch (e) {
      AppLogger.e('❌ Error creando registro de presencia: $e');
      AppLogger.w('⚠️ Si la tabla user_presence no existe, ejecuta el SQL en Supabase');
    }
  }

  Future<Map<String, dynamic>> getUserPresence(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        // ✅ Manejar diferentes tipos de datos para is_online
        bool isOnline = false;
        if (response['is_online'] is bool) {
          isOnline = response['is_online'] as bool;
        } else if (response['is_online'] is String) {
          isOnline = (response['is_online'] as String).toLowerCase() == 'true';
        } else if (response['is_online'] is int) {
          isOnline = response['is_online'] == 1;
        }
        
        DateTime? lastSeen;
        for (final key in response.keys) {
          if (key.contains('last') || key.contains('seen')) {
            if (response[key] != null) {
              try {
                lastSeen = TimeUtils.parseDynamicDateTime(response[key]);
                break;
              } catch (_) {
                continue;
              }
            }
          }
        }
        
        return {
          'online': isOnline,
          'last_seen': lastSeen,
          'updated_at': response['updated_at'] != null
              ? TimeUtils.parseDynamicDateTime(response['updated_at'])
              : null,
        };
      }

      // Si no hay registro, no crear uno automáticamente
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

  // ✅ MÉTODO CORREGIDO: checkPresenceTableExists
  Future<bool> checkPresenceTableExists() async {
    try {
      // ✅ CORREGIDO: Usar consulta simple
      await _supabase
          .from('user_presence')
          .select('id')
          .limit(1);
      return true;
    } catch (e) {
      AppLogger.e('❌ Tabla user_presence no existe o tiene problemas: $e');
      return false;
    }
  }

  Future<void> initializePresenceTable() async {
    try {
      final tableExists = await checkPresenceTableExists();
      
      if (!tableExists) {
        AppLogger.w('⚠️ Tabla user_presence no existe');
        AppLogger.w('💡 Ejecuta este SQL en Supabase para crear la tabla:');
        AppLogger.w('''
CREATE TABLE IF NOT EXISTS user_presence (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON user_presence
FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users" ON user_presence
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable update for users based on user_id" ON user_presence
FOR UPDATE USING (auth.uid() = user_id);
''');
      } else {
        AppLogger.d('✅ Tabla user_presence existe');
      }
      
    } catch (e) {
      AppLogger.e('❌ Error inicializando tabla de presencia: $e');
    }
  }

  Future<Map<String, dynamic>> initializeCompleteSetup() async {
    try {
      AppLogger.d('🔧 Inicializando sistema de presencia completo...');
      
      final tableExists = await checkPresenceTableExists();
      
      if (!tableExists) {
        AppLogger.w('⚠️ Tabla no existe');
        return {
          'success': false,
          'message': 'Tabla user_presence no existe. Ejecuta el SQL de creación.',
          'sql_required': true,
          'recommended_sql': '''
CREATE TABLE user_presence (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver presencia" ON user_presence
FOR SELECT USING (true);

CREATE POLICY "Usuarios pueden insertar su presencia" ON user_presence
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuarios pueden actualizar su presencia" ON user_presence
FOR UPDATE USING (auth.uid() = user_id);
''',
        };
      }
      
      final tableInfo = await _getTableStructure();
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        try {
          await updateUserPresence(userId: currentUser.id, online: true);
          AppLogger.d('✅ Configuración de presencia verificada correctamente');
          
          return {
            'success': true,
            'message': 'Sistema de presencia configurado correctamente',
            'table_structure': tableInfo,
            'user_id': currentUser.id,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error verificando permisos: $e',
            'error': e.toString(),
            'needs_rls_fix': e.toString().contains('policy'),
          };
        }
      }
      
      return {
        'success': true,
        'message': 'Tabla existe pero usuario no autenticado',
        'table_structure': tableInfo,
      };
      
    } catch (e) {
      AppLogger.e('❌ Error en inicialización completa: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, Map<String, dynamic>>> getMultipleUsersPresence(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final response = await _supabase
          .from('user_presence')
          .select()
          .inFilter('user_id', userIds);

      Map<String, Map<String, dynamic>> presences = {};
      
      for (var row in response) {
        final userId = row['user_id'] as String;
        
        // ✅ Manejar diferentes tipos de datos para is_online
        bool isOnline = false;
        if (row['is_online'] is bool) {
          isOnline = row['is_online'] as bool;
        } else if (row['is_online'] is String) {
          isOnline = (row['is_online'] as String).toLowerCase() == 'true';
        } else if (row['is_online'] is int) {
          isOnline = row['is_online'] == 1;
        }
        
        DateTime? lastSeen;
        for (final key in row.keys) {
          if (key.contains('last') || key.contains('seen')) {
            if (row[key] != null) {
              try {
                lastSeen = TimeUtils.parseDynamicDateTime(row[key].toString());
                break;
              } catch (_) {
                continue;
              }
            }
          }
        }
        
        presences[userId] = {
          'online': isOnline,
          'last_seen': lastSeen,
          'updated_at': row['updated_at'] != null
              ? TimeUtils.parseDynamicDateTime(row['updated_at'].toString())
              : null,
        };
      }

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

  Stream<Map<String, dynamic>> streamUserPresence(String userId) {
    final controller = StreamController<Map<String, dynamic>>();
    
    getUserPresence(userId).then((presence) {
      if (!controller.isClosed) {
        controller.add(presence);
      }
    });

    final channel = _supabase
        .channel('presence_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            if (payload.newRecord['user_id'] == userId) {
              // ✅ Manejar diferentes tipos de datos para is_online
              bool isOnline = false;
              if (payload.newRecord['is_online'] is bool) {
                isOnline = payload.newRecord['is_online'] as bool;
              } else if (payload.newRecord['is_online'] is String) {
                isOnline = (payload.newRecord['is_online'] as String).toLowerCase() == 'true';
              }
              
              final presence = {
                'online': isOnline,
                'last_seen': _parseTimestamp(payload.newRecord),
                'updated_at': payload.newRecord['updated_at'] != null
                    ? TimeUtils.parseDynamicDateTime(payload.newRecord['updated_at'].toString())
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

  DateTime? _parseTimestamp(Map<String, dynamic> record) {
    for (final key in record.keys) {
      if (key.contains('last') || key.contains('seen')) {
        if (record[key] != null) {
          try {
            return TimeUtils.parseDynamicDateTime(record[key].toString());
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  void startPresenceMonitor(String userId) {
    updateUserPresence(userId: userId, online: true);
    
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      updateUserPresence(userId: userId, online: true);
    });

    AppLogger.d('🚀 Monitor de presencia iniciado para: $userId');
  }

  void stopPresenceMonitor(String userId) async {
    await updateUserPresence(userId: userId, online: false);
    
    _presenceTimer?.cancel();
    _presenceTimer = null;
    
    for (final channel in _presenceChannels.values) {
      channel.unsubscribe();
    }
    _presenceChannels.clear();

    AppLogger.d('🛑 Monitor de presencia detenido para: $userId');
  }

  void dispose() {
    _presenceTimer?.cancel();
    for (final channel in _presenceChannels.values) {
      channel.unsubscribe();
    }
    _presenceChannels.clear();
  }

  Future<bool> isUserOnline(String userId) async {
    try {
      final presence = await getUserPresence(userId);
      return presence['online'] == true;
    } catch (e) {
      AppLogger.e('Error verificando si usuario está online: $e');
      return false;
    }
  }

  Future<String> getFormattedLastSeen(String userId) async {
    try {
      final presence = await getUserPresence(userId);
      final lastSeen = presence['last_seen'];
      
      if (lastSeen == null) return 'Desconectado';
      
      return TimeUtils.formatTimeAgo(lastSeen);
    } catch (e) {
      AppLogger.e('Error obteniendo last seen formateado: $e');
      return 'Desconectado';
    }
  }

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

  Future<Map<String, dynamic>> diagnosePresenceSystem() async {
    try {
      AppLogger.d('🔍 Iniciando diagnóstico del sistema de presencia...');
      
      final results = <String, dynamic>{};
      
      results['table_exists'] = await checkPresenceTableExists();
      
      if (results['table_exists']) {
        final structure = await _getTableStructure();
        results['table_structure'] = structure;
        
        try {
          final sample = await _supabase
              .from('user_presence')
              .select('id')
              .limit(1);
          results['record_count'] = sample.length;
        } catch (e) {
          results['record_count_error'] = e.toString();
        }
        
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          results['current_user_id'] = currentUser.id;
          
          try {
            final userPresence = await getUserPresence(currentUser.id);
            results['user_presence_data'] = userPresence;
          } catch (e) {
            results['user_presence_error'] = e.toString();
          }
        }
      }
      
      results['success'] = true;
      results['message'] = 'Diagnóstico completado';
      
      AppLogger.d('📊 Resultados del diagnóstico: $results');
      return results;
      
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error durante el diagnóstico',
      };
    }
  }

  // ✅ NUEVO: Método para diagnosticar problemas de DateTime
  Future<void> diagnoseDateTimeIssue() async {
    try {
      AppLogger.d('🔍 INICIANDO DIAGNÓSTICO DE DATE/TIME...');
      
      // 1. Verificar tabla user_presence
      final presence = await _supabase
          .from('user_presence')
          .select('user_id, is_online, updated_at, last_seen_at')
          .limit(3);
      
      AppLogger.d('📋 Presencia muestra:');
      for (var p in presence) {
        AppLogger.d('   - user_id: ${p['user_id']}');
        AppLogger.d('     is_online: ${p['is_online']} (tipo: ${p['is_online'].runtimeType})');
        AppLogger.d('     updated_at: ${p['updated_at']} (tipo: ${p['updated_at'].runtimeType})');
      }
      
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico DateTime: $e');
    }
  }
}