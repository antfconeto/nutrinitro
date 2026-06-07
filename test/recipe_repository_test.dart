import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/recipe_loader.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/recipe_seed_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AnalysisRecipeRepository repository;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE crops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            analysis_data_json TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE analysis_recipes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            version TEXT NOT NULL,
            targets TEXT NOT NULL,
            recipe_json TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await database.execute('''
          CREATE TABLE crop_recipe_bindings (
            crop_id INTEGER NOT NULL,
            recipe_id TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (crop_id, recipe_id)
          )
        ''');
        await database.insert('crops', {
          'name': 'Capim Marandu',
          'icon': 'assets/images/crops/grass.png',
          'analysis_data_json': RecipeSeedService.maranduCropAnalysisDataJson,
        });
      },
    );
    repository = AnalysisRecipeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('seed from asset and load by crop id', () async {
    final assetJson = await rootBundle.loadString('assets/recipes/marandu_nutrients_v1.json');
    final recipe = AnalysisRecipe.fromJsonString(assetJson);

    await repository.upsert(recipe);
    await repository.bindCropToRecipe(cropId: 1, recipeId: recipe.id);

    final loader = RecipeLoader(repository: repository);
    final loaded = await loader.loadByCropId(1);

    expect(loaded, isNotNull);
    expect(loaded!.id, recipe.id);
    expect(loaded.predictions.length, recipe.predictions.length);
  });

  test('findCropNamesWithRecipes returns bound crop', () async {
    final assetJson = await rootBundle.loadString('assets/recipes/marandu_nutrients_v1.json');
    final recipe = AnalysisRecipe.fromJsonString(assetJson);
    await repository.upsert(recipe);
    await repository.bindCropToRecipe(cropId: 1, recipeId: recipe.id);

    final result = await repository.findCropNamesWithRecipes();
    switch (result) {
      case Success(value: final names):
        expect(names, contains('Capim Marandu'));
      case Failure(:final error):
        fail('Unexpected failure: $error');
    }
  });
}
