import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/core/const/drone/gps_signal_level.dart';

class TelemetryData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final double pitch;
  final double roll;
  final double yaw;
  final int batteryPercent;
  final double batteryVoltage;
  final int gpsSatellites;
  final GpsSignalLevel gpsSignal;
  final DroneConnectionState connectionState;
  final DateTime timestamp;

  const TelemetryData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.batteryPercent,
    required this.batteryVoltage,
    required this.gpsSatellites,
    required this.gpsSignal,
    required this.connectionState,
    required this.timestamp,
  });

  bool get isLowBattery => batteryPercent <= 20;
  bool get isCriticalBattery => batteryPercent <= 10;

  TelemetryData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? heading,
    double? pitch,
    double? roll,
    double? yaw,
    int? batteryPercent,
    double? batteryVoltage,
    int? gpsSatellites,
    GpsSignalLevel? gpsSignal,
    DroneConnectionState? connectionState,
    DateTime? timestamp,
  }) {
    return TelemetryData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      yaw: yaw ?? this.yaw,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      gpsSatellites: gpsSatellites ?? this.gpsSatellites,
      gpsSignal: gpsSignal ?? this.gpsSignal,
      connectionState: connectionState ?? this.connectionState,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'TelemetryData(lat: $latitude, lng: $longitude, alt: $altitude, speed: $speed, battery: $batteryPercent%)';
  }
}
