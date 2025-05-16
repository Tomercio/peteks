import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageService {
  static const String _imagePrefix = 'note_image_';
  static final ImagePicker _picker = ImagePicker();
  static Directory? _imagesDir;

  // Initialize the service
  static Future<void> init() async {
    await _getImagesDirectory();
  }

  // Get the directory path for storing images
  static Future<Directory?> _getImagesDirectory() async {
    if (_imagesDir != null) return _imagesDir;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/note_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      _imagesDir = imagesDir;
      return _imagesDir;
    } catch (e) {
      return null;
    }
  }

  // Pick an image from the gallery
  static Future<String?> pickImageFromGallery() async {
    if (kIsWeb) {
      // Web: Not supported
      return null;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _saveImage(File(pickedFile.path));
    } catch (e) {
      return null;
    }
  }

  // Take a photo using the camera
  static Future<String?> takePhoto() async {
    if (kIsWeb) {
      // Web: Not supported
      return null;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _saveImage(File(pickedFile.path));
    } catch (e) {
      return null;
    }
  }

  // Save image to app directory
  static Future<String?> _saveImage(File imageFile) async {
    try {
      final imagesDir = await _getImagesDirectory();
      if (imagesDir == null) return null;

      final fileName =
          _imagePrefix + const Uuid().v4() + path.extension(imageFile.path);
      final savedFile = await imageFile.copy('${imagesDir.path}/$fileName');

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  // Check if image exists
  static bool imageExists(String imagePath) {
    try {
      final file = File(imagePath);
      return file.existsSync();
    } catch (e) {
      // Ignored: If an error occurs, assume the image does not exist.
      return false;
    }
  }

  // Delete an image
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      // Ignored: If an error occurs, the image could not be deleted.
    }
  }

  // Delete all images of a note
  static Future<void> deleteAllNoteImages(List<String> imagePaths) async {
    for (final imagePath in imagePaths) {
      await deleteImage(imagePath);
    }
  }
}
