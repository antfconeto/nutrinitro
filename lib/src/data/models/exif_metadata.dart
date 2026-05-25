// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ExifMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime? datetime;
  ExifMetadata({
    this.latitude,
    this.longitude,
    this.datetime,
  });

  ExifMetadata copyWith({
    double? latitude,
    double? longitude,
    DateTime? datetime,
  }) {
    return ExifMetadata(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      datetime: datetime ?? this.datetime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'datetime': datetime?.millisecondsSinceEpoch,
    };
  }

  factory ExifMetadata.fromMap(Map<String, dynamic> map) {
    return ExifMetadata(
      latitude: map['latitude'] != null ? map['latitude'] as double : null,
      longitude: map['longitude'] != null ? map['longitude'] as double : null,
      datetime: map['datetime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['datetime'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExifMetadata.fromJson(String source) =>
      ExifMetadata.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ExifMetadata(latitude: $latitude, longitude: $longitude, datetime: $datetime)';

  @override
  bool operator ==(covariant ExifMetadata other) {
    if (identical(this, other)) return true;

    return other.latitude == latitude &&
        other.longitude == longitude &&
        other.datetime == datetime;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ datetime.hashCode;

  // Methods Personalized

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasDatetime => datetime != null;
}
