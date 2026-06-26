class FlightPathPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;

  const FlightPathPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });

  FlightPathPoint copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? timestamp,
  }) {
    return FlightPathPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lng': longitude,
    'alt': altitude,
    'ts': timestamp.toIso8601String(),
  };

  factory FlightPathPoint.fromMap(Map<String, dynamic> map) => FlightPathPoint(
    latitude: map['lat'] as double,
    longitude: map['lng'] as double,
    altitude: map['alt'] as double,
    timestamp: DateTime.parse(map['ts'] as String),
  );

  @override
  String toString() =>
      'FlightPathPoint(lat: $latitude, lng: $longitude, alt: $altitude, ts: $timestamp)';

  @override
  bool operator ==(covariant FlightPathPoint other) {
    if (identical(this, other)) return true;
    return other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      altitude.hashCode ^
      timestamp.hashCode;
}
