import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

class DiagnosticService {
  final SupabaseClient _supabase;

  DiagnosticService(this._supabase);

  Future<Map<String, dynamic>> comprehensiveDiagnostic() async {
    AppLogger.d('🩺 INICIANDO DIAGNÓSTICO COMPLETO DEL SISTEMA');
    AppLogger.d('=' * 60);

    final Map<String, dynamic> results = {
      'success': false,
      'steps': <String, dynamic>{},
      'bucket_names': <String>[],
      'missing_buckets': <String>[],
      'errors': <String>[],
      'recommendations': <String>[]
    };

    try {
      // 1. LISTAR TODOS LOS BUCKETS DISPONIBLES
      results['steps']['1_list_buckets'] = await _listAllBuckets();
      results['bucket_names'] = results['steps']['1_list_buckets']['bucket_names'] ?? [];
      results['missing_buckets'] = results['steps']['1_list_buckets']['missing_buckets'] ?? [];

      // 2. VERIFICAR BUCKET ESPECÍFICO
      final List<dynamic> availableBuckets = results['bucket_names'];
      if (availableBuckets.contains('product-images')) {
        results['steps']['2_product_images_bucket'] = await _checkSpecificBucket('product-images');
      } else {
        results['errors'].add('No se encontró el bucket "product-images"');
        results['recommendations'].add('Crea un bucket llamado "product-images" en Supabase Storage');
        
        // Verificar si hay buckets alternativos
        if (availableBuckets.isNotEmpty) {
          results['recommendations'].add('Buckets disponibles: ${availableBuckets.join(', ')}');
        }
      }

      // 3. VERIFICAR AUTENTICACIÓN
      results['steps']['3_auth'] = await _checkAuthentication();

      // 4. VERIFICAR POLÍTICAS (solo si el bucket existe)
      if (results['steps']['2_product_images_bucket'] != null && 
          results['steps']['2_product_images_bucket']['success'] == true) {
        final bucketName = results['steps']['2_product_images_bucket']['bucket_name'];
        results['steps']['4_policies'] = await _checkPolicies(bucketName);
      }

      // 5. PRUEBA REAL DE SUBIDA
      results['steps']['5_upload_test'] = await _testActualUpload();

    } catch (e) {
      results['errors'].add('Error en diagnóstico: $e');
    }

    return _compileFinalResults(results);
  }

  Future<Map<String, dynamic>> _listAllBuckets() async {
    try {
      AppLogger.d('1. 📦 LISTANDO TODOS LOS BUCKETS DISPONIBLES...');
      final buckets = await _supabase.storage.listBuckets();
      
      final bucketNames = buckets.map((b) => b.name).toList();
      AppLogger.d('   📋 Buckets encontrados: $bucketNames');
      
      // ✅ VERIFICAR BUCKETS ESPERADOS
      final expectedBuckets = ['product-images'];
      final missingBuckets = expectedBuckets.where((b) => !bucketNames.contains(b)).toList();
      
      return {
        'success': true,
        'bucket_names': bucketNames,
        'missing_buckets': missingBuckets,
        'message': 'Se encontraron ${buckets.length} buckets. Faltan: $missingBuckets'
      };
    } catch (e) {
      AppLogger.e('   ❌ Error listando buckets: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al listar buckets - Verifica permisos RLS'
      };
    }
  }

  Future<Map<String, dynamic>> _checkSpecificBucket(String bucketName) async {
    try {
      AppLogger.d('2. 🔍 VERIFICANDO BUCKET: $bucketName');
      
      final buckets = await _supabase.storage.listBuckets();
      final targetBucket = buckets.firstWhere(
        (bucket) => bucket.name == bucketName,
      );

      AppLogger.d('   ✅ Bucket encontrado: ${targetBucket.name}');
      AppLogger.d('   🆔 ID: ${targetBucket.id}');
      AppLogger.d('   👁️  Público: ${targetBucket.public}');

      return {
        'success': true,
        'bucket_name': targetBucket.name,
        'bucket_id': targetBucket.id,
        'is_public': targetBucket.public,
        'message': 'Bucket $bucketName existe y es accesible'
      };
    } catch (e) {
      AppLogger.e('   ❌ Bucket $bucketName no encontrado: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Bucket $bucketName no existe'
      };
    }
  }

