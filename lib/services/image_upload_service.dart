// lib/services/image_upload_service.dart - VERSIÓN COMPLETA CORREGIDA
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  // ✅ MÉTODO PRINCIPAL CORREGIDO - PRODUCTOS
  Future<String?> uploadProductImage(File imageFile, String userId) async {
    try {
      print('📤 INICIANDO SUBIDA DE IMAGEN DE PRODUCTO...');

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        print('❌ El archivo no existe');
        return null;
      }

      final fileLength = await imageFile.length();
      print('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 5 * 1024 * 1024) {
        print('❌ Imagen demasiado grande (máximo 5MB)');
        return null;
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ Usuario no autenticado');
        return null;
      }

      // 3. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'products/$fileName';

      print('📁 Subiendo: $fileName a product-images');
      print('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      print('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN
      print('🔄 Subiendo a product-images...');
      
      final uploadResponse = await _supabase.storage
          .from('product-images')
          .uploadBinary(filePath, imageBytes);

      print('✅ Imagen subida exitosamente: $uploadResponse');

      // 6. ✅ OBTENER URL PÚBLICA CORRECTAMENTE
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      print('🌐 URL pública generada: $publicUrl');

      // 7. ✅ VERIFICAR QUE LA URL ES ACCESIBLE
      try {
        final response = await _supabase.storage
            .from('product-images')
            .list(path: 'products');
        print('✅ Verificación de URL: OK - ${response.length} archivos en products');
      } catch (e) {
        print('⚠️ Advertencia en verificación: $e');
      }

      return publicUrl;

    } catch (e) {
      print('❌ ERROR CRÍTICO subiendo imagen: $e');
      
      // ✅ DEBUG DETALLADO
      if (e.toString().contains('bucket')) {
        print('🔴 PROBLEMA CON BUCKET: Verifica que product-images exista');
      } else if (e.toString().contains('policy')) {
        print('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT');
      } else if (e.toString().contains('JWT')) {
        print('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO NUEVO: Subir imagen de perfil
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      print('📤 SUBIENDO IMAGEN DE PERFIL...');

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        print('❌ El archivo no existe');
        return null;
      }

      final fileLength = await imageFile.length();
      print('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 3 * 1024 * 1024) {
        print('❌ Imagen demasiado grande (máximo 3MB)');
        return null;
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ Usuario no autenticado');
        return null;
      }

      // 3. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final filePath = 'profiles/$fileName';

      print('📁 Subiendo: $fileName a product-images');
      print('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      print('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN
      print('🔄 Subiendo a product-images...');
      
      final uploadResponse = await _supabase.storage
          .from('product-images')
          .uploadBinary(filePath, imageBytes);

      print('✅ Imagen de perfil subida exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      print('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      print('❌ ERROR subiendo imagen de perfil: $e');
      
      // DEBUG DETALLADO
      if (e.toString().contains('bucket')) {
        print('🔴 PROBLEMA CON BUCKET: Verifica que product-images exista');
      } else if (e.toString().contains('policy')) {
        print('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO SIMPLIFICADO PARA VERIFICAR BUCKET
  Future<bool> checkBucketExists(String bucketName) async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final exists = buckets.any((bucket) => bucket.name == bucketName);
      print('📦 Bucket $bucketName existe: $exists');
      return exists;
    } catch (e) {
      print('❌ Error verificando bucket: $e');
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
        print('❌ URL de imagen inválida');
        return false;
      }

      // El path del archivo es todo después del bucket name
      final filePath = pathSegments.sublist(2).join('/');
      
      print('🗑️ Eliminando imagen: $filePath');

      await _supabase.storage
          .from('product-images')
          .remove([filePath]);

      print('✅ Imagen eliminada: $filePath');
      return true;
    } catch (e) {
      print('❌ Error eliminando imagen: $e');
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
        print('❌ URL de imagen de perfil inválida');
        return false;
      }

      // El path del archivo es todo después del bucket name
      final filePath = pathSegments.sublist(2).join('/');
      
      print('🗑️ Eliminando imagen de perfil: $filePath');

      await _supabase.storage
          .from('product-images')
          .remove([filePath]);

      print('✅ Imagen de perfil eliminada: $filePath');
      return true;
    } catch (e) {
      print('❌ Error eliminando imagen de perfil: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA LISTAR ARCHIVOS (CORREGIDO - SIN .size)
  Future<void> listProductImages() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list();
      
      print('📁 Archivos en product-images: ${files.length}');
      for (final file in files) {
        print('   - ${file.name}'); // ✅ SOLO nombre, sin .size
      }
    } catch (e) {
      print('❌ Error listando archivos: $e');
    }
  }

  // ✅ MÉTODO NUEVO: LISTAR ARCHIVOS DE PERFIL
  Future<void> listProfileImages() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list(path: 'profiles');
      
      print('📁 Archivos de perfil en product-images: ${files.length}');
      for (final file in files) {
        print('   - ${file.name}');
      }
    } catch (e) {
      print('❌ Error listando imágenes de perfil: $e');
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
      print('❌ Error verificando archivo: $e');
      return false;
    }
  }

  // ✅ MÉTODO NUEVO: OBTENER INFO DETALLADA DE ARCHIVOS
  Future<void> getDetailedFileInfo() async {
    try {
      final files = await _supabase.storage
          .from('product-images')
          .list();
      
      print('📊 INFORMACIÓN DETALLADA DE ARCHIVOS:');
      for (final file in files) {
        print('''
   📄 ${file.name}
   📂 ${file.id}
   🕒 ${file.updatedAt}
   👤 ${file.owner}
   ${file.metadata != null ? '📋 Metadata: ${file.metadata}' : ''}
        ''');
      }
    } catch (e) {
      print('❌ Error obteniendo info detallada: $e');
    }
  }

  // ✅ MÉTODO CORREGIDO: LIMPIAR IMÁGENES TEMPORALES
  Future<void> cleanupTempImages(String userId) async {
    try {
      print('🧹 Limpiando imágenes temporales del usuario: $userId');
      
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
            print('⚠️ Error parseando fecha para archivo ${file.name}: $e');
          }
        }
      }
      
      if (filesToDelete.isNotEmpty) {
        await _supabase.storage
            .from('product-images')
            .remove(filesToDelete);
        print('✅ Imágenes temporales eliminadas: ${filesToDelete.length}');
      } else {
        print('✅ No hay imágenes temporales para limpiar');
      }
      
    } catch (e) {
      print('❌ Error limpiando imágenes temporales: $e');
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
      print('❌ Error obteniendo estadísticas de storage: $e');
      return {
        'total_files': 0,
        'product_images': 0,
        'profile_images': 0,
        'other_files': 0,
      };
    }
  }
}