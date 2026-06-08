import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'database_client.g.dart';

@Riverpod(keepAlive: true)
Future<Database> databaseClient(Ref ref) async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'nutrinitro.db');

  return openDatabase(
    path,
    version: 2,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    try {
      await db.execute('ALTER TABLE analyses ADD COLUMN analysis_type TEXT NOT NULL DEFAULT "agronomic"');
    } catch (_) {}

    // Seed Capim Marandu if not present
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM crops WHERE name = ?",
      ['Capim Marandu'],
    )) ?? 0;

    if (count == 0) {
      await db.insert('crops', {
        'name': 'Capim Marandu',
        'icon': 'assets/images/crops/grass.png',
        'analysis_data_json':
            '{"crop":"marandu_grass","parameters":{"chlorophyll":42.5}}',
      });
    }
  }
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
      'analysis_data_json':
          '{"crop":"marandu_grass","parameters":{"chlorophyll":42.5}}',
    },
  ];

  for (final crop in crops) {
    await db.insert('crops', crop);
  }
}
