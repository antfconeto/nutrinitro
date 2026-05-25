import 'package:nutrinitro/src/data/services/analysis/analysis_service.dart';
import 'package:nutrinitro/src/data/services/camera/camera_service.dart';
import 'package:nutrinitro/src/data/services/camera/exif_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services_provider.g.dart';

@riverpod
ExifService exifService(Ref ref) {
  return ExifService();
}

@riverpod
AnalysisService analysisService(Ref ref) {
  return AnalysisService();
}

@riverpod
CameraService cameraService(Ref ref) {
  return CameraService();
}

