import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';
import 'package:sqflite/sqflite.dart';

class DroneImageRepository {
  final Database _db;

  DroneImageRepository(this._db);

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<Result<DroneImageModel>> find(int id) async {
    try {
      final rows = await _db.query(
        'drone_images',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return Failure(Exception('Drone image not found'));
      return Success(DroneImageModel.fromMap(rows.first));
    } catch (e) {
      return Failure(Exception('Error fetching drone image: $e'));
    }
  }

  Future<Result<List<DroneImageModel>>> all() async {
    try {
      final rows = await _db.query(
        'drone_images',
        orderBy: 'datetime DESC',
      );
      return Success(rows.map(DroneImageModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching all drone images: $e'));
    }
  }

  Future<Result<List<DroneImageModel>>> findBy(
    String field,
    dynamic value,
  ) async {
    try {
      final rows = await _db.query(
        'drone_images',
        where: '$field = ?',
        whereArgs: [value],
        orderBy: 'datetime ASC',
      );
      return Success(rows.map(DroneImageModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching drone images by $field: $e'));
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<Result<DroneImageModel>> create(DroneImageModel image) async {
    try {
      final id = await _db.insert(
        'drone_images',
        image.toMap()..remove('id'),
      );
      return find(id);
    } catch (e) {
      return Failure(Exception('Error creating drone image: $e'));
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  /// Used to link a drone image to an analysis after import.
  /// Example: repository.update(imageId, {'analysis_id': analysisId})
  Future<Result<Nil>> update(int imageId, Map<String, dynamic> fields) async {
    try {
      await _db.update(
        'drone_images',
        fields,
        where: 'id = ?',
        whereArgs: [imageId],
      );
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error updating drone image: $e'));
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> delete(int imageId) async {
    try {
      await _db.delete('drone_images', where: 'id = ?', whereArgs: [imageId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting drone image: $e'));
    }
  }

  Future<Result<Nil>> deleteBy(String field, dynamic value) async {
    try {
      await _db.delete(
        'drone_images',
        where: '$field = ?',
        whereArgs: [value],
      );
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting drone images by $field: $e'));
    }
  }
}
