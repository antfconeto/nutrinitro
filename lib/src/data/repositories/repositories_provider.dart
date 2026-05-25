import 'package:nutrinitro/src/core/database/database_client.dart';
import 'package:nutrinitro/src/data/repositories/analysis/analysis_repository.dart';
import 'package:nutrinitro/src/data/repositories/crop/crop_repository.dart';
import 'package:nutrinitro/src/data/repositories/image/image_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repositories_provider.g.dart';

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
Future<AnalysisRepository> analysisRepository(Ref ref) async {
  final db     = await ref.watch(databaseClientProvider.future);
  final images = await ref.watch(imageRepositoryProvider.future);
  final crops  = await ref.watch(cropRepositoryProvider.future);
  return AnalysisRepository(db, images, crops);
}