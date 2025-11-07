// lib/services/image_upload_service.dart - VERSIÓN COMPLETA CON PERFILES
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

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
      
      // DEBUG DETALLADO
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

  // ✅ MÉTODO EXISTENTE: Subir imagen de producto
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

  // ✅ MÉTODO EXISTENTE: Subir imagen de historia DESDE ARCHIVO
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

  // ✅ MÉTODO EXISTENTE: Subir imagen de historia DESDE BYTES
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
}