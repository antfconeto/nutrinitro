class DroneWaypointModel {
  final int? id;
  final int missionId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final bool capturePhoto;
  final int orderIndex;

  const DroneWaypointModel({
    this.id,
    required this.missionId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.speed = 5.0,
    this.heading = 0.0,
    this.capturePhoto = true,
    required this.orderIndex,
  });

  bool get isNadir => heading == 0.0;

  DroneWaypointModel copyWith({
    int? id,
    int? missionId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    bool? capturePhoto,
    int? orderIndex,
  }) {
    return DroneWaypointModel(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      capturePhoto: capturePhoto ?? this.capturePhoto,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mission_id': missionId,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'capture_photo': capturePhoto ? 1 : 0,
    'order_index': orderIndex,
  };

  factory DroneWaypointModel.fromMap(Map<String, dynamic> map) =>
      DroneWaypointModel(
        id: map['id'] as int?,
        missionId: map['mission_id'] as int,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        altitude: map['altitude'] as double,
        speed: map['speed'] as double,
        heading: map['heading'] as double,
        capturePhoto: (map['capture_photo'] as int) == 1,
        orderIndex: map['order_index'] as int,
      );

  @override
  String toString() =>
      'DroneWaypointModel(id: $id, lat: $latitude, lng: $longitude, alt: $altitude, order: $orderIndex)';

  @override
  bool operator ==(covariant DroneWaypointModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.missionId == missionId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.speed == speed &&
        other.heading == heading &&
        other.capturePhoto == capturePhoto &&
        other.orderIndex == orderIndex;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      missionId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      altitude.hashCode ^
      orderIndex.hashCode;
}
