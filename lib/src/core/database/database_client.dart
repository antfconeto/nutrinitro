import 'package:nutrinitro/src/data/repositories/recipe/analysis_recipe_repository.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/recipe_seed_service.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'database_client.g.dart';

@Riverpod(keepAlive: true)
Future<Database> databaseClient(Ref ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'nutrinitro.db');

  final db = await openDatabase(
    path,
    version: 3,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  await _seedRecipesIfNeeded(db);
  return db;
}

Future<void> _seedRecipesIfNeeded(Database db) async {
  final repository = AnalysisRecipeRepository(db);
  final seedService = RecipeSeedService(repository);
  await seedService.seedFromAssets();
  await seedService.seedCropBindings(db);
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    try {
      await db.execute(
        'ALTER TABLE analyses ADD COLUMN analysis_type TEXT NOT NULL DEFAULT "agronomic"',
      );
    } catch (_) {}

    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM crops WHERE name = ?",
      ['Capim Marandu'],
    )) ?? 0;

    if (count == 0) {
      await db.insert('crops', {
        'name': 'Capim Marandu',
        'icon': 'assets/images/crops/grass.png',
        'analysis_data_json': RecipeSeedService.maranduCropAnalysisDataJson,
      });
    }
  }

  if (oldVersion < 3) {
    await _createRecipeTables(db);
    await db.update(
      'crops',
      {'analysis_data_json': RecipeSeedService.maranduCropAnalysisDataJson},
      where: 'name = ?',
      whereArgs: ['Capim Marandu'],
    );
  }
}

Future<void> _createRecipeTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS analysis_recipes (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      version     TEXT NOT NULL,
      targets     TEXT NOT NULL,
      recipe_json TEXT NOT NULL,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS crop_recipe_bindings (
      crop_id    INTEGER NOT NULL,
      recipe_id  TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (crop_id, recipe_id),
      FOREIGN KEY (crop_id) REFERENCES crops(id),
      FOREIGN KEY (recipe_id) REFERENCES analysis_recipes(id)
    )
  ''');
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE crops (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      name               VARCHAR NOT NULL,
      icon               TEXT NOT NULL,
      analysis_data_json TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE analyses (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      title         VARCHAR NOT NULL,
      datetime      TIMESTAMP NOT NULL,
      notes         TEXT,
      crop_id       INTEGER NOT NULL,
      status        VARCHAR NOT NULL DEFAULT 'pending',
      analysis_type TEXT NOT NULL DEFAULT 'agronomic',
      FOREIGN KEY (crop_id) REFERENCES crops(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE images (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      analysis_id    INTEGER NOT NULL,
      original_path  TEXT NOT NULL,
      analyzed_path  TEXT,
      result         TEXT,
      latitude       REAL,
      longitude      REAL,
      datetime       TIMESTAMP,
      display_order  INTEGER NOT NULL,
      FOREIGN KEY (analysis_id) REFERENCES analyses(id)
    )
  ''');

  await _createRecipeTables(db);
  await _seedCrops(db);
}

Future<void> _seedCrops(Database db) async {
  final crops = [
    {
      'name': 'Milho',
      'icon': 'assets/images/crops/corn.png',
      'analysis_data_json':
          '{"crop":"corn","parameters":{"moisture":14,"protein":8}}',
    },
    {
      'name': 'Feijao',
      'icon': 'assets/images/crops/soybean.png',
      'analysis_data_json':
          '{"crop":"soybean","parameters":{"moisture":13,"protein":36}}',
    },
    {
      'name': 'Capim Marandu',
      'icon': 'assets/images/crops/grass.png',
      'analysis_data_json': RecipeSeedService.maranduCropAnalysisDataJson,
    },
  ];

  for (final crop in crops) {
    await db.insert('crops', crop);
  }
}
