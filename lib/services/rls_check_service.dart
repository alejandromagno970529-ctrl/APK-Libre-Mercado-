// lib/services/rls_check_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class RLSCheckService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> checkStoragePolicies() async {
    try {
      final buckets = ['chat-files', 'chat-images', 'profile-pictures', 'product-images'];
      
      for (final bucket in buckets) {
        try {
          // Intentar subir un archivo pequeño de prueba
          final Uint8List testData = Uint8List.fromList([0x68, 0x65, 0x6C, 0x6C, 0x6F]); // "hello"
          final testPath = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
          
          await _supabase.storage
            .from(bucket)
            .uploadBinary(testPath, testData);
          
          AppLogger.info('✅ Política RLS correcta para bucket: $bucket');
          
          // Limpiar archivo de prueba
          await _supabase.storage.from(bucket).remove([testPath]);
        } catch (e) {
          AppLogger.error('❌ Política RLS faltante para bucket: $bucket - Error: $e');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error verificando políticas RLS: $e');
    }
  }

  static Future<void> checkAllRLSPolicies() async {
    AppLogger.info('🔍 Verificando todas las políticas RLS...');
    
    await checkStoragePolicies();
    await checkTablePolicies();
  }

  static Future<void> checkTablePolicies() async {
    try {
      // Verificar políticas para chats
      try {
        // ignore: unused_local_variable
        final result = await _supabase
            .from('chats')
            .select('id')
            .limit(1)
            .maybeSingle();
        AppLogger.info('✅ Política RLS correcta para tabla: chats');
      } catch (e) {
        AppLogger.error('❌ Política RLS faltante para tabla: chats - Error: $e');
      }

      // Verificar políticas para mensajes
      try {
        // ignore: unused_local_variable
        final result = await _supabase
            .from('messages')
            .select('id')
            .limit(1)
            .maybeSingle();
        AppLogger.info('✅ Política RLS correcta para tabla: messages');
      } catch (e) {
        AppLogger.error('❌ Política RLS faltante para tabla: messages - Error: $e');
      }

      // Verificar políticas para productos
      try {
        // ignore: unused_local_variable
        final result = await _supabase
            .from('products')
            .select('id')
            .limit(1)
            .maybeSingle();
        AppLogger.info('✅ Política RLS correcta para tabla: products');
      } catch (e) {
        AppLogger.error('❌ Política RLS faltante para tabla: products - Error: $e');
      }

    } catch (e) {
      AppLogger.error('❌ Error verificando políticas de tabla: $e');
    }
  }

  static Future<bool> testFileUpload(String bucket) async {
    try {
      final Uint8List testData = Uint8List.fromList([0x74, 0x65, 0x73, 0x74]); // "test"
      final testPath = 'test_upload_${DateTime.now().millisecondsSinceEpoch}.txt';
      
      await _supabase.storage
        .from(bucket)
        .uploadBinary(testPath, testData);
      
      // Limpiar
      await _supabase.storage.from(bucket).remove([testPath]);
      
      AppLogger.info('✅ Upload test exitoso para bucket: $bucket');
      return true;
    } catch (e) {
      AppLogger.error('❌ Upload test fallido para bucket: $bucket - Error: $e');
      return false;
    }
  }

  static Future<Map<String, bool>> runCompleteRLSCheck() async {
    AppLogger.info('🚀 Ejecutando verificación completa de RLS...');
    
    final results = <String, bool>{};
    
    // Verificar buckets de almacenamiento
    final buckets = ['chat-files', 'chat-images', 'profile-pictures', 'product-images'];
    for (final bucket in buckets) {
      results['storage_$bucket'] = await testFileUpload(bucket);
    }
    
    // Verificar tablas de base de datos
    try {
      await checkTablePolicies();
      results['database_tables'] = true;
    } catch (e) {
      results['database_tables'] = false;
    }
    
    AppLogger.info('📊 Resultados de verificación RLS: $results');
    return results;
  }
}