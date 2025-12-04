// lib/services/presence_service.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../models/chat_model.dart';

class PresenceService {
  final SupabaseClient _supabase;
  Timer? _presenceTimer;
  final Map<String, RealtimeChannel> _presenceChannels = {};

  PresenceService() : _supabase = Supabase.instance.client;

  // ✅ CORREGIDO: updateUserPresence adaptándose a tu esquema REAL
  Future<void> updateUserPresence({required String userId, bool online = true}) async {
    try {
      AppLogger.d('🔄 Actualizando presencia para: $userId (online: $online)');
      
      // Primero verificar qué columnas existen
      final tableInfo = await _getTableStructure();
      
      final data = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Verificar si existe la columna is_online
      if (tableInfo['has_is_online'] == true) {
        data['is_online'] = online;
      }
      
      // Verificar qué columna de timestamp usar
      if (tableInfo['last_seen_column'] != null) {
        data[tableInfo['last_seen_column']!] = DateTime.now().toIso8601String();
      }
      
      AppLogger.d('📊 Datos de presencia a enviar: $data');
      
      // Usar upsert con manejo de conflictos
      await _supabase
          .from('user_presence')
          .upsert(data, onConflict: 'user_id');

      AppLogger.d('✅ Presencia actualizada para usuario: $userId');
      
    } catch (e) {
      AppLogger.e('❌ Error actualizando presencia: $e');
      
      // Si hay error, intentar crear el registro primero
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('violates foreign key')) {
        await _ensureUserPresenceRecord(userId);
      }
    }
  }

  // ✅ Método para obtener estructura de la tabla
  Future<Map<String, dynamic>> _getTableStructure() async {
    try {
      // Intentar obtener un registro para ver columnas
      final result = await _supabase
          .from('user_presence')
          .select()
          .limit(1)
          .maybeSingle();
      
      if (result != null) {
        AppLogger.d('📋 Estructura encontrada: ${result.keys}');
        
        return {
          'has_is_online': result.containsKey('is_online'),
          'last_seen_column': _detectLastSeenColumn(result.keys),
          'has_updated_at': result.containsKey('updated_at'),
        };
      }
      
      // Si no hay registros, intentar con información de schema
      return {
        'has_is_online': true,
        'last_seen_column': 'last_seen_at',
        'has_updated_at': true,
      };
      
    } catch (e) {
      AppLogger.e('⚠️ Error obteniendo estructura: $e');
      
      // Suponer estructura por defecto basada en tus errores
      return {
        'has_is_online': true,
        'last_seen_column': 'last_seen_at', // Cambia esto según lo que veas en el SQL anterior
        'has_updated_at': true,
      };
    }
  }

  // ✅ Detectar qué columna usar para last_seen
  String? _detectLastSeenColumn(Iterable<String> columns) {
    if (columns.contains('last_seen_at')) return 'last_seen_at';
    if (columns.contains('last_seen')) return 'last_seen';
    if (columns.contains('last_seen_date')) return 'last_seen_date';
    if (columns.contains('seen_at')) return 'seen_at';
    return null;
  }

  // ✅ Crear registro de presencia si no existe
  Future<void> _ensureUserPresenceRecord(String userId) async {
    try {
      AppLogger.d('📝 Creando registro de presencia para: $userId');
      
      // Primero verificar si ya existe
      final existing = await _supabase
          .from('user_presence')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null) {
        AppLogger.d('✅ Registro ya existe para: $userId');
        return;
      }
      
      // Crear registro básico
      final record = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Agregar columnas opcionales si existen en la tabla
      final tableInfo = await _getTableStructure();
      if (tableInfo['has_is_online'] == true) {
        record['is_online'] = true as String;
      }
      
      if (tableInfo['last_seen_column'] != null) {
        record[tableInfo['last_seen_column']!] = DateTime.now().toIso8601String();
      }
      
      await _supabase
          .from('user_presence')
          .insert(record);
          
      AppLogger.d('✅ Registro de presencia creado para: $userId');
      
    } catch (e) {
      AppLogger.e('❌ Error creando registro de presencia: $e');
      await _createPresenceTableWithCurrentSchema();
    }
  }

  // ✅ Obtener presencia de un usuario
  Future<Map<String, dynamic>> getUserPresence(String userId) async {
    try {
      final response = await _supabase
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        // Manejar diferentes nombres de columnas
        final isOnline = response['is_online'] ?? false;
        
        // Buscar cualquier columna que pueda ser last_seen
        DateTime? lastSeen;
        for (final key in response.keys) {
          if (key.contains('last') || key.contains('seen')) {
            if (response[key] != null) {
              try {
                lastSeen = DateTime.parse(response[key]);
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
              ? DateTime.parse(response['updated_at'])
              : null,
        };
      }

      // Si no hay registro, crear uno por defecto
      await _ensureUserPresenceRecord(userId);
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

  // ✅ Verificar si la tabla existe
  Future<bool> checkPresenceTableExists() async {
    try {
      await _supabase
          .from('user_presence')
          .select('count(*)')
          .limit(1);
      return true;
    } catch (e) {
      AppLogger.e('❌ Tabla user_presence no existe o tiene problemas: $e');
      return false;
    }
  }

  // ✅ Inicializar tabla con el esquema CORRECTO
  Future<void> initializePresenceTable() async {
    try {
      final tableExists = await checkPresenceTableExists();
      
      if (!tableExists) {
        AppLogger.w('⚠️ Tabla user_presence no existe');
        
        // Primero verificar qué esquema se necesita
        await _checkAndCreateTable();
      } else {
        // Verificar estructura actual
        final tableInfo = await _getTableStructure();
        AppLogger.d('📊 Estructura actual de user_presence: $tableInfo');
        
        if (tableInfo['last_seen_column'] == null) {
          AppLogger.w('⚠️ Columna last_seen no encontrada, agregando...');
          await _addMissingColumns();
        }
      }
      
    } catch (e) {
      AppLogger.e('❌ Error inicializando tabla de presencia: $e');
    }
  }

  // ✅ Método para crear tabla basado en estructura actual
  Future<void> _createPresenceTableWithCurrentSchema() async {
    AppLogger.d('''
📋 CREA LA TABLA user_presence CON ESTE SQL (AJUSTA SEGÚN TUS NECESIDADES):

-- 1. Crear tabla básica (usa el nombre de columna que veas en el error)
CREATE TABLE IF NOT EXISTS user_presence (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),  -- o usa 'last_seen' si es lo que tienes
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 2. Habilitar RLS
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- 3. Políticas básicas (ajusta según necesidades)
CREATE POLICY "Users can view all presence" ON user_presence 
FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update own presence" ON user_presence 
FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own presence" ON user_presence 
FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- 4. Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_user_presence_user_id ON user_presence(user_id);
CREATE INDEX IF NOT EXISTS idx_user_presence_is_online ON user_presence(is_online);
CREATE INDEX IF NOT EXISTS idx_user_presence_updated_at ON user_presence(updated_at);
''');
  }

  // ✅ Verificar y crear tabla automáticamente
  Future<void> _checkAndCreateTable() async {
    try {
      // Primero ejecuta el SQL de verificación para ver qué tienes
      AppLogger.d('🔍 Ejecuta este SQL para ver tu estructura:');
      AppLogger.d('SELECT * FROM information_schema.columns WHERE table_name = \'user_presence\';');
      
      // Esperar a que el usuario revise
      AppLogger.w('⚠️ Por favor verifica la estructura de tu tabla primero');
      
    } catch (e) {
      AppLogger.e('❌ Error verificando tabla: $e');
    }
  }

  // ✅ Agregar columnas faltantes
  Future<void> _addMissingColumns() async {
    AppLogger.d('''
📋 AGREGAR COLUMNAS FALTANTES (ejecuta en Supabase SQL Editor):

-- Agregar columna is_online si no existe
ALTER TABLE user_presence 
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;

-- Agregar columna de timestamp (usa el nombre que necesites)
ALTER TABLE user_presence 
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT NOW();

-- O si prefieres last_seen sin _at:
-- ALTER TABLE user_presence 
-- ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE user_presence 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
''');
  }

  // ✅ INICIALIZAR CONFIGURACIÓN COMPLETA
  Future<Map<String, dynamic>> initializeCompleteSetup() async {
    try {
      AppLogger.d('🔧 Inicializando sistema de presencia completo...');
      
      // 1. Verificar tabla
      final tableExists = await checkPresenceTableExists();
      
      if (!tableExists) {
        AppLogger.w('⚠️ Tabla no existe, creando estructura recomendada...');
        return {
          'success': false,
          'message': 'Tabla user_presence no existe. Ejecuta el SQL de creación.',
          'sql_required': true,
          'recommended_sql': _getRecommendedTableSQL(),
        };
      }
      
      // 2. Verificar estructura
      final tableInfo = await _getTableStructure();
      
      if (tableInfo['last_seen_column'] == null) {
        AppLogger.w('⚠️ Columna last_seen no encontrada');
        return {
          'success': false,
          'message': 'Falta columna para timestamp. Ejecuta SQL para agregarla.',
          'sql_required': true,
          'missing_column': 'last_seen/timestamp column',
        };
      }
      
      // 3. Verificar RLS
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

  // ✅ Obtener SQL recomendado según errores
  String _getRecommendedTableSQL() {
    return '''
-- SQL RECOMENDADO PARA user_presence (BASADO EN TUS ERRORES)

-- 1. Eliminar tabla si existe (cuidado, esto borra datos)
-- DROP TABLE IF EXISTS user_presence;

-- 2. Crear tabla completa
CREATE TABLE user_presence (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),  -- ⚠️ ESTA ES LA COLUMNA QUE FALLA
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 3. RLS
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- 4. Políticas (mínimas)
CREATE POLICY "Enable read access for all users" ON user_presence
FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON user_presence
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable update for users based on user_id" ON user_presence
FOR UPDATE USING (auth.uid() = user_id);

-- 5. Índices
CREATE INDEX idx_user_presence_user_id ON user_presence(user_id);
CREATE INDEX idx_user_presence_last_seen ON user_presence(last_seen_at);
CREATE INDEX idx_user_presence_is_online ON user_presence(is_online);

-- 6. Insertar datos de usuarios existentes (opcional)
INSERT INTO user_presence (user_id, is_online, last_seen_at)
SELECT id, false, NOW() FROM auth.users
ON CONFLICT (user_id) DO NOTHING;
''';
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
        final userId = row['user_id'] as String;
        final isOnline = row['is_online'] ?? false;
        
        DateTime? lastSeen;
        for (final key in row.keys) {
          if (key.contains('last') || key.contains('seen')) {
            if (row[key] != null) {
              try {
                lastSeen = DateTime.parse(row[key].toString());
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
              ? DateTime.parse(row['updated_at'].toString())
              : null,
        };
      }

      // Para usuarios sin registro
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

  // ✅ Stream de presencia
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
              final presence = {
                'online': payload.newRecord['is_online'] ?? false,
                'last_seen': _parseTimestamp(payload.newRecord),
                'updated_at': payload.newRecord['updated_at'] != null
                    ? DateTime.parse(payload.newRecord['updated_at'].toString())
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

  // ✅ Parsear timestamp de cualquier columna
  DateTime? _parseTimestamp(Map<String, dynamic> record) {
    for (final key in record.keys) {
      if (key.contains('last') || key.contains('seen')) {
        if (record[key] != null) {
          try {
            return DateTime.parse(record[key].toString());
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  // ✅ Monitor de presencia
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

  // ✅ Limpieza
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

  // ✅ Obtener presencia para chats
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

  // ✅ DIAGNÓSTICO DEL SISTEMA
  Future<Map<String, dynamic>> diagnosePresenceSystem() async {
    try {
      AppLogger.d('🔍 Iniciando diagnóstico del sistema de presencia...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar tabla
      results['table_exists'] = await checkPresenceTableExists();
      
      // 2. Verificar estructura
      if (results['table_exists']) {
        final structure = await _getTableStructure();
        results['table_structure'] = structure;
        
        // 3. Verificar datos de ejemplo
        try {
          final sample = await _supabase
              .from('user_presence')
              .select('count(*)')
              .limit(1)
              .single();
          results['record_count'] = sample['count'];
        } catch (e) {
          results['record_count_error'] = e.toString();
        }
        
        // 4. Verificar usuario actual
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
}