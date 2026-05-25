import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:sqflite/sqflite.dart';

class CropRepository {
  final Database _db;

  CropRepository(this._db);

  Future<Result<List<CropModel>>> all() async {
    try {
      final rows = await _db.query('crops', orderBy: 'name ASC');
      return Success(rows.map(CropModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching crops: $e'));
    }
  }

  Future<Result<CropModel>> find(int id) async {
    try {
      final rows = await _db.query(
        'crops',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return Failure(Exception('Crop not found'));
      return Success(CropModel.fromMap(rows.first));
    } catch (e) {
      return Failure(Exception('Error fetching crop: $e'));
    }
  }

  Future<Result<List<CropModel>>> findBy(String field, dynamic value) async {
    try {
      final rows = await _db.query(
        'crops',
        where: '$field = ?',
        whereArgs: [value],
        orderBy: 'name ASC',
      );
      return Success(rows.map(CropModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching crops by $field: $e'));
    }
  }
}