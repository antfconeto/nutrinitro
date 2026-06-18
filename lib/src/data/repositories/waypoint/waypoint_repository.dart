import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:sqflite/sqflite.dart';

class WaypointRepository {
  final Database _db;

  WaypointRepository(this._db);

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<Result<DroneWaypointModel>> find(int id) async {
    try {
      final rows = await _db.query(
        'waypoints',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return Failure(Exception('Waypoint not found'));
      return Success(DroneWaypointModel.fromMap(rows.first));
    } catch (e) {
      return Failure(Exception('Error fetching waypoint: $e'));
    }
  }

  Future<Result<List<DroneWaypointModel>>> findBy(
    String field,
    dynamic value,
  ) async {
    try {
      final rows = await _db.query(
        'waypoints',
        where: '$field = ?',
        whereArgs: [value],
        orderBy: 'order_index ASC',
      );
      return Success(rows.map(DroneWaypointModel.fromMap).toList());
    } catch (e) {
      return Failure(Exception('Error fetching waypoints by $field: $e'));
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<Result<DroneWaypointModel>> create(DroneWaypointModel waypoint) async {
    try {
      final id = await _db.insert(
        'waypoints',
        waypoint.toMap()..remove('id'),
      );
      return find(id);
    } catch (e) {
      return Failure(Exception('Error creating waypoint: $e'));
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> update(
    int waypointId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _db.update(
        'waypoints',
        fields,
        where: 'id = ?',
        whereArgs: [waypointId],
      );
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error updating waypoint: $e'));
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> delete(int waypointId) async {
    try {
      await _db.delete('waypoints', where: 'id = ?', whereArgs: [waypointId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting waypoint: $e'));
    }
  }

  Future<Result<Nil>> deleteBy(String field, dynamic value) async {
    try {
      await _db.delete('waypoints', where: '$field = ?', whereArgs: [value]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting waypoints by $field: $e'));
    }
  }
}
