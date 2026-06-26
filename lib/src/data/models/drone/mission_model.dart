import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/data/models/drone/flight_path_point.dart';

class MissionModel {
  final int? id;
  final String title;
  final String? notes;
  final MissionStatus status;
  final int? cropId;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<DroneWaypointModel> waypoints;
  final List<FlightPathPoint> flightPath;

  const MissionModel({
    this.id,
    required this.title,
    this.notes,
    this.status = MissionStatus.planned,
    this.cropId,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.waypoints = const [],
    this.flightPath = const [],
  });

  bool get isPlanned => status == MissionStatus.planned;
  bool get isExecuting => status == MissionStatus.executing;
  bool get isCompleted => status == MissionStatus.completed;
  bool get isAborted => status == MissionStatus.aborted;

  MissionModel copyWith({
    int? id,
    String? title,
    String? notes,
    MissionStatus? status,
    int? cropId,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<DroneWaypointModel>? waypoints,
    List<FlightPathPoint>? flightPath,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      cropId: cropId ?? this.cropId,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      waypoints: waypoints ?? this.waypoints,
      flightPath: flightPath ?? this.flightPath,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'notes': notes,
    'status': status.name,
    'crop_id': cropId,
    'created_at': createdAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'flight_path_json': flightPath.isNotEmpty
        ? jsonEncode(flightPath.map((p) => p.toMap()).toList())
        : null,
  };

  factory MissionModel.fromMap(
    Map<String, dynamic> map, {
    List<DroneWaypointModel> waypoints = const [],
  }) {
    List<FlightPathPoint> flightPath = const [];
    final pathJson = map['flight_path_json'];
    if (pathJson != null && (pathJson as String).isNotEmpty) {
      final decoded = jsonDecode(pathJson) as List;
      flightPath = decoded
          .map((e) => FlightPathPoint.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return MissionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      status: MissionStatus.fromString(map['status'] as String),
      cropId: map['crop_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      waypoints: waypoints,
      flightPath: flightPath,
    );
  }

  @override
  String toString() =>
      'MissionModel(id: $id, title: $title, status: $status, waypoints: ${waypoints.length})';

  @override
  bool operator ==(covariant MissionModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.title == title &&
        other.status == status &&
        other.cropId == cropId &&
        listEquals(other.waypoints, waypoints);
  }

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ status.hashCode ^ cropId.hashCode;
}
