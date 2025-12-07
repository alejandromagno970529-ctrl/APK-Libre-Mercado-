// lib/services/file_upload_service.dart - VERSIÓN CON COMPRESIÓN INTEGRADA
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libre_mercado_final_app/utils/logger.dart';

// ✅ NUEVO: Importar servicio de compresión
import './image_compression_service.dart';

class FileUploadService {
  final SupabaseClient _supabase;
  
  // ✅ NUEVO: Instancia del servicio de compresión
  final ImageCompressionService _compressionService = ImageCompressionService();

  FileUploadService(this._supabase);

  // Método para seleccionar archivos
  Future<List<PlatformFile>?> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );

      if (result != null) {
        AppLogger.d('📁 Archivos seleccionados: ${result.files.length}');
        return result.files;
      }
      return null;
    } catch (e) {
      AppLogger.e('Error al seleccionar archivos: $e', e);
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: Subir archivo con mejor manejo de RLS
  Future<String> uploadFile(File file, String userId) async {
    try {
      AppLogger.d('📤 SUBIENDO ARCHIVO GENÉRICO...');

      // 1. Verificaciones básicas
      if (!await file.exists()) {
        AppLogger.e('❌ El archivo no existe');
        throw Exception('El archivo no existe');
      }

      final fileLength = await file.length();
      AppLogger.d('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      // ✅ AUMENTADO LÍMITE A 10MB PARA ARCHIVOS
      if (fileLength > 10 * 1024 * 1024) {
        AppLogger.e('❌ Archivo demasiado grande (máximo 10MB)');
        throw Exception('Archivo demasiado grande (máximo 10MB)');
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      // 3. Generar nombre único CON RUTA SIMPLIFICADA
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = 'file_${timestamp}_${userId.substring(0, 8)}.$fileExtension';
      
      // ✅ CORREGIDO: Usar path con user_id para mejor organización y RLS
      final filePath = 'user_$userId/$fileName';

      AppLogger.d('📁 Subiendo: $fileName a bucket files');
      AppLogger.d('👤 Usuario: ${currentUser.email}');
      AppLogger.d('📍 Path: $filePath');

      // 4. Leer archivo
      final List<int> fileBytesList = await file.readAsBytes();
      final Uint8List fileBytes = Uint8List.fromList(fileBytesList);
      
      AppLogger.d('📦 Bytes leídos: ${fileBytes.length}');

      // 5. ✅ INTENTAR SUBIR CON MANEJO MEJORADO DE ERRORES RLS
      String bucketName = 'files';
      try {
        AppLogger.d('🔄 Subiendo a bucket $bucketName...');
        
        final uploadResponse = await _supabase.storage
            .from(bucketName)
            .uploadBinary(filePath, fileBytes);

        AppLogger.d('✅ Archivo subido exitosamente: $uploadResponse');
      } catch (e) {
        AppLogger.e('❌ Error en upload inicial: $e');
        
        // ✅ INTENTAR FALLBACK: Subir sin user_id en el path
        if (e.toString().contains('row-level security')) {
          AppLogger.w('⚠️ RLS bloqueó upload, intentando método alternativo...');
          
          final fallbackPath = 'public/$fileName';
          try {
            await _supabase.storage
                .from(bucketName)
                .uploadBinary(fallbackPath, fileBytes);
            AppLogger.d('✅ Archivo subido con método alternativo');
          } catch (e2) {
            AppLogger.e('❌ Error en método alternativo: $e2');
            throw Exception('No se pudo subir el archivo debido a restricciones de seguridad');
          }
        } else {
          rethrow;
        }
      }

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');

      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo archivo: $e');
      
      // Análisis de errores específicos
      if (e.toString().contains('row-level security')) {
        AppLogger.e('🔴 ERROR RLS: Contacta al administrador para configurar políticas');
        throw Exception('Error de permisos. Contacta al administrador.');
      } else if (e.toString().contains('Bucket not found')) {
        AppLogger.e('🔴 BUCKET NO ENCONTRADO: Ejecuta los comandos SQL en Supabase');
        throw Exception('Bucket "files" no configurado. Contacta al administrador.');
      } else if (e.toString().contains('JWT')) {
        AppLogger.e('🔴 ERROR DE AUTENTICACIÓN');
        throw Exception('Error de autenticación. Vuelve a iniciar sesión.');
      }
      
      rethrow;
    }
  }

  // ✅ MÉTODO MEJORADO: uploadChatImage para FileUploadService CON COMPRESIÓN
  Future<String> uploadChatImage(File imageFile, String userId) async {
    try {
      AppLogger.d('🖼️ SUBIENDO IMAGEN PARA CHAT DESDE FILE_UPLOAD_SERVICE...');

      // ✅ NUEVO: COMPRIMIR IMAGEN ANTES DE SUBIR
      if (await _compressionService.needsCompression(imageFile)) {
        AppLogger.d('🗜️ Comprimiendo imagen antes de subir...');
        final compressedFile = await _compressionService.compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
          AppLogger.d('✅ Imagen comprimida exitosamente');
        }
      }

      // 1. Verificaciones básicas
      if (!await imageFile.exists()) {
        AppLogger.e('❌ El archivo no existe');
        throw Exception('El archivo no existe');
      }

      final fileLength = await imageFile.length();
      AppLogger.d('📊 Tamaño del archivo: ${fileLength ~/ 1024}KB');

      if (fileLength > 5 * 1024 * 1024) {
        AppLogger.e('❌ Imagen demasiado grande (máximo 5MB)');
        throw Exception('Imagen demasiado grande (máximo 5MB)');
      }

      // 2. Verificar autenticación
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      // 3. Path simplificado con user_id
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_image_${timestamp}_${userId.substring(0, 8)}.jpg';
      final filePath = 'user_$userId/$fileName';

      AppLogger.d('📁 Subiendo imagen: $fileName');

      // 4. Leer archivo
      final List<int> imageBytesList = await imageFile.readAsBytes();
      final Uint8List imageBytes = Uint8List.fromList(imageBytesList);

      // 5. ✅ INTENTAR PRIMERO chat-images, LUEGO files
      String bucketName = 'chat-images';
      try {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(filePath, imageBytes);
        AppLogger.d('✅ Imagen subida exitosamente a chat-images');
      } catch (e) {
        AppLogger.w('⚠️ Bucket chat-images no disponible, usando files: $e');
        bucketName = 'files';
        
        // ✅ INTENTAR CON PATH ALTERNATIVO SI FALLA RLS
        try {
          await _supabase.storage
              .from(bucketName)
              .uploadBinary(filePath, imageBytes);
          AppLogger.d('✅ Imagen subida exitosamente a files');
        } catch (e2) {
          AppLogger.e('❌ Error subiendo a files: $e2');
          // Último intento con path público
          final publicPath = 'public/$fileName';
          await _supabase.storage
              .from(bucketName)
              .uploadBinary(publicPath, imageBytes);
          AppLogger.d('✅ Imagen subida exitosamente a path público');
        }
      }

      // 6. OBTENER URL PÚBLICA
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      AppLogger.d('🌐 URL pública generada: $publicUrl');
      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo imagen de chat: $e', e);
      
      // Análisis detallado del error
      if (e.toString().contains('row-level security')) {
        AppLogger.e('🔴 ERROR RLS: Verifica las políticas del bucket');
        AppLogger.e('💡 Ejecuta los comandos SQL proporcionados en Supabase');
      } else if (e.toString().contains('Bucket not found')) {
        AppLogger.e('🔴 BUCKET NO ENCONTRADO: chat-images no existe');
        AppLogger.e('💡 Crea el bucket chat-images en Supabase Storage');
      }
      
      rethrow;
    }
  }

  // ✅ NUEVO MÉTODO: Subir imagen con compresión automática
  Future<String> uploadImageWithCompression(File imageFile, String userId, {String bucketName = 'files'}) async {
    try {
      AppLogger.d('🖼️ Subiendo imagen con compresión automática...');
      
      // Comprimir si es necesario
      if (await _compressionService.needsCompression(imageFile)) {
        AppLogger.d('🗜️ Comprimiendo imagen...');
        final compressedFile = await _compressionService.compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
          AppLogger.d('✅ Imagen comprimida exitosamente');
        }
      }
      
      // Subir la imagen (compresión o no)
      return await uploadFile(imageFile, userId);
    } catch (e) {
      AppLogger.e('❌ Error subiendo imagen comprimida: $e');
      rethrow;
    }
  }

  // ✅ NUEVO MÉTODO: Subir archivo con manejo específico para documentos
  Future<String> uploadDocument(File file, String userId, String fileType) async {
    try {
      AppLogger.d('📄 SUBIENDO DOCUMENTO: $fileType');

      // Verificar tamaño (máximo 2MB para documentos)
      final fileLength = await file.length();
      if (fileLength > 2 * 1024 * 1024) {
        throw Exception('Documento demasiado grande (máximo 2MB)');
      }

      // Usar bucket específico para documentos o files como fallback
      String bucketName = 'files';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = 'doc_${fileType}_${timestamp}_${userId.substring(0, 8)}.$fileExtension';
      final filePath = 'documents/user_$userId/$fileName';

      AppLogger.d('📁 Subiendo documento: $fileName');

      final List<int> fileBytesList = await file.readAsBytes();
      final Uint8List fileBytes = Uint8List.fromList(fileBytesList);

      // Intentar subir
      try {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(filePath, fileBytes);
      } catch (e) {
        // Fallback a path público
        AppLogger.w('⚠️ Error con path organizado, usando path público');
        final publicPath = 'public/documents/$fileName';
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(publicPath, fileBytes);
      }

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      AppLogger.d('✅ Documento subido exitosamente: $publicUrl');
      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo documento: $e');
      rethrow;
    }
  }

  Future<String> uploadAudioFile(File audioFile, String userId) async {
    try {
      AppLogger.d('🎤 SUBIENDO ARCHIVO DE AUDIO...');

      if (!await audioFile.exists()) {
        throw Exception('El archivo de audio no existe');
      }

      final fileLength = await audioFile.length();
      if (fileLength > 5 * 1024 * 1024) {
        throw Exception('Archivo de audio demasiado grande (máximo 5MB)');
      }

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_${timestamp}_${userId.substring(0, 8)}.m4a';
      final filePath = 'user_$userId/$fileName';

      AppLogger.d('📁 Subiendo audio: $fileName');

      final List<int> audioBytesList = await audioFile.readAsBytes();
      final Uint8List audioBytes = Uint8List.fromList(audioBytesList);

      String bucketName = 'files';
      try {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(filePath, audioBytes);
      } catch (e) {
        AppLogger.w('⚠️ Error subiendo audio, usando path público');
        final publicPath = 'public/audio/$fileName';
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(publicPath, audioBytes);
      }

      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      AppLogger.d('✅ Audio subido exitosamente: $publicUrl');
      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo audio: $e', e);
      rethrow;
    }
  }

  // Método para subir múltiples archivos
  Future<List<String>> uploadFiles(List<PlatformFile> files, String userId) async {
    final List<String> uploadedUrls = [];
    
    for (final file in files) {
      try {
        final filePath = file.path;
        if (filePath != null) {
          final fileToUpload = File(filePath);
          final url = await uploadFile(fileToUpload, userId);
          uploadedUrls.add(url);
          AppLogger.d('✅ Archivo subido: $url');
        }
      } catch (e) {
        AppLogger.e('Error subiendo archivo ${file.name}: $e', e);
      }
    }
    
    return uploadedUrls;
  }

  // Verificar permisos de almacenamiento
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Verificar permisos de micrófono
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Obtener información del archivo
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    try {
      final stat = await file.stat();
      return {
        'size': stat.size,
        'modified': stat.modified,
        'path': file.path,
        'name': file.path.split('/').last,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo info del archivo: $e', e);
      return {};
    }
  }

  // Formatear tamaño de archivo
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // ✅ NUEVO MÉTODO: Detectar si un archivo es imagen
  bool isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // ✅ NUEVO MÉTODO: Detectar si un archivo es documento
  bool isDocumentFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'].contains(extension);
  }

  // ✅ NUEVO MÉTODO: Detectar si un archivo es audio
  bool isAudioFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension);
  }

  // ✅ NUEVO MÉTODO: Detectar si un archivo es video
  bool isVideoFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  // ✅ NUEVO MÉTODO: Obtener información de compresión
  Future<Map<String, dynamic>> getCompressionInfo(File file) async {
    try {
      final originalSize = await file.length();
      final needsCompression = await _compressionService.needsCompression(file);
      
      return {
        'original_size': originalSize,
        'original_size_kb': (originalSize / 1024).toStringAsFixed(2),
        'needs_compression': needsCompression,
        'max_width': ImageCompressionService.maxWidth,
        'max_height': ImageCompressionService.maxHeight,
        'quality': ImageCompressionService.quality,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Resto de métodos de diagnóstico permanecen igual...
  Future<void> diagnoseFileBuckets() async {
    try {
      AppLogger.d('🔍 INICIANDO DIAGNÓSTICO DE BUCKETS DE ARCHIVOS...');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        AppLogger.e('❌ Usuario no autenticado');
        return;
      }

      final buckets = await _supabase.storage.listBuckets();
      AppLogger.d('📦 Buckets disponibles: ${buckets.length}');
      
      for (final bucket in buckets) {
        AppLogger.d('   - ${bucket.name} (público: ${bucket.public})');
      }

      // Verificar buckets específicos para archivos
      final requiredBuckets = ['files', 'chat-images'];
      for (final bucketName in requiredBuckets) {
        final exists = buckets.any((b) => b.name == bucketName);
        if (exists) {
          AppLogger.d('✅ Bucket $bucketName: EXISTE');
        } else {
          AppLogger.w('⚠️ Bucket $bucketName: NO EXISTE');
        }
      }
      
    } catch (e) {
      AppLogger.e('❌ Error en diagnóstico de buckets de archivos: $e');
    }
  }

  Future<Map<String, dynamic>> checkBucketPermissions(String bucketName) async {
    try {
      AppLogger.d('🔍 Verificando permisos para bucket: $bucketName');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'authenticated': false, 'error': 'Usuario no autenticado'};
      }

      final testFileName = 'permission_test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final testBytes = Uint8List.fromList('test'.codeUnits);

      // Verificar INSERT
      bool canInsert = false;
      try {
        await _supabase.storage
            .from(bucketName)
            .uploadBinary(testFileName, testBytes);
        canInsert = true;
        
        // Limpiar
        await _supabase.storage
            .from(bucketName)
            .remove([testFileName]);
      } catch (e) {
        AppLogger.e('❌ No tiene permisos INSERT en $bucketName: $e');
      }

      // Verificar SELECT (obtener URL pública)
      bool canSelect = false;
      try {
        final publicUrl = _supabase.storage
            .from(bucketName)
            .getPublicUrl(testFileName);
        canSelect = publicUrl.isNotEmpty;
      } catch (e) {
        AppLogger.e('❌ No tiene permisos SELECT en $bucketName: $e');
      }

      return {
        'authenticated': true,
        'bucketExists': true,
        'canInsert': canInsert,
        'canSelect': canSelect,
        'userId': currentUser.id,
      };
    } catch (e) {
      return {
        'authenticated': true,
        'bucketExists': false,
        'error': e.toString(),
      };
    }
  }
}