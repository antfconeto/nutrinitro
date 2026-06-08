import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/validation/recipe_validator.dart';

class RecipeLoader {
  final AnalysisRecipeRepository _repository;
  final RecipeValidator _validator;
  final Map<String, AnalysisRecipe> _cache = {};

  RecipeLoader({
    required AnalysisRecipeRepository repository,
    RecipeValidator? validator,
  })  : _repository = repository,
        _validator = validator ?? const RecipeValidator();

  Future<AnalysisRecipe?> loadById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];

    final result = await _repository.findById(id);
    switch (result) {
      case Success(value: final recipe):
        if (recipe == null) return null;
        _validator.validate(recipe);
        _cache[id] = recipe;
        return recipe;
      case Failure():
        return null;
    }
  }

  Future<AnalysisRecipe?> loadByCropId(int cropId) async {
    final result = await _repository.findDefaultByCropId(cropId);
    switch (result) {
      case Success(value: final recipe):
        if (recipe == null) return null;
        _validator.validate(recipe);
        _cache[recipe.id] = recipe;
        return recipe;
      case Failure():
        return null;
    }
  }

  AnalysisRecipe parseFromPayload(String recipeJson) {
    final recipe = AnalysisRecipe.fromJsonString(recipeJson);
    _validator.validate(recipe);
    _cache[recipe.id] = recipe;
    return recipe;
  }

  void clearCache() => _cache.clear();
}
