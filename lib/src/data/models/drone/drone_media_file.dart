import 'package:equatable/equatable.dart';

enum DroneMediaType {
  photo,
  video,
}

enum DroneMediaCategory {
  preFlight,
  inFlight,
}

extension DroneMediaCategoryLabel on DroneMediaCategory {
  String get label => switch (this) {
        DroneMediaCategory.preFlight => 'Antes da decolagem',
        DroneMediaCategory.inFlight => 'Decolagem e voo',
      };
}

class DroneMediaFile extends Equatable {
  final String id;
  final String name;
  final String? url;
  final int sizeBytes;
  final DateTime createdTime;
  final DroneMediaType type;
  final DroneMediaCategory category;

  const DroneMediaFile({
    required this.id,
    required this.name,
    this.url,
    required this.sizeBytes,
    required this.createdTime,
    required this.type,
    this.category = DroneMediaCategory.preFlight,
  });

  /// Garante categoria válida (ex.: após hot reload com instâncias antigas).
  DroneMediaFile normalized() {
    try {
      // ignore: unnecessary_statements
      category;
      return this;
    } on TypeError {
      return DroneMediaFile(
        id: id,
        name: name,
        url: url,
        sizeBytes: sizeBytes,
        createdTime: createdTime,
        type: type,
        category: DroneMediaCategory.preFlight,
      );
    }
  }

  DroneMediaFile copyWith({
    String? id,
    String? name,
    String? url,
    int? sizeBytes,
    DateTime? createdTime,
    DroneMediaType? type,
    DroneMediaCategory? category,
  }) {
    return DroneMediaFile(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdTime: createdTime ?? this.createdTime,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        url,
        sizeBytes,
        createdTime,
        type,
        category,
      ];
}
