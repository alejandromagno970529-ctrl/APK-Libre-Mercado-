import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class SupabaseCheck {
  final SupabaseClient _supabase;

  SupabaseCheck(this._supabase);

  Future<Map<String, dynamic>> checkConnection() async {
    try {
      AppLogger.d('🔗 Verificando conexión con Supabase...');
      
      // Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      final hasSession = currentUser != null;
      
      // Verificar base de datos (sin variable sin uso)
      await _supabase
          .from('products')
          .select('count')
          .limit(1);
      
      // Verificar storage
      final buckets = await _supabase.storage.listBuckets();
      final hasStorage = buckets.isNotEmpty;
      
      AppLogger.d('✅ Conexión Supabase verificada correctamente');
      
      return {
        'success': true,
        'has_session': hasSession,
        'user_email': currentUser?.email,
        'database_accessible': true,
        'storage_accessible': hasStorage,
        'buckets_count': buckets.length,
        'message': 'Conexión establecida correctamente',
      };
      
    } catch (e) {
      AppLogger.e('❌ Error verificando conexión Supabase', e);
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error en la conexión con Supabase',
      };
    }
  }

  Future<bool> checkTableExists(String tableName) async {
    try {
      await _supabase
          .from(tableName)
          .select()
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkBucketExists(String bucketName) async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      return buckets.any((bucket) => bucket.name == bucketName);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> comprehensiveCheck() async {
    final connectionResult = await checkConnection();
    
    // Verificar tablas importantes
    final importantTables = ['products', 'profiles', 'chats', 'messages', 'ratings'];
    final tablesCheck = <String, bool>{};
    for (final table in importantTables) {
      tablesCheck[table] = await checkTableExists(table);
    }

    // Verificar buckets importantes
    final importantBuckets = ['product-images'];
    final bucketsCheck = <String, bool>{};
    for (final bucket in importantBuckets) {
      bucketsCheck[bucket] = await checkBucketExists(bucket);
    }

    // Calcular éxito general
    final connectionSuccess = connectionResult['success'] == true;
    final allTablesExist = !tablesCheck.containsValue(false);
    final allBucketsExist = !bucketsCheck.containsValue(false);
    
    return {
      'connection': connectionResult,
      'tables': tablesCheck,
      'buckets': bucketsCheck,
      'overall_success': connectionSuccess && allTablesExist && allBucketsExist,
      'summary': {
        'connection_ok': connectionSuccess,
        'tables_ok': allTablesExist,
        'buckets_ok': allBucketsExist,
      }
    };
  }

  // ✅ MÉTODO: Verificar políticas RLS específicas
  Future<Map<String, dynamic>> checkRLSPolicies() async {
    try {
      final results = <String, dynamic>{};
      final currentUser = _supabase.auth.currentUser;
      
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Usuario no autenticado para verificar políticas RLS'
        };
      }

      // Verificar políticas de productos
      try {
        // Intentar leer productos
        final productsResult = await _supabase.from('products').select().limit(1);
        results['products_select'] = true;
        results['products_count'] = productsResult.length;
      } catch (e) {
        results['products_select'] = false;
        results['products_select_error'] = e.toString();
      }

      // Verificar políticas de perfiles
      try {
        final profileResult = await _supabase.from('profiles').select().eq('id', currentUser.id).single();
        results['profiles_select'] = true;
        results['profile_data'] = profileResult.isNotEmpty;
      } catch (e) {
        results['profiles_select'] = false;
        results['profiles_select_error'] = e.toString();
      }

      // Verificar políticas de storage
      try {
        final buckets = await _supabase.storage.listBuckets();
        results['storage_list'] = true;
        results['available_buckets'] = buckets.map((b) => b.name).toList();
        results['buckets_count'] = buckets.length;
      } catch (e) {
        results['storage_list'] = false;
        results['storage_list_error'] = e.toString();
      }

      // Verificar si podemos crear un producto (política INSERT)
      try {
        final testProduct = {
          'titulo': 'Producto de prueba RLS',
          'descripcion': 'Este es un producto de prueba para verificar políticas RLS',
          'precio': 0.0,
          'categorias': 'Prueba',
          'user_id': currentUser.id,
          'created_at': DateTime.now().toIso8601String(),
          'latitud': 0.0,
          'longitud': 0.0,
          'moneda': 'CUP',
          'disponible': false, // Marcado como no disponible para no aparecer en listados
        };
        
        final insertResult = await _supabase
            .from('products')
            .insert(testProduct)
            .select();
            
        results['products_insert'] = true;
        results['inserted_id'] = insertResult[0]['id'];
        
        // Limpiar el producto de prueba
        if (insertResult.isNotEmpty) {
          await _supabase
              .from('products')
              .delete()
              .eq('id', insertResult[0]['id']);
        }
      } catch (e) {
        results['products_insert'] = false;
        results['products_insert_error'] = e.toString();
      }

      results['success'] = !results.containsValue(false);
      results['message'] = results['success'] 
          ? 'Todas las políticas RLS funcionan correctamente'
          : 'Algunas políticas RLS tienen problemas';

      return results;

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error verificando políticas RLS'
      };
    }
  }

  // ✅ MÉTODO: Diagnóstico rápido del sistema
  Future<Map<String, dynamic>> quickDiagnostic() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.d('🔍 Iniciando diagnóstico rápido del sistema...');

      final connection = await checkConnection();
      final rlsPolicies = await checkRLSPolicies();
      
      final connectionSuccess = connection['success'] == true;
      final rlsSuccess = rlsPolicies['success'] == true;
      
      final diagnosticResult = {
        'timestamp': DateTime.now().toIso8601String(),
        'duration_ms': stopwatch.elapsedMilliseconds,
        'connection': connection,
        'rls_policies': rlsPolicies,
        'system_healthy': connectionSuccess && rlsSuccess,
        'health_status': connectionSuccess && rlsSuccess ? '✅ SALUDABLE' : '❌ CON PROBLEMAS',
      };

      stopwatch.stop();
      
      AppLogger.d('📊 Diagnóstico completado en ${stopwatch.elapsedMilliseconds}ms');
      AppLogger.d('✅ Sistema saludable: ${diagnosticResult['system_healthy']}');

      return diagnosticResult;

    } catch (e) {
      stopwatch.stop();
      AppLogger.e('❌ Error en diagnóstico rápido', e);
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'duration_ms': stopwatch.elapsedMilliseconds,
        'system_healthy': false,
        'health_status': '❌ ERROR',
        'error': e.toString(),
        'message': 'Error durante el diagnóstico del sistema'
      };
    }
  }

  // ✅ MÉTODO: Verificar configuración mínima requerida
  Future<Map<String, dynamic>> checkMinimumRequirements() async {
    try {
      final requirements = <String, dynamic>{};
      
      // 1. Conexión básica
      final connection = await checkConnection();
      requirements['supabase_connection'] = connection['success'] == true;
      
      // 2. Tablas esenciales
      requirements['products_table'] = await checkTableExists('products');
      requirements['profiles_table'] = await checkTableExists('profiles');
      requirements['chats_table'] = await checkTableExists('chats');
      requirements['messages_table'] = await checkTableExists('messages');
      
      // 3. Bucket de imágenes
      requirements['product_images_bucket'] = await checkBucketExists('product-images');
      
      // 4. Verificar si todas las requirements están cumplidas
      final allMet = !requirements.containsValue(false);
      
      return {
        'requirements': requirements,
        'all_requirements_met': allMet,
        'missing_requirements': requirements.entries
            .where((entry) => entry.value == false)
            .map((entry) => entry.key)
            .toList(),
        'message': allMet 
            ? '✅ Todas las requirements mínimas están cumplidas'
            : '❌ Faltan algunas requirements del sistema'
      };
      
    } catch (e) {
      return {
        'requirements': {},
        'all_requirements_met': false,
        'missing_requirements': ['error_during_check'],
        'error': e.toString(),
        'message': 'Error verificando requirements del sistema'
      };
    }
  }

  // ✅ MÉTODO NUEVO: Obtener resumen de estado del sistema
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final quickDiag = await quickDiagnostic();
      final minRequirements = await checkMinimumRequirements();
      
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'system_health': quickDiag['system_healthy'] == true ? 'healthy' : 'unhealthy',
        'requirements_met': minRequirements['all_requirements_met'] == true,
        'quick_diagnostic': quickDiag,
        'minimum_requirements': minRequirements,
        'recommendations': _generateRecommendations(quickDiag, minRequirements),
      };
    } catch (e) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'system_health': 'unknown',
        'requirements_met': false,
        'error': e.toString(),
        'message': 'Error obteniendo estado del sistema'
      };
    }
  }

  // ✅ MÉTODO PRIVADO: Generar recomendaciones basadas en el diagnóstico
  List<String> _generateRecommendations(
    Map<String, dynamic> quickDiag, 
    Map<String, dynamic> minRequirements
  ) {
    final recommendations = <String>[];
    
    if (quickDiag['system_healthy'] != true) {
      recommendations.add('Revisar la conexión con Supabase y las políticas RLS');
    }
    
    final missingReqs = minRequirements['missing_requirements'] as List<dynamic>?;
    if (missingReqs != null && missingReqs.isNotEmpty) {
      recommendations.add('Configurar los siguientes elementos: ${missingReqs.join(', ')}');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ El sistema está configurado correctamente');
    }
    
    return recommendations;
  }
}