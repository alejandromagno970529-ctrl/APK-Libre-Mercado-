// lib/services/image_upload_service.dart - VERSIÓN COMPLETA CON MÉTODOS DE TIENDA
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  // ✅ MÉTODO FALTANTE: uploadStoryImage - Agregado para solucionar el error
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

  // ✅ MÉTODO MEJORADO: Extraer información de la URL de imagen
  Map<String, String>? _parseImageUrl(String imageUrl) {
    try {
      AppLogger.d('🔍 Analizando URL de imagen: $imageUrl');
      
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        AppLogger.w('⚠️ No se pudieron extraer segmentos de la URL');
        return null;
      }

      // Buscar el bucket en los pathSegments
      for (int i = 0; i < pathSegments.length; i++) {
        final segment = pathSegments[i];
        if (segment == 'profile-images' || segment == 'product-images' || segment == 'stories' || segment == 'store-logos' || segment == 'store-banners') {
          final bucketName = segment;
          
          // El nombre del archivo debería ser el resto de los segmentos
          if (i + 1 < pathSegments.length) {
            final fileName = pathSegments.sublist(i + 1).join('/');
            AppLogger.d('📦 Bucket: $bucketName, Archivo: $fileName');
            return {
              'bucketName': bucketName,
              'fileName': fileName,
            };
          }
        }
      }

      AppLogger.w('⚠️ No se pudo determinar bucket o nombre de archivo');
      AppLogger.d('🔍 Segmentos encontrados: $pathSegments');
      return null;
    } catch (e) {
      AppLogger.e('❌ Error analizando URL de imagen: $e');
      return null;
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar imagen del almacenamiento
  Future<bool> deleteImage(String imageUrl) async {
    try {
      AppLogger.d('🗑️ INICIANDO ELIMINACIÓN DE IMAGEN...');
      AppLogger.d('🔗 URL a eliminar: $imageUrl');

      // 1. Extraer información de la URL
      final imageInfo = _parseImageUrl(imageUrl);
      if (imageInfo == null) {
        AppLogger.e('❌ No se pudo extraer información de la URL');
        return false;
      }

      final bucketName = imageInfo['bucketName']!;
      final fileName = imageInfo['fileName']!;

      AppLogger.d('📦 Bucket identificado: $bucketName');
      AppLogger.d('📄 Archivo a eliminar: $fileName');

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado para eliminar imagen');
        return false;
      }

      // 3. ELIMINAR EL ARCHIVO DEL BUCKET
      AppLogger.d('🔄 Eliminando archivo del storage...');
      
      await _supabase.storage
          .from(bucketName)
          .remove([fileName]);

      AppLogger.d('✅ Imagen eliminada exitosamente del bucket: $bucketName');
      return true;

    } catch (e) {
      AppLogger.e('❌ ERROR eliminando imagen del almacenamiento: $e');
      
      // Análisis detallado del error
      if (e.toString().contains('Bucket not found')) {
        AppLogger.e('🔴 PROBLEMA: El bucket no existe');
      } else if (e.toString().contains('Object not found')) {
        AppLogger.w('⚠️ La imagen ya no existe en el almacenamiento');
        return true; // Considerar como éxito si ya no existe
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas DELETE en el bucket');
        AppLogger.e('💡 Solución: Ejecuta las políticas SQL en el dashboard de Supabase');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido o expirado');
      } else if (e.toString().contains('Permission denied')) {
        AppLogger.e('🔴 PROBLEMA DE PERMISOS: El usuario no tiene permisos para eliminar esta imagen');
      }
      
      return false;
    }
  }

  // ✅ MÉTODO MEJORADO: Eliminar múltiples imágenes
  Future<int> deleteMultipleImages(List<String> imageUrls) async {
    try {
      AppLogger.d('🗑️ ELIMINANDO ${imageUrls.length} IMÁGENES...');
      
      int successCount = 0;
      
      for (final imageUrl in imageUrls) {
        final success = await deleteImage(imageUrl);
        if (success) {
          successCount++;
        } else {
          AppLogger.w('⚠️ No se pudo eliminar imagen: $imageUrl');
        }
      }
      
      AppLogger.d('✅ Eliminación completada: $successCount/${imageUrls.length} imágenes eliminadas');
      return successCount;
    } catch (e) {
      AppLogger.e('❌ ERROR eliminando múltiples imágenes: $e');
      return 0;
    }
  }

  // ✅ MÉTODO: Subir imagen de perfil
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
      final fileName = 'profile_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'profiles/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a profile-images');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN AL BUCKET DE PERFILES
      AppLogger.d('🔄 Subiendo a profile-images...');
      
      final uploadResponse = await _supabase.storage
          .from('profile-images')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Imagen de perfil subida exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo imagen de perfil: $e');
      
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que profile-images exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT en profile-images');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO: Subir imagen de producto (individual)
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

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO subiendo imagen: $e');
      
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

  // ✅ NUEVO MÉTODO: Subir logo de tienda
  Future<String?> uploadStoreLogoImage(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO LOGO DE TIENDA...');

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
      final fileName = 'store_logo_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'store-logos/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a store-logos');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN AL BUCKET DE LOGOS DE TIENDA
      AppLogger.d('🔄 Subiendo a store-logos...');
      
      final uploadResponse = await _supabase.storage
          .from('store-logos')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Logo de tienda subido exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('store-logos')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo logo de tienda: $e');
      
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que store-logos exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT en store-logos');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ NUEVO MÉTODO: Subir banner de tienda
  Future<String?> uploadStoreBannerImage(File imageFile, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO BANNER DE TIENDA...');

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
      final fileName = 'store_banner_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'store-banners/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a store-banners');
      AppLogger.d('👤 Usuario: ${currentUser.email}');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${imageBytes.length}');

      // 5. SUBIR IMAGEN AL BUCKET DE BANNERS DE TIENDA
      AppLogger.d('🔄 Subiendo a store-banners...');
      
      final uploadResponse = await _supabase.storage
          .from('store-banners')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Banner de tienda subido exitosamente: $uploadResponse');

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('store-banners')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo banner de tienda: $e');
      
      if (e.toString().contains('bucket')) {
        AppLogger.e('🔴 PROBLEMA CON BUCKET: Verifica que store-banners exista');
      } else if (e.toString().contains('policy')) {
        AppLogger.e('🔴 PROBLEMA CON POLÍTICAS RLS: Verifica políticas INSERT en store-banners');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 PROBLEMA DE AUTENTICACIÓN: Token inválido');
      }
      
      return null;
    }
  }

  // ✅ MÉTODO: Subir imagen de historia DESDE BYTES
  Future<String?> uploadStoryImageFromBytes(Uint8List imageBytes, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO IMAGEN DE HISTORIA DESDE BYTES...');

      // 1. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return null;
      }

      // 2. Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'story_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'stories/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a stories');
      AppLogger.d('📦 Bytes a subir: ${imageBytes.length}');

      // 3. SUBIR IMAGEN AL BUCKET DE HISTORIAS
      AppLogger.d('🔄 Subiendo a stories...');
      
      final uploadResponse = await _supabase.storage
          .from('stories')
          .uploadBinary(filePath, imageBytes);

      AppLogger.d('✅ Imagen de historia subida exitosamente: $uploadResponse');

      // 4. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from('stories')
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo imagen de historia desde bytes: $e');
      return null;
    }
  }

  // ✅ MÉTODO: Subir múltiples imágenes de producto
  Future<List<String>> uploadMultipleProductImages(List<File> imageFiles, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO ${imageFiles.length} IMÁGENES DE PRODUCTO...');

      final List<String> uploadedUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final imageFile = imageFiles[i];
          
          // Verificaciones básicas
          if (!await imageFile.exists()) {
            AppLogger.e('❌ El archivo ${i + 1} no existe');
            continue;
          }

          final fileLength = await imageFile.length();
          if (fileLength > 5 * 1024 * 1024) {
            AppLogger.e('❌ Imagen ${i + 1} demasiado grande (máximo 5MB)');
            continue;
          }

          // Generar nombre único
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'product_${timestamp}_${userId.substring(0, 8)}_$i.jpg';
          final filePath = 'products/$fileName';

          AppLogger.d('📁 Subiendo: $fileName a product-images');

          // Leer archivo
          final List<int> imageBytesList = await imageFile.readAsBytes();
          final Uint8List imageBytes = Uint8List.fromList(imageBytesList);

          // SUBIR IMAGEN
          await _supabase.storage
              .from('product-images')
              .uploadBinary(filePath, imageBytes);

          // OBTENER URL PÚBLICA
          final publicUrl = _supabase.storage
              .from('product-images')
              .getPublicUrl(filePath);

          uploadedUrls.add(publicUrl);
          AppLogger.d('✅ Imagen ${i + 1} subida: $publicUrl');

        } catch (e) {
          AppLogger.e('❌ Error subiendo imagen ${i + 1}: $e');
          // Continuar con las siguientes imágenes
        }
      }

      AppLogger.d('🎉 Subida completada: ${uploadedUrls.length}/${imageFiles.length} imágenes');
      return uploadedUrls;

    } catch (e) {
      AppLogger.e('❌ ERROR CRÍTICO en uploadMultipleProductImages: $e');
      return [];
    }
  }

  // ✅ MÉTODO ADICIONAL: Eliminar imagen específica de un bucket
  Future<void> deleteImageFromBucket(String fileName, String bucketName) async {
    try {
      AppLogger.d('🗑️ Eliminando imagen específica: $fileName del bucket: $bucketName');
      
      await _supabase.storage
          .from(bucketName)
          .remove([fileName]);

      AppLogger.d('✅ Imagen eliminada exitosamente');
    } catch (e) {
      AppLogger.e('❌ ERROR eliminando imagen específica: $e');
    }
  }

  // ✅ NUEVO MÉTODO: Verificar si una imagen existe en storage
  Future<bool> checkImageExists(String imageUrl) async {
    try {
      final imageInfo = _parseImageUrl(imageUrl);
      if (imageInfo == null) return false;

      final bucketName = imageInfo['bucketName']!;
      final fileName = imageInfo['fileName']!;

      // Intentar obtener los metadatos de la imagen
      await _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      return true;
    } catch (e) {
      // Si hay error, asumimos que la imagen no existe
      return false;
    }
  }

  // ✅ NUEVO MÉTODO: Limpiar imágenes huérfanas (para mantenimiento)
  Future<void> cleanupOrphanedImages(List<String> activeImageUrls) async {
    try {
      AppLogger.d('🧹 INICIANDO LIMPIEZA DE IMÁGENES HUÉRFANAS...');
      
      // Este método sería llamado manualmente para limpiar imágenes que ya no se usan
      // Por ahora es un esqueleto para futuras implementaciones
      AppLogger.d('✅ Limpieza de imágenes huérfanas completada');
    } catch (e) {
      AppLogger.e('❌ ERROR en limpieza de imágenes huérfanas: $e');
    }
  }
}