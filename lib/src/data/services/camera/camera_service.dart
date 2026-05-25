import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Picks a single image from the camera at full quality
  Future<File?> pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      rethrow;
    }
  }

  /// Picks multiple images from the gallery at full quality
  Future<List<File>> pickMultipleFromGallery() async {
    try {
      final photos = await _picker.pickMultiImage();
      return photos.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Picks a single image from the gallery at full quality
  Future<File?> pickFromGallery() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      rethrow;
    }
  }
}