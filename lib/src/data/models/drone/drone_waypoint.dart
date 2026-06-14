import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum WaypointAction {
  none,
  shootPhoto,
  startRecord,
  stopRecord,
  rotateGimbal,
}

class DroneWaypoint extends Equatable {
  final int id;
  final LatLng coordinate;
  final double altitude; // em metros
  final double speed; // em m/s
  final WaypointAction action;
  final double actionParameter;

  const DroneWaypoint({
    required this.id,
    required this.coordinate,
    required this.altitude,
    required this.speed,
    this.action = WaypointAction.none,
    this.actionParameter = 0.0,
  });

  DroneWaypoint copyWith({
    int? id,
    LatLng? coordinate,
    double? altitude,
    double? speed,
    WaypointAction? action,
    double? actionParameter,
  }) {
    return DroneWaypoint(
      id: id ?? this.id,
      coordinate: coordinate ?? this.coordinate,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      action: action ?? this.action,
      actionParameter: actionParameter ?? this.actionParameter,
    );
  }

  @override
  List<Object?> get props => [
        id,
        coordinate,
        altitude,
        speed,
        action,
        actionParameter,
      ];
}
