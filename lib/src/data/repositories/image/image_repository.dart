import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:sqflite/sqflite.dart';

class ImageRepository {
  final Database _db;

  ImageRepository(this._db);

  Future<Result<List<ImageModel>>> all() async {
    try {
      final rows = await _db.query('images', orderBy: 'display_order ASC');
      return Success(rows.map(ImageModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching images: $e'));
    }
  }

  Future<Result<ImageModel>> find(int id) async {
    try {
      final rows = await _db.query('images', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return Failure(Exception('Image not found'));
      return Success(ImageModel.fromMap(rows.first));
    } catch (e) {
      return Failure(Exception('Error fetching image: $e'));
    }
  }

  Future<Result<List<ImageModel>>> findBy(String field, dynamic value) async {
    try {
      final rows = await _db.query(
        'images',
        where: '$field = ?',
        whereArgs: [value],
        orderBy: 'display_order ASC',
      );
      return Success(rows.map(ImageModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching images by $field: $e'));
    }
  }

  Future<Result<ImageModel>> create(ImageModel image) async {
    try {
      final map = image.toMap()..remove('id');
      final id = await _db.insert('images', map);
      return find(id);
    } catch (e) {
      return Failure(Exception('Error creating image: $e'));
    }
  }

  Future<Result<Nil>> update(int imageId, Map<String, dynamic> fields) async {
    try {
      await _db.update('images', fields, where: 'id = ?', whereArgs: [imageId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error updating image: $e'));
    }
  }

  Future<Result<Nil>> delete(int imageId) async {
    try {
      await _db.delete('images', where: 'id = ?', whereArgs: [imageId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting image: $e'));
    }
  }

  Future<Result<Nil>> deleteBy(String field, dynamic value) async {
    try {
      await _db.delete('images', where: '$field = ?', whereArgs: [value]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting images by $field: $e'));
    }
  }
}
