import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/repositories/waypoint/waypoint_repository.dart';
import 'package:sqflite/sqflite.dart';

class MissionRepository {
  final Database _db;
  final WaypointRepository _waypointRepository;

  MissionRepository(this._db, this._waypointRepository);

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<Result<List<MissionModel>>> all() async {
    try {
      final rows = await _db.query('missions', orderBy: 'created_at DESC');
      final missions = <MissionModel>[];
      for (final row in rows) {
        missions.add(await _buildMission(row));
      }
      return Success(missions);
    } catch (e) {
      return Failure(Exception('Error fetching missions: $e'));
    }
  }

  Future<Result<MissionModel>> find(int id) async {
    try {
      final rows = await _db.query(
        'missions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return Failure(Exception('Mission not found'));
      return Success(await _buildMission(rows.first));
    } catch (e) {
      return Failure(Exception('Error fetching mission: $e'));
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<Result<MissionModel>> create({
    required String title,
    String? notes,
    required List<DroneWaypointModel> waypoints,
  }) async {
    try {
      final missionId = await _db.insert('missions', {
        'title': title,
        'notes': notes,
        'status': MissionStatus.planned.name,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final wp in waypoints) {
        await _db.insert(
          'waypoints',
          wp.copyWith(missionId: missionId).toMap()..remove('id'),
        );
      }

      return find(missionId);
    } catch (e) {
      return Failure(Exception('Error creating mission: $e'));
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> update(int missionId, Map<String, dynamic> fields) async {
    try {
      await _db.update(
        'missions',
        fields,
        where: 'id = ?',
        whereArgs: [missionId],
      );
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error updating mission: $e'));
    }
  }

  Future<Result<MissionModel>> updateWithWaypoints({
    required int missionId,
    required String title,
    String? notes,
    required List<DroneWaypointModel> waypoints,
  }) async {
    try {
      await _db.update(
        'missions',
        {'title': title, 'notes': notes},
        where: 'id = ?',
        whereArgs: [missionId],
      );
      await _waypointRepository.deleteBy('mission_id', missionId);
      for (final wp in waypoints) {
        await _db.insert(
          'waypoints',
          wp.copyWith(missionId: missionId).toMap()..remove('id'),
        );
      }
      return find(missionId);
    } catch (e) {
      return Failure(Exception('Error updating mission: $e'));
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> delete(int missionId) async {
    try {
      await _waypointRepository.deleteBy('mission_id', missionId);
      await _db.delete('missions', where: 'id = ?', whereArgs: [missionId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting mission: $e'));
    }
  }

  // ─── Helper ────────────────────────────────────────────────────────────────

  Future<MissionModel> _buildMission(Map<String, dynamic> row) async {
    final result = await _waypointRepository.findBy('mission_id', row['id']);
    List<DroneWaypointModel> waypoints = [];
    if (result is Success<List<DroneWaypointModel>>) {
      waypoints = result.value;
    }
    return MissionModel.fromMap(row, waypoints: waypoints);
  }
}