  Future<Map<String, dynamic>> _checkAuthentication() async {
    try {
      AppLogger.d('3. 👤 VERIFICANDO AUTENTICACIÓN...');
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        AppLogger.e('   ❌ Usuario NO autenticado');
        return {
          'success': false,
          'error': 'Usuario no autenticado',
          'message': 'Inicia sesión para realizar operaciones'
        };
      }

      AppLogger.d('   ✅ Usuario autenticado: ${currentUser.email}');
      AppLogger.d('   🆔 User ID: ${currentUser.id}');

      return {
        'success': true,
        'user_email': currentUser.email,
        'user_id': currentUser.id,
        'message': 'Usuario autenticado correctamente'
      };
    } catch (e) {
      AppLogger.e('   ❌ Error en autenticación: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando autenticación'
      };
    }
  }

  Future<Map<String, dynamic>> _checkPolicies(String bucketName) async {
    try {
      AppLogger.d('4. 🛡️  VERIFICANDO POLÍTICAS PARA: $bucketName');
      
      // Probar SELECT
      try {
        final files = await _supabase.storage.from(bucketName).list();
        AppLogger.d('   ✅ Política SELECT: OK - ${files.length} archivos');
      } catch (e) {
        AppLogger.e('   ❌ Política SELECT falló: $e');
        return {
          'success': false,
          'error': 'SELECT falló: $e',
          'message': 'Política SELECT no configurada'
        };
      }

      // Probar INSERT (solo si hay usuario autenticado)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        try {
          final testData = [0x74, 0x65, 0x73, 0x74]; // "test" en bytes
          final testPath = 'diagnostic_test_${DateTime.now().millisecondsSinceEpoch}.txt';
          
          await _supabase.storage
              .from(bucketName)
              .uploadBinary(testPath, Uint8List.fromList(testData));
          
          AppLogger.d('   ✅ Política INSERT: OK');
          
          // Limpiar
          await _supabase.storage.from(bucketName).remove([testPath]);
          AppLogger.d('   ✅ Política DELETE: OK');
          
        } catch (e) {
          AppLogger.e('   ❌ Política INSERT falló: $e');
          return {
            'success': false,
            'error': 'INSERT falló: $e',
            'message': 'Política INSERT no configurada'
          };
        }
      }

      return {
        'success': true,
        'message': 'Todas las políticas funcionan correctamente'
      };
    } catch (e) {
      AppLogger.e('   ❌ Error verificando políticas: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando políticas'
      };
    }
  }

  Future<Map<String, dynamic>> _testActualUpload() async {
    try {
      AppLogger.d('5. 🧪 PRUEBA REAL DE SUBIDA...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Usuario no autenticado',
          'message': 'No se puede probar subida sin usuario'
        };
      }

      // Crear una imagen de prueba pequeña (1x1 pixel PNG)
      final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      final testPath = 'real_test_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Intentar con diferentes nombres de buckets
      final possibleBuckets = ['product-images', 'bucket'];
      String? successfulBucket;
      String? publicUrl;

      for (final bucket in possibleBuckets) {
        try {
          AppLogger.d('   🔄 Probando bucket: $bucket');
          
          // Verificar si el bucket existe
          final buckets = await _supabase.storage.listBuckets();
          final bucketExists = buckets.any((b) => b.name == bucket);
          
          if (!bucketExists) {
            AppLogger.d('   ❌ Bucket $bucket no existe');
            continue;
          }
          
          await _supabase.storage
              .from(bucket)
              .uploadBinary(testPath, Uint8List.fromList(pngHeader));
          
          publicUrl = _supabase.storage.from(bucket).getPublicUrl(testPath);
          successfulBucket = bucket;
          AppLogger.d('   ✅ Subida exitosa en: $bucket');
          break;
        } catch (e) {
          AppLogger.d('   ❌ Falló en $bucket: $e');
        }
      }

      if (successfulBucket != null) {
        // Limpiar
        try {
          await _supabase.storage.from(successfulBucket).remove([testPath]);
        } catch (e) {
          AppLogger.w('   ⚠️  No se pudo limpiar archivo de prueba');
        }

        return {
          'success': true,
          'bucket_used': successfulBucket,
          'public_url': publicUrl,
          'message': 'Subida real exitosa en bucket: $successfulBucket'
        };
      } else {
        return {
          'success': false,
          'error': 'Todos los buckets fallaron',
          'message': 'No se pudo subir a ningún bucket'
        };
      }

    } catch (e) {
      AppLogger.e('   ❌ Error en prueba real: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error en prueba real de subida'
      };
    }
  }

  Map<String, dynamic> _compileFinalResults(Map<String, dynamic> results) {
    final errors = results['errors'] as List<dynamic>;
    final missingBuckets = results['missing_buckets'] as List<dynamic>;
    final hasErrors = errors.isNotEmpty || missingBuckets.isNotEmpty;

    results['success'] = !hasErrors;
    
    if (hasErrors) {
      String errorMessage = '❌ Se encontraron problemas:';
      if (errors.isNotEmpty) {
        errorMessage += '\n• ${errors.length} errores críticos';
      }
      if (missingBuckets.isNotEmpty) {
        errorMessage += '\n• Faltan buckets: ${missingBuckets.join(', ')}';
      }
      results['message'] = errorMessage;
    } else {
      results['message'] = '🎉 ¡SISTEMA CONFIGURADO CORRECTAMENTE!';
    }

    AppLogger.d('=' * 60);
    AppLogger.d('📊 RESUMEN FINAL DEL DIAGNÓSTICO:');
    AppLogger.d('   ✅ Éxito: ${!hasErrors}');
    AppLogger.d('   📦 Buckets disponibles: ${results['bucket_names']}');
    AppLogger.d('   ❌ Buckets faltantes: ${results['missing_buckets']}');
    AppLogger.d('   ⚠️  Errores: ${errors.length}');
    if (errors.isNotEmpty) {
      for (final error in errors) {
        AppLogger.d('      - $error');
      }
    }
    AppLogger.d('=' * 60);

    return results;
  }
}