import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:sqflite/sqflite.dart';

class AnalysisRecipeRepository {
  final Database _db;

  AnalysisRecipeRepository(this._db);

  Future<Result<AnalysisRecipe?>> findById(String id) async {
    try {
      final rows = await _db.query(
        'analysis_recipes',
        where: 'id = ? AND is_active = 1',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return Success(null);
      return Success(AnalysisRecipeRecord.fromMap(rows.first).toRecipe());
    } catch (e) {
      return Failure(Exception('Error fetching recipe $id: $e'));
    }
  }

  Future<Result<List<AnalysisRecipe>>> findAllByCropId(int cropId) async {
    try {
      final rows = await _db.rawQuery('''
        SELECT r.*
        FROM analysis_recipes r
        INNER JOIN crop_recipe_bindings b ON b.recipe_id = r.id
        WHERE b.crop_id = ? AND r.is_active = 1
        ORDER BY b.is_default DESC, r.name ASC
      ''', [cropId]);

      return Success(
        rows.map((row) => AnalysisRecipeRecord.fromMap(row).toRecipe()).toList(),
      );
    } catch (e) {
      return Failure(Exception('Error fetching recipes for crop $cropId: $e'));
    }
  }

  Future<Result<AnalysisRecipe?>> findDefaultByCropId(int cropId) async {
    try {
      final rows = await _db.rawQuery('''
        SELECT r.*
        FROM analysis_recipes r
        INNER JOIN crop_recipe_bindings b ON b.recipe_id = r.id
        WHERE b.crop_id = ? AND r.is_active = 1
        ORDER BY b.is_default DESC
        LIMIT 1
      ''', [cropId]);

      if (rows.isEmpty) return Success(null);
      return Success(AnalysisRecipeRecord.fromMap(rows.first).toRecipe());
    } catch (e) {
      return Failure(Exception('Error fetching recipe for crop $cropId: $e'));
    }
  }

  Future<Result<List<String>>> findCropNamesWithRecipes() async {
    try {
      final rows = await _db.rawQuery('''
        SELECT DISTINCT c.name
        FROM crops c
        INNER JOIN crop_recipe_bindings b ON b.crop_id = c.id
        INNER JOIN analysis_recipes r ON r.id = b.recipe_id
        WHERE r.is_active = 1
        ORDER BY c.name ASC
      ''');
      return Success(rows.map((row) => row['name'] as String).toList());
    } catch (e) {
      return Failure(Exception('Error fetching crops with recipes: $e'));
    }
  }

  Future<Result<bool>> cropHasRecipe(int cropId) async {
    try {
      final count = Sqflite.firstIntValue(await _db.rawQuery('''
        SELECT COUNT(*) FROM crop_recipe_bindings b
        INNER JOIN analysis_recipes r ON r.id = b.recipe_id
        WHERE b.crop_id = ? AND r.is_active = 1
      ''', [cropId]));
      return Success((count ?? 0) > 0);
    } catch (e) {
      return Failure(Exception('Error checking recipe binding for crop $cropId: $e'));
    }
  }

  Future<void> upsert(AnalysisRecipe recipe) async {
    final record = AnalysisRecipeRecord.fromRecipe(recipe);
    await _db.insert(
      'analysis_recipes',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> bindCropToRecipe({
    required int cropId,
    required String recipeId,
    bool isDefault = true,
  }) async {
    await _db.insert(
      'crop_recipe_bindings',
      {
        'crop_id': cropId,
        'recipe_id': recipeId,
        'is_default': isDefault ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getStoredVersion(String id) async {
    final rows = await _db.query(
      'analysis_recipes',
      columns: ['version'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['version'] as String?;
  }

  Future<List<AnalysisRecipeRecord>> allActive() async {
    final rows = await _db.query(
      'analysis_recipes',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return rows.map(AnalysisRecipeRecord.fromMap).toList();
  }
}
