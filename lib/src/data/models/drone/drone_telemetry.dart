import 'package:equatable/equatable.dart';

class DroneTelemetry extends Equatable {
  final int batteryPercentage;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedHorizontal;
  final double speedVertical;
  final double yaw;
  final double pitch;
  final double roll;
  final int satelliteCount;
  final double gpsSignalLevel;
  final bool isFlying;

  const DroneTelemetry({
    required this.batteryPercentage,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speedHorizontal,
    required this.speedVertical,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.satelliteCount,
    required this.gpsSignalLevel,
    required this.isFlying,
  });

  factory DroneTelemetry.empty() {
    return const DroneTelemetry(
      batteryPercentage: 0,
      latitude: 0.0,
      longitude: 0.0,
      altitude: 0.0,
      speedHorizontal: 0.0,
      speedVertical: 0.0,
      yaw: 0.0,
      pitch: 0.0,
      roll: 0.0,
      satelliteCount: 0,
      gpsSignalLevel: 0.0,
      isFlying: false,
    );
  }

  DroneTelemetry copyWith({
    int? batteryPercentage,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speedHorizontal,
    double? speedVertical,
    double? yaw,
    double? pitch,
    double? roll,
    int? satelliteCount,
    double? gpsSignalLevel,
    bool? isFlying,
  }) {
    return DroneTelemetry(
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speedHorizontal: speedHorizontal ?? this.speedHorizontal,
      speedVertical: speedVertical ?? this.speedVertical,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      satelliteCount: satelliteCount ?? this.satelliteCount,
      gpsSignalLevel: gpsSignalLevel ?? this.gpsSignalLevel,
      isFlying: isFlying ?? this.isFlying,
    );
  }

  @override
  List<Object?> get props => [
        batteryPercentage,
        latitude,
        longitude,
        altitude,
        speedHorizontal,
        speedVertical,
        yaw,
        pitch,
        roll,
        satelliteCount,
        gpsSignalLevel,
        isFlying,
      ];
}
