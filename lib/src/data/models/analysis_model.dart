// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';

class AnalysisModel {
  final int? id;
  final String title;
  final DateTime datetime;
  final String? notes;
  final int cropId;
  final AnalysisStatus status;
  final String analysisType;

  final CropModel? crop;
  final List<ImageModel> images;

  AnalysisModel({
    this.id,
    required this.title,
    required this.datetime,
    this.notes,
    required this.cropId,
    required this.status,
    this.analysisType = 'agronomic',
    this.crop,
    required this.images,
  });

  AnalysisModel copyWith({
    int? id,
    String? title,
    DateTime? datetime,
    String? notes,
    int? cropId,
    AnalysisStatus? status,
    String? analysisType,
    CropModel? crop,
    List<ImageModel>? images,
  }) {
    return AnalysisModel(
      id: id ?? this.id,
      title: title ?? this.title,
      datetime: datetime ?? this.datetime,
      notes: notes ?? this.notes,
      cropId: cropId ?? this.cropId,
      status: status ?? this.status,
      analysisType: analysisType ?? this.analysisType,
      crop: crop ?? this.crop,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'datetime': datetime.toIso8601String(),
      'notes': notes,
      'crop_id': cropId,
      'status': status.name,
      'analysis_type': analysisType,
    };
  }

  factory AnalysisModel.fromMap(
    Map<String, dynamic> map, {
    CropModel? crop,
    List<ImageModel> images = const [],
  }) {
    return AnalysisModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] as String,
      datetime: DateTime.parse(
        map['datetime'] as String,
      ), 
      notes: map['notes'] as String?,
      cropId: map['crop_id'] as int, 
      status: AnalysisStatus.fromString(map['status'] as String),
      analysisType: map['analysis_type'] as String? ?? 'agronomic',
      crop: crop, 
      images: images, 
    );
  }

  String toJson() => json.encode(toMap());

  factory AnalysisModel.fromJson(String source) => AnalysisModel.fromMap(
    json.decode(source) as Map<String, dynamic>,
    images: [],
  );

  @override
  String toString() {
    return 'AnalysisModel(id: $id, title: $title, datetime: $datetime, notes: $notes, cropId: $cropId, status: $status, analysisType: $analysisType, crop: $crop, images: $images)';
  }

  @override
  bool operator ==(covariant AnalysisModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.datetime == datetime &&
        other.notes == notes &&
        other.cropId == cropId &&
        other.status == status &&
        other.analysisType == analysisType &&
        other.crop == crop &&
        listEquals(other.images, images);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        datetime.hashCode ^
        notes.hashCode ^
        cropId.hashCode ^
        status.hashCode ^
        analysisType.hashCode ^
        crop.hashCode ^
        images.hashCode;
  }

  // Methods Personalized

  bool get isPending => status == AnalysisStatus.pending;
  bool get isProcessing => status == AnalysisStatus.processing;
  bool get isCompleted => status == AnalysisStatus.completed;
  bool get isError => status == AnalysisStatus.error;

  ImageModel? get previewImage => images.isNotEmpty ? images.first : null;

  List<ImageModel> get imagesWithLocation =>
      images.where((i) => i.hasLocation).toList();
}
