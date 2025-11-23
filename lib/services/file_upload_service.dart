import 'dart:io';
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
        allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
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

  // Método para subir archivos
  Future<List<String>> uploadFiles(List<PlatformFile> files, String userId) async {
    final List<String> uploadedUrls = [];
    
    for (final file in files) {
      try {
        final filePath = file.path;
        if (filePath != null) {
          final fileToUpload = File(filePath);
          // Intentamos usar uploadFile, si no existe, usamos uploadImage
          final url = await _uploadFileCompat(fileToUpload, userId);
          uploadedUrls.add(url);
          AppLogger.d('✅ Archivo subido: $url');
        }
      } catch (e) {
        AppLogger.e('Error subiendo archivo ${file.name}', e);
      }
    }
    
    return uploadedUrls;
  }

  // Método de compatibilidad - intenta usar uploadFile, si no existe, usa uploadImage
  Future<String> _uploadFileCompat(File file, String userId) async {
    try {
      // Si el método uploadFile existe en ImageUploadService, lo usamos
      return await _uploadService.uploadFile(file, userId);
    } catch (e) {
      // Si no, usamos uploadImage (para imágenes)
      return await _uploadService.uploadImage(file, userId);
    }
  }

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