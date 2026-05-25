// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ImageModel {
  final int? id;
  final int analysisId;
  final String originalPath;
  final String? analyzedPath;
  final String? result; // JSON with analysis result for this image
  final double? latitude; // from EXIF metadata
  final double? longitude; // from EXIF metadata
  final DateTime? datetime; // from EXIF metadata
  final int displayOrder;

  ImageModel({
    this.id,
    required this.analysisId,
    required this.originalPath,
    this.analyzedPath,
    this.result,
    this.latitude,
    this.longitude,
    this.datetime,
    required this.displayOrder,
  });

  ImageModel copyWith({
    int? id,
    int? analysisId,
    String? originalPath,
    String? analyzedPath,
    String? result,
    double? latitude,
    double? longitude,
    DateTime? datetime,
    int? displayOrder,
  }) {
    return ImageModel(
      id: id ?? this.id,
      analysisId: analysisId ?? this.analysisId,
      originalPath: originalPath ?? this.originalPath,
      analyzedPath: analyzedPath ?? this.analyzedPath,
      result: result ?? this.result,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      datetime: datetime ?? this.datetime,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'analysisId': analysisId,
      'originalPath': originalPath,
      'analyzedPath': analyzedPath,
      'result': result,
      'latitude': latitude,
      'longitude': longitude,
      'datetime': datetime?.millisecondsSinceEpoch,
      'displayOrder': displayOrder,
    };
  }

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] != null ? map['id'] as int : null,
      analysisId: map['analysisId'] as int,
      originalPath: map['originalPath'] as String,
      analyzedPath: map['analyzedPath'] != null
          ? map['analyzedPath'] as String
          : null,
      result: map['result'] != null ? map['result'] as String : null,
      latitude: map['latitude'] != null ? map['latitude'] as double : null,
      longitude: map['longitude'] != null ? map['longitude'] as double : null,
      datetime: map['datetime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['datetime'] as int)
          : null,
      displayOrder: map['displayOrder'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageModel.fromJson(String source) =>
      ImageModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ImageModel(id: $id, analysisId: $analysisId, originalPath: $originalPath, analyzedPath: $analyzedPath, result: $result, latitude: $latitude, longitude: $longitude, datetime: $datetime, displayOrder: $displayOrder)';
  }

  @override
  bool operator ==(covariant ImageModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.analysisId == analysisId &&
        other.originalPath == originalPath &&
        other.analyzedPath == analyzedPath &&
        other.result == result &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.datetime == datetime &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        analysisId.hashCode ^
        originalPath.hashCode ^
        analyzedPath.hashCode ^
        result.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        datetime.hashCode ^
        displayOrder.hashCode;
  }

  // Methods Personalized

  bool get hasLocation => latitude != null && longitude != null;
  bool get hasExifDatetime => datetime != null;
  bool get wasAnalyzed => analyzedPath != null && result != null;
}
