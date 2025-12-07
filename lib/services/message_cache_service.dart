// lib/services/message_cache_service.dart - VERSIÓN COMPLETA CORREGIDA
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../utils/logger.dart';

/// Servicio de caché local para mensajes y chats
class MessageCacheService {
  static const String _messageCachePrefix = 'cached_messages_';
  static const String _chatCachePrefix = 'cached_chats_';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const int maxCachedMessages = 100; // Por chat
  static const int cacheExpirationDays = 7;

  final SharedPreferences _prefs;

  MessageCacheService(this._prefs);

  /// Factory para inicializar el servicio
  static Future<MessageCacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MessageCacheService(prefs);
  }

  // ========== MENSAJES ==========

  /// Guardar mensajes en caché
  Future<void> cacheMessages(String chatId, List<Message> messages) async {
    try {
      // Limitar cantidad de mensajes en caché
      final messagesToCache = messages.take(maxCachedMessages).toList();
      
      final cacheData = {
        'messages': messagesToCache.map((m) => m.toMap()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
        'count': messagesToCache.length,
      };

      final key = '$_messageCachePrefix$chatId';
      final jsonString = json.encode(cacheData);
      
      await _prefs.setString(key, jsonString);
      AppLogger.d('✅ Cached ${messagesToCache.length} messages for chat: $chatId');
      
    } catch (e) {
      AppLogger.e('❌ Error caching messages: $e');
    }
  }

  /// Obtener mensajes desde caché
  Future<List<Message>> getCachedMessages(String chatId) async {
    try {
      final key = '$_messageCachePrefix$chatId';
      final jsonString = _prefs.getString(key);
      
      if (jsonString == null) {
        AppLogger.d('📭 No cached messages for chat: $chatId');
        return [];
      }

      final cacheData = json.decode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at'] as String);
      
      // Verificar expiración
      final isExpired = DateTime.now().difference(cachedAt).inDays > cacheExpirationDays;
      if (isExpired) {
        AppLogger.d('⏰ Cache expired for chat: $chatId');
        await clearChatCache(chatId);
        return [];
      }

      final messagesList = cacheData['messages'] as List;
      final messages = messagesList
          .map((m) => Message.fromMap(m as Map<String, dynamic>))
          .toList();
      
      AppLogger.d('✅ Retrieved ${messages.length} cached messages for chat: $chatId');
      return messages;
      
    } catch (e) {
      AppLogger.e('❌ Error getting cached messages: $e');
      return [];
    }
  }

  /// Agregar un mensaje individual al caché
  Future<void> addMessageToCache(String chatId, Message message) async {
    try {
      final cachedMessages = await getCachedMessages(chatId);
      
      // Verificar si ya existe
      final exists = cachedMessages.any((m) => m.id == message.id);
      if (exists) {
        AppLogger.d('⏭️ Message already in cache: ${message.id}');
        return;
      }

      // Agregar al inicio (más reciente)
      cachedMessages.insert(0, message);
      
      // Mantener solo los últimos N mensajes
      final limitedMessages = cachedMessages.take(maxCachedMessages).toList();
      
      await cacheMessages(chatId, limitedMessages);
      
    } catch (e) {
      AppLogger.e('❌ Error adding message to cache: $e');
    }
  }

  /// Actualizar un mensaje en caché
  Future<void> updateMessageInCache(String chatId, Message updatedMessage) async {
    try {
      final cachedMessages = await getCachedMessages(chatId);
      
      final index = cachedMessages.indexWhere((m) => m.id == updatedMessage.id);
      if (index != -1) {
        cachedMessages[index] = updatedMessage;
        await cacheMessages(chatId, cachedMessages);
        AppLogger.d('✅ Message updated in cache: ${updatedMessage.id}');
      }
      
    } catch (e) {
      AppLogger.e('❌ Error updating message in cache: $e');
    }
  }

  /// Eliminar un mensaje del caché
  Future<void> deleteMessageFromCache(String chatId, String messageId) async {
    try {
      final cachedMessages = await getCachedMessages(chatId);
      cachedMessages.removeWhere((m) => m.id == messageId);
      await cacheMessages(chatId, cachedMessages);
      AppLogger.d('✅ Message deleted from cache: $messageId');
      
    } catch (e) {
      AppLogger.e('❌ Error deleting message from cache: $e');
    }
  }

  /// Limpiar caché de un chat específico
  Future<void> clearChatCache(String chatId) async {
    try {
      final messageKey = '$_messageCachePrefix$chatId';
      await _prefs.remove(messageKey);
      AppLogger.d('🗑️ Cache cleared for chat: $chatId');
      
    } catch (e) {
      AppLogger.e('❌ Error clearing chat cache: $e');
    }
  }

  // ========== CHATS ==========

  /// Guardar lista de chats en caché
  Future<void> cacheChats(List<Chat> chats) async {
    try {
      final cacheData = {
        'chats': chats.map((c) => c.toMap()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
        'count': chats.length,
      };

      final jsonString = json.encode(cacheData);
      await _prefs.setString(_chatCachePrefix, jsonString);
      
      AppLogger.d('✅ Cached ${chats.length} chats');
      
    } catch (e) {
      AppLogger.e('❌ Error caching chats: $e');
    }
  }

  /// Obtener chats desde caché
  Future<List<Chat>> getCachedChats() async {
    try {
      final jsonString = _prefs.getString(_chatCachePrefix);
      
      if (jsonString == null) {
        AppLogger.d('📭 No cached chats');
        return [];
      }

      final cacheData = json.decode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at'] as String);
      
      // Verificar expiración
      final isExpired = DateTime.now().difference(cachedAt).inDays > cacheExpirationDays;
      if (isExpired) {
        AppLogger.d('⏰ Chats cache expired');
        await clearChatsCache();
        return [];
      }

      final chatsList = cacheData['chats'] as List;
      final chats = chatsList
          .map((c) => Chat.fromMap(c as Map<String, dynamic>))
          .toList();
      
      AppLogger.d('✅ Retrieved ${chats.length} cached chats');
      return chats;
      
    } catch (e) {
      AppLogger.e('❌ Error getting cached chats: $e');
      return [];
    }
  }

  /// Limpiar caché de chats
  Future<void> clearChatsCache() async {
    try {
      await _prefs.remove(_chatCachePrefix);
      AppLogger.d('🗑️ Chats cache cleared');
      
    } catch (e) {
      AppLogger.e('❌ Error clearing chats cache: $e');
    }
  }

  // ========== SINCRONIZACIÓN ==========

  /// Guardar timestamp de última sincronización
  Future<void> saveLastSyncTime() async {
    try {
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      AppLogger.d('✅ Last sync time saved');
      
    } catch (e) {
      AppLogger.e('❌ Error saving last sync time: $e');
    }
  }

  /// Obtener timestamp de última sincronización
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timeString = _prefs.getString(_lastSyncKey);
      if (timeString == null) return null;
      
      return DateTime.parse(timeString);
      
    } catch (e) {
      AppLogger.e('❌ Error getting last sync time: $e');
      return null;
    }
  }

  /// Verificar si necesita sincronizar
  Future<bool> needsSync({Duration threshold = const Duration(minutes: 5)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    final difference = DateTime.now().difference(lastSync);
    return difference > threshold;
  }

  // ========== LIMPIEZA Y MANTENIMIENTO ==========

  /// Limpiar todo el caché
  Future<void> clearAllCache() async {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_messageCachePrefix) || 
        key.startsWith(_chatCachePrefix)
      ).toList();
      
      for (final key in cacheKeys) {
        await _prefs.remove(key);
      }
      
      await _prefs.remove(_lastSyncKey);
      
      AppLogger.d('🗑️ All cache cleared (${cacheKeys.length} entries)');
      
    } catch (e) {
      AppLogger.e('❌ Error clearing all cache: $e');
    }
  }

  /// Limpiar caché expirado
  Future<void> cleanExpiredCache() async {
    try {
      final keys = _prefs.getKeys();
      final messageCacheKeys = keys.where((key) => 
        key.startsWith(_messageCachePrefix)
      ).toList();
      
      int cleaned = 0;
      
      for (final key in messageCacheKeys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final cacheData = json.decode(jsonString) as Map<String, dynamic>;
            final cachedAt = DateTime.parse(cacheData['cached_at'] as String);
            
            final isExpired = DateTime.now().difference(cachedAt).inDays > cacheExpirationDays;
            if (isExpired) {
              await _prefs.remove(key);
              cleaned++;
            }
          } catch (e) {
            // Si hay error al parsear, eliminar el caché corrupto
            await _prefs.remove(key);
            cleaned++;
          }
        }
      }
      
      AppLogger.d('🧹 Cleaned $cleaned expired cache entries');
      
    } catch (e) {
      AppLogger.e('❌ Error cleaning expired cache: $e');
    }
  }

  /// Obtener tamaño del caché en bytes (aproximado)
  Future<int> getCacheSize() async {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_messageCachePrefix) || 
        key.startsWith(_chatCachePrefix)
      ).toList();
      
      int totalSize = 0;
      
      for (final key in cacheKeys) {
        final value = _prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
      
      return totalSize;
      
    } catch (e) {
      AppLogger.e('❌ Error getting cache size: $e');
      return 0;
    }
  }

  // ✅ MÉTODO CORREGIDO: getStats debe devolver Map<String, dynamic>
  Future<Map<String, dynamic>> getStats() async {
    try {
      final keys = _prefs.getKeys();
      final messageCacheKeys = keys.where((key) => 
        key.startsWith(_messageCachePrefix)
      ).toList();
      final chatCacheKeys = keys.where((key) => 
        key.startsWith(_chatCachePrefix)
      ).toList();
      
      final size = await getCacheSize();
      final lastSync = await getLastSyncTime();
      
      return {
        'total_message_caches': messageCacheKeys.length,
        'total_chat_caches': chatCacheKeys.length,
        'total_size_bytes': size,
        'total_size_kb': (size / 1024).toStringAsFixed(2),
        'last_sync': lastSync?.toIso8601String(),
        'needs_sync': await needsSync(),
      };
      
    } catch (e) {
      AppLogger.e('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  // ========== BÚSQUEDA EN CACHÉ ==========

  /// Buscar mensajes en caché local
  Future<List<Message>> searchInCache(String chatId, String query) async {
    try {
      final cachedMessages = await getCachedMessages(chatId);
      
      final results = cachedMessages.where((message) {
        final text = message.text.toLowerCase();
        final searchQuery = query.toLowerCase();
        return text.contains(searchQuery);
      }).toList();
      
      AppLogger.d('🔍 Found ${results.length} messages matching "$query" in cache');
      return results;
      
    } catch (e) {
      AppLogger.e('❌ Error searching in cache: $e');
      return [];
    }
  }

  /// Obtener mensajes no leídos desde caché
  Future<List<Message>> getUnreadMessagesFromCache(String chatId, String userId) async {
    try {
      final cachedMessages = await getCachedMessages(chatId);
      
      final unread = cachedMessages.where((message) {
        return message.fromId != userId && !message.read;
      }).toList();
      
      AppLogger.d('📬 Found ${unread.length} unread messages in cache');
      return unread;
      
    } catch (e) {
      AppLogger.e('❌ Error getting unread from cache: $e');
      return [];
    }
  }
}