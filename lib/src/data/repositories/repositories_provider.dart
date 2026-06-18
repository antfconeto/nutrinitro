import 'package:nutrinitro/src/core/database/database_client.dart';
import 'package:nutrinitro/src/data/repositories/analysis/analysis_repository.dart';
import 'package:nutrinitro/src/data/repositories/crop/crop_repository.dart';
import 'package:nutrinitro/src/data/repositories/drone_image/drone_image_repository.dart';
import 'package:nutrinitro/src/data/repositories/image/image_repository.dart';
import 'package:nutrinitro/src/data/repositories/mission/mission_repository.dart';
import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:nutrinitro/src/data/repositories/waypoint/waypoint_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repositories_provider.g.dart';

@riverpod
Future<AnalysisRepository> analysisRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  final images = await ref.watch(imageRepositoryProvider.future);
  final crops = await ref.watch(cropRepositoryProvider.future);
  return AnalysisRepository(db, images, crops);
}

@riverpod
Future<CropRepository> cropRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  return CropRepository(db);
}

@riverpod
Future<ImageRepository> imageRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  return ImageRepository(db);
}

@riverpod
Future<AnalysisRecipeRepository> analysisRecipeRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  return AnalysisRecipeRepository(db);
}

@riverpod
Future<WaypointRepository> waypointRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  return WaypointRepository(db);
}

@riverpod
Future<MissionRepository> missionRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  final waypoints = await ref.watch(waypointRepositoryProvider.future);
  return MissionRepository(db, waypoints);
}

@riverpod
Future<DroneImageRepository> droneImageRepository(Ref ref) async {
  final db = await ref.watch(databaseClientProvider.future);
  return DroneImageRepository(db);
}
