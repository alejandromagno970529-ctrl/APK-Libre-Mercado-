import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ServiceImageUploader {
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    final supabase = Supabase.instance.client;
    final uploadedUrls = <String>[];

    for (final imageFile in imageFiles) {
      try {
        final file = File(imageFile.path);
        final fileBytes = await file.readAsBytes();
        final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        
        // Subir a Supabase Storage
        await supabase.storage
            .from('services')
            .upload(fileName, fileBytes as File);
        
        // Obtener URL pública
        final publicUrl = supabase.storage
            .from('services')
            .getPublicUrl(fileName);
        
        uploadedUrls.add(publicUrl);
      } catch (error) {
        // ignore: avoid_print
        print('Error uploading image: $error');
        // Continuar con las siguientes imágenes
      }
    }

    return uploadedUrls;
  }

  static Future<String> uploadSingleImage(XFile imageFile) async {
    final supabase = Supabase.instance.client;
    
    try {
      final file = File(imageFile.path);
      final fileBytes = await file.readAsBytes();
      final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      // Subir a Supabase Storage
      await supabase.storage
          .from('services')
          .upload(fileName, fileBytes as File);
      
      // Obtener URL pública
      final publicUrl = supabase.storage
          .from('services')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (error) {
      // ignore: avoid_print
      print('Error uploading image: $error');
      rethrow;
    }
  }
}