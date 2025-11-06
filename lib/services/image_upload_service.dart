// lib/services/image_upload_service.dart - VERSIÓN COMPLETA CON HISTORIAS
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  // ✅ MÉTODO PRINCIPAL CORREGIDO - PRODUCTOS
  Future<String?> uploadProductImage(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 INICIANDO SUBIDA DE IMAGEN DE PRODUCTO...');

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        AppLogger.e('❌ El archivo no existe');
        return null;
      }

      final fileLength = await imageFile.length();
      AppLogger.d('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 5 * 1024 * 1024) {
        AppLogger.e('❌ Imagen demasiado grande (máximo 5MB)');
        return null;
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return null;
      }

      // 3. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'products/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a product-images');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN
      AppLogger.d('🔄 Subiendo a product-images...');
      
      final uploadResponse = await _supabase.storage
          .from('product-images')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Imagen subida exitosamente: $uploadResponse');

      // 6. ✅ OBTENER URL PÚBLICA CORRECTAMENTE
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      // 7. ✅ VERIFICAR QUE LA URL ES ACCESIBLE
      try {
        final response = await _supabase.storage
            .from('product-images')
            .list(path: 'products');
        AppLogger.d('✅ Verificación de URL: OK - ${response.length} archivos en products');
      } catch (e) {
        AppLogger.w('⚠️ Advertencia en verificación: $e');
      }

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO subiendo imagen: $e');
      
      // ✅ DEBUG DETALLADO
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que product-images exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO NUEVO: Subir imagen de historia
  Future<String?> uploadStoryImage(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO IMAGEN DE HISTORIA...');

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        AppLogger.e('❌ El archivo no existe');
        return null;
      }

      final fileLength = await imageFile.length();
      AppLogger.d('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 5 * 1024 * 1024) {
        AppLogger.e('❌ Imagen demasiado grande (máximo 5MB)');
        return null;
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return null;
      }

      // 3. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'story_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'stories/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a stories');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN AL BUCKET DE HISTORIAS
      AppLogger.d('🔄 Subiendo a stories...');
      
      final uploadResponse = await _supabase.storage
          .from('stories')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Imagen de historia subida exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('stories')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo imagen de historia: $e');
      
      // DEBUG DETALLADO
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que stories exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT en stories');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO NUEVO: Subir imagen de perfil
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO IMAGEN DE PERFIL...');

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        AppLogger.e('❌ El archivo no existe');
        return null;
      }

      final fileLength = await imageFile.length();
      AppLogger.d('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 3 * 1024 * 1024) {
        AppLogger.e('❌ Imagen demasiado grande (máximo 3MB)');
        return null;
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return null;
      }

      // 3. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final filePath = 'profiles/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a product-images');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN
      AppLogger.d('🔄 Subiendo a product-images...');
      
      final uploadResponse = await _supabase.storage
          .from('product-images')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Imagen de perfil subida exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo imagen de perfil: $e');
      
      // DEBUG DETALLADO
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que product-images exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO SIMPLIFICADO PARA VERIFICAR BUCKET
  Future<bool> checkBucketExists(String bucketName) async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final exists = buckets.any((bucket) => bucket.name == bucketName);
      AppLogger.d('📦 Bucket $bucketName existe: $exists');
      return exists;
    } catch (e) {
      AppLogger.e('❌ Error verificando bucket: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA ELIMINAR IMAGEN (CORREGIDO)
  Future<bool> deleteProductImage(String imageUrl) async {
    try {
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 2) {
        AppLogger.e('❌ URL de imagen inválida');
        return false;
      }

      // El path del archivo es todo después del bucket name
      final filePath = pathSegments.sublist(2).join('/');
      
      AppLogger.d('🗑️ Eliminando imagen: $filePath');

      await _supabase.storage
          .from('product-images')
          .remove([filePath]);

      AppLogger.d('✅ Imagen eliminada: $filePath');
      return true;
    } catch (e) {
      AppLogger.e('❌ Error eliminando imagen: $e');
      return false;
    }
  }

  // ✅ MÉTODO NUEVO: Eliminar imagen de historia
  Future<bool> deleteStoryImage(String imageUrl) async {
    try {
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 2) {
        AppLogger.e('❌ URL de imagen de historia inválida');
        return false;
      }

      // El path del archivo es todo después del bucket name
      final filePath = pathSegments.sublist(2).join('/');
      
      AppLogger.d('🗑️ Eliminando imagen de historia: $filePath');

      await _supabase.storage
          .from('stories')
          .remove([filePath]);

      AppLogger.d('✅ Imagen de historia eliminada: $filePath');
      return true;
    } catch (e) {
      AppLogger.e('❌ Error eliminando imagen de historia: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA ELIMINAR IMAGEN DE PERFIL
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 2) {
        AppLogger.e('❌ URL de imagen de perfil inválida');
        return false;
      }

      // El path del archivo es todo después del bucket name
      final filePath = pathSegments.sublist(2).join('/');
      
      AppLogger.d('🗑️ Eliminando imagen de perfil: $filePath');

      await _supabase.storage
          .from('product-images')
          .remove([filePath]);

      AppLogger.d('✅ Imagen de perfil eliminada: $filePath');
      return true;
    } catch (e) {
      AppLogger.e('❌ Error eliminando imagen de perfil: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA LISTAR ARCHIVOS (CORREGIDO - SIN .size)
  Future<void> listProductImages() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list();
      
      AppLogger.d('📁 Archivos en product-images: ${files.length}');
      for (final file in files) {
        AppLogger.d('   - ${file.name}'); // ✅ SOLO nombre, sin .size
      }
    } catch (e) {
      AppLogger.e('❌ Error listando archivos: $e');
    }
  }

  // ✅ MÉTODO NUEVO: Listar imágenes de historias
  Future<void> listStoryImages() async {
    try {
      final files = await _supabase.storage
          .from('stories')
          .list();
      
      AppLogger.d('📁 Archivos en stories: ${files.length}');
      for (final file in files) {
        AppLogger.d('   - ${file.name}');
      }
    } catch (e) {
      AppLogger.e('❌ Error listando imágenes de historias: $e');
    }
  }

  // ✅ MÉTODO NUEVO: LISTAR ARCHIVOS DE PERFIL
  Future<void> listProfileImages() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list(path: 'profiles');
      
      AppLogger.d('📁 Archivos de perfil en product-images: ${files.length}');
      for (final file in files) {
        AppLogger.d('   - ${file.name}');
      }
    } catch (e) {
      AppLogger.e('❌ Error listando imágenes de perfil: $e');
    }
  }

  // ✅ MÉTODO NUEVO: VERIFICAR SI UN ARCHIVO EXISTE
  Future<bool> checkFileExists(String filePath) async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list(path: filePath);
      return files.isNotEmpty;
    } catch (e) {
      AppLogger.e('❌ Error verificando archivo: $e');
      return false;
    }
  }

  // ✅ MÉTODO NUEVO: OBTENER INFO DETALLADA DE ARCHIVOS
  Future<void> getDetailedFileInfo() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list();
      
      AppLogger.d('📊 INFORMACIÓN DETALLADA DE ARCHIVOS:');
      for (final file in files) {
        AppLogger.d('''
   📄 ${file.name}
   📂 ${file.id}
   🕒 ${file.updatedAt}
   👤 ${file.owner}
   ${file.metadata != null ? '📋 Metadata: ${file.metadata}' : ''}
        ''');
      }
    } catch (e) {
      AppLogger.e('❌ Error obteniendo info detallada: $e');
    }
  }

  // ✅ MÉTODO CORREGIDO: LIMPIAR IMÁGENES TEMPORALES
  Future<void> cleanupTempImages(String userId) async {
    try {
      AppLogger.d('🧹 Limpiando imágenes temporales del usuario: $userId');
      
      // Listar todas las imágenes del usuario
      final allFiles = await _supabase.storage
          .from('product-images')
          .list();
      
      // Filtrar imágenes antiguas (más de 7 días)
      final filesToDelete = <String>[];
      final now = DateTime.now();
      
      for (final file in allFiles) {
        if (file.updatedAt != null) {
          try {
            // ✅ CORREGIDO: Convertir String a DateTime
            final updatedAt = DateTime.parse(file.updatedAt!);
            final fileAge = now.difference(updatedAt);
            if (fileAge.inDays > 7) {
              filesToDelete.add(file.name);
            }
          } catch (e) {
            AppLogger.w('⚠️ Error parseando fecha para archivo ${file.name}: $e');
          }
        }
      }
      
      if (filesToDelete.isNotEmpty) {
        await _supabase.storage
            .from('product-images')
            .remove(filesToDelete);
        AppLogger.d('✅ Imágenes temporales eliminadas: ${filesToDelete.length}');
      } else {
        AppLogger.d('✅ No hay imágenes temporales para limpiar');
      }
      
    } catch (e) {
      AppLogger.e('❌ Error limpiando imágenes temporales: $e');
    }
  }

  // ✅ MÉTODO NUEVO: OBTENER ESTADÍSTICAS DE STORAGE
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list();
      
      int totalFiles = files.length;
      int productImages = files.where((f) => f.name.contains('product_')).length;
      int profileImages = files.where((f) => f.name.contains('profile_')).length;
      
      return {
        'total_files': totalFiles,
        'product_images': productImages,
        'profile_images': profileImages,
        'other_files': totalFiles - productImages - profileImages,
      };
    } catch (e) {
      AppLogger.e('❌ Error obteniendo estadísticas de storage: $e');
      return {
        'total_files': 0,
        'product_images': 0,
        'profile_images': 0,
        'other_files': 0,
      };
    }
  }
}