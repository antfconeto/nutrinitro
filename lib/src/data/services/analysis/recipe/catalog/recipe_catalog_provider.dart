import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/crop_analysis_option.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/recipe_catalog.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_catalog_provider.g.dart';

@riverpod
Future<RecipeCatalog> recipeCatalog(Ref ref) async {
  final repository = await ref.watch(analysisRecipeRepositoryProvider.future);
  return RecipeCatalog(repository);
}

@riverpod
Future<bool> cropHasRecipe(Ref ref, int cropId) async {
  final catalog = await ref.watch(recipeCatalogProvider.future);
  return catalog.cropHasRecipe(cropId);
}

@riverpod
Future<List<CropAnalysisOption>> cropRegisteredAnalyses(
  Ref ref, {
  required int cropId,
  String? cropName,
}) async {
  final catalog = await ref.watch(recipeCatalogProvider.future);
  return catalog.analysesForCrop(cropId: cropId, cropName: cropName);
}
