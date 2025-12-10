// lib/services/image_compression_service.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

class ImageCompressionService {
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;
  static const int quality = 85;

  /// Comprimir imagen antes de subir
  Future<File?> compressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      AppLogger.d('🗜️ Comprimiendo imagen: ${imageFile.path}');
      AppLogger.d('   Tamaño original: ${await imageFile.length()} bytes');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (result == null) {
        AppLogger.e('❌ Error: No se pudo comprimir la imagen');
        return null;
      }

      final compressedFile = File(result.path);
      AppLogger.d('✅ Imagen comprimida exitosamente');
      AppLogger.d('   Tamaño final: ${await compressedFile.length()} bytes');
      
      return compressedFile;
      
    } catch (e) {
      AppLogger.e('❌ Error comprimiendo imagen: $e');
      return null;
    }
  }

  /// Verificar si una imagen necesita compresión
  Future<bool> needsCompression(File imageFile) async {
    try {
      final size = await imageFile.length();
      // Comprimir si es mayor a 1MB
      return size > 1024 * 1024;
    } catch (e) {
      return false;
    }
  }
}