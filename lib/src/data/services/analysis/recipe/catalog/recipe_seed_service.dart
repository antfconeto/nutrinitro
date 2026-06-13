import 'package:flutter/services.dart' show rootBundle;
import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:sqflite/sqflite.dart';

class RecipeSeedService {
  static const List<String> bundledRecipeAssets = [
    'assets/recipes/marandu_nutrients_v1.json',
  ];

  static const Map<String, String> defaultCropBindings = {
    'Capim Marandu': 'marandu_nutrients_v1',
  };

  static const String maranduCropAnalysisDataJson =
      '{"schema_version":1,"default_recipe_id":"marandu_nutrients_v1"}';

  final AnalysisRecipeRepository _repository;

  RecipeSeedService(this._repository);

  Future<void> seedFromAssets() async {
    for (final assetPath in bundledRecipeAssets) {
      final jsonString = await rootBundle.loadString(assetPath);
      final recipe = AnalysisRecipe.fromJsonString(jsonString);
      final storedVersion = await _repository.getStoredVersion(recipe.id);

      if (storedVersion == null || _isNewerVersion(recipe.version, storedVersion)) {
        await _repository.upsert(recipe);
      }
    }
  }

  Future<void> seedCropBindings(Database db) async {
    for (final entry in defaultCropBindings.entries) {
      final cropRows = await db.query(
        'crops',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      if (cropRows.isEmpty) continue;

      final cropId = cropRows.first['id'] as int;
      await _repository.bindCropToRecipe(
        cropId: cropId,
        recipeId: entry.value,
      );

      if (entry.key == 'Capim Marandu') {
        await db.update(
          'crops',
          {'analysis_data_json': maranduCropAnalysisDataJson},
          where: 'id = ?',
          whereArgs: [cropId],
        );
      }
    }
  }

  bool _isNewerVersion(String incoming, String stored) {
    final incomingParts = incoming.split('.').map(int.parse).toList();
    final storedParts = stored.split('.').map(int.parse).toList();
    final length = incomingParts.length > storedParts.length
        ? incomingParts.length
        : storedParts.length;

    for (int i = 0; i < length; i++) {
      final a = i < incomingParts.length ? incomingParts[i] : 0;
      final b = i < storedParts.length ? storedParts[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }
}
