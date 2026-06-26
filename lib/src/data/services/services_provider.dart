import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_service.dart';
import 'package:nutrinitro/src/data/services/camera/camera_service.dart';
import 'package:nutrinitro/src/data/services/camera/exif_service.dart';
import 'package:nutrinitro/src/data/services/camera/image_cropper_service.dart';
import 'package:nutrinitro/src/data/services/drone/core/i_drone_service.dart';
import 'package:nutrinitro/src/data/services/drone/dji/dji_drone_service.dart';
import 'package:nutrinitro/src/data/services/drone/mock/mock_drone_service.dart';
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

// Drone

@Riverpod(keepAlive: true)
IDroneService droneService(Ref ref) {
  final service = Env.useMockDrone
      ? MockDroneService()
      : DjiDroneService(); 

  ref.onDispose(service.dispose);
  return service;
}
