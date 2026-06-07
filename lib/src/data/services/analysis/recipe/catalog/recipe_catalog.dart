import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_registry.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/crop_analysis_option.dart';

class RecipeCatalog {
  final AnalysisRecipeRepository _repository;
  List<String>? _cachedCropNames;

  RecipeCatalog(this._repository);

  Future<List<String>> cropNamesWithRecipes({bool forceRefresh = false}) async {
    if (_cachedCropNames != null && !forceRefresh) {
      return List.unmodifiable(_cachedCropNames!);
    }

    final result = await _repository.findCropNamesWithRecipes();
    switch (result) {
      case Success(value: final names):
        _cachedCropNames = names;
        return List.unmodifiable(names);
      case Failure():
        return const [];
    }
  }

  Future<bool> cropHasRecipe(int cropId) async {
    final result = await _repository.cropHasRecipe(cropId);
    switch (result) {
      case Success(value: final hasRecipe):
        return hasRecipe;
      case Failure():
        return false;
    }
  }

  Future<List<CropAnalysisOption>> analysesForCrop({
    required int cropId,
    String? cropName,
  }) async {
    final options = <CropAnalysisOption>[];

    final recipesResult = await _repository.findAllByCropId(cropId);
    switch (recipesResult) {
      case Success(value: final recipes):
        for (final recipe in recipes) {
          final analysis = AnalysisRegistry.getById('nitrogen');
          if (analysis == null) continue;

          options.add(CropAnalysisOption(
            analysisId: analysis.id,
            displayName: recipe.name,
            description: recipe.ui.description ?? analysis.description,
            recipeId: recipe.id,
            recipeVersion: recipe.version,
          ));
        }
      case Failure():
        break;
    }

    final agronomic = AnalysisRegistry.getById('agronomic');
    if (agronomic != null &&
        cropName != null &&
        agronomic.supportedCropNames.contains(cropName)) {
      options.add(CropAnalysisOption(
        analysisId: agronomic.id,
        displayName: agronomic.name,
        description: agronomic.description,
      ));
    }

    return options;
  }

  void invalidate() => _cachedCropNames = null;
}
