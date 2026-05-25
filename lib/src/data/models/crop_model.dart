// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CropModel {
  final int? id;
  final String name;
  final String icon; // ex: 'assets/images/crops/corn.png'
  final String analysisDataJson; // JSON with analysis parameters

  CropModel({
    this.id,
    required this.name,
    required this.icon,
    required this.analysisDataJson,
  });

  CropModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? analysisDataJson,
  }) {
    return CropModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      analysisDataJson: analysisDataJson ?? this.analysisDataJson,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'icon': icon,
      'analysisDataJson': analysisDataJson,
    };
  }

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] as String,
      icon: map['icon'] as String,
      analysisDataJson: map['analysisDataJson'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CropModel.fromJson(String source) =>
      CropModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CropModel(id: $id, name: $name, icon: $icon, analysisDataJson: $analysisDataJson)';
  }

  @override
  bool operator ==(covariant CropModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.analysisDataJson == analysisDataJson;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        icon.hashCode ^
        analysisDataJson.hashCode;
  }
}
