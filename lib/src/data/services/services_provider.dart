import 'package:nutrinitro/src/data/services/analysis/analysis_service.dart';
import 'package:nutrinitro/src/data/services/camera/camera_service.dart';
import 'package:nutrinitro/src/data/services/camera/exif_service.dart';
import 'package:nutrinitro/src/data/services/camera/image_cropper_service.dart';
import 'package:nutrinitro/src/data/services/storage/storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services_provider.g.dart';

// Analysis

@riverpod
AnalysisService analysisService(Ref ref) {
  return AnalysisService();
}

// Camera

@riverpod
ExifService exifService(Ref ref) {
  return ExifService();
}

@riverpod
CameraService cameraService(Ref ref) {
  return CameraService();
}

@riverpod
ImageCropperService imageCropperService(Ref ref) {
  return ImageCropperService();
}

// Storage

@riverpod
StorageService storageService(Ref ref) {
  return StorageService();
}
