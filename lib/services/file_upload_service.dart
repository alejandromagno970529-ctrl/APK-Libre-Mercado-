// lib/services/file_upload_service.dart - VERSIÓN CORREGIDA
import 'dart:io';
// ✅ AGREGAR ESTA IMPORTACIÓN
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:libre_mercado_final__app/services/image_upload_service.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class FileUploadService {
  final ImageUploadService _uploadService;

  FileUploadService(this._uploadService);

  // Método para seleccionar archivos
  Future<List<PlatformFile>?> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt', 'mp3', 'm4a', 'mp4'],
      );

      if (result != null) {
        AppLogger.d('📁 Archivos seleccionados: ${result.files.length}');
        return result.files;
      }
      return null;
    } catch (e) {
      AppLogger.e('Error al seleccionar archivos', e);
      rethrow;
    }
  }

  // ✅ MÉTODO CORREGIDO: Subir archivo individual
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

      if (fileLength > 10 * 1024 * 1024) {
        AppLogger.e('❌ Archivo demasiado grande (máximo 10MB)');
        throw Exception('Archivo demasiado grande (máximo 10MB)');
      }

      // ✅ CORRECCIÓN: Usar el método uploadFile de ImageUploadService en lugar de acceder directamente a _supabase
      AppLogger.d('🔄 Usando ImageUploadService para subir archivo...');
      
      final publicUrl = await _uploadService.uploadFile(file, userId);
      
      AppLogger.d('✅ Archivo subido exitosamente: $publicUrl');
      return publicUrl;

    } catch (e) {
      AppLogger.e('❌ ERROR subiendo archivo: $e');
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
        AppLogger.e('Error subiendo archivo ${file.name}', e);
      }
    }
    
    return uploadedUrls;
  }

  // ✅ ELIMINADO: Método de compatibilidad innecesario ya que ImageUploadService tiene uploadFile

  // Verificar permisos de almacenamiento
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Verificar permisos de micrófono (si necesitas audio en el futuro)
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}