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
    version: 1,
    onCreate: _onCreate,
  );
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

Future<void> _seedCrops(Database db) async {
  final crops = [
    {
      'name': 'Corn',
      'icon': 'assets/images/crops/corn.png',
      'analysis_data_json': '{"crop":"corn","parameters":{"moisture":14,"protein":8}}',
    },
  ];

  for (final crop in crops) {
    await db.insert('crops', crop);
  }
}