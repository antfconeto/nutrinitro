class DroneImageModel {
  final int? id;
  final int missionId;
  final int? waypointId;
  final String localPath;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final DateTime datetime;
  final int? analysisId;

  const DroneImageModel({
    this.id,
    required this.missionId,
    this.waypointId,
    required this.localPath,
    this.latitude,
    this.longitude,
    this.altitude,
    required this.datetime,
    this.analysisId,
  });

  bool get hasLocation => latitude != null && longitude != null;
  bool get isLinked => analysisId != null;

  DroneImageModel copyWith({
    int? id,
    int? missionId,
    int? waypointId,
    String? localPath,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? datetime,
    int? analysisId,
  }) {
    return DroneImageModel(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      waypointId: waypointId ?? this.waypointId,
      localPath: localPath ?? this.localPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      datetime: datetime ?? this.datetime,
      analysisId: analysisId ?? this.analysisId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mission_id': missionId,
    'waypoint_id': waypointId,
    'local_path': localPath,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'datetime': datetime.toIso8601String(),
    'analysis_id': analysisId,
  };

  factory DroneImageModel.fromMap(Map<String, dynamic> map) => DroneImageModel(
    id: map['id'] as int?,
    missionId: map['mission_id'] as int,
    waypointId: map['waypoint_id'] as int?,
    localPath: map['local_path'] as String,
    latitude: map['latitude'] as double?,
    longitude: map['longitude'] as double?,
    altitude: map['altitude'] as double?,
    datetime: DateTime.parse(map['datetime'] as String),
    analysisId: map['analysis_id'] as int?,
  );

  @override
  String toString() =>
      'DroneImageModel(id: $id, missionId: $missionId, localPath: $localPath, linked: $isLinked)';

  @override
  bool operator ==(covariant DroneImageModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.missionId == missionId &&
        other.localPath == localPath;
  }

  @override
  int get hashCode => id.hashCode ^ missionId.hashCode ^ localPath.hashCode;
}
