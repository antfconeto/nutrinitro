import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;

  static Database get instance {
    assert(
      _db != null,
      'DatabaseService not initialized. Call init() in main().',
    );
    return _db!;
  }

  static Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nutrinitro.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        title    VARCHAR NOT NULL,
        datetime TIMESTAMP NOT NULL,
        notes    TEXT,
        crop_id  INTEGER NOT NULL,
        status   VARCHAR NOT NULL DEFAULT 'pending',
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

  static Future<void> _seedCrops(Database db) async {
    final crops = [
      {
        'name': 'Corn',
        'icon': 'assets/images/crops/corn.png',
        'analysis_data_json':
            '{"crop":"corn","parameters":{"moisture":14,"protein":8}}',
      },
    ];

    for (final crop in crops) {
      await db.insert('crops', crop);
    }
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
