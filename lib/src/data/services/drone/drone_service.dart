import 'dart:typed_data';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint.dart';
import 'package:nutrinitro/src/data/models/drone/camera_parameters.dart';
import 'package:nutrinitro/src/data/models/drone/gimbal_parameters.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';

abstract class DroneService {
  // Connection Management
  Future<bool> registerSdk();
  Future<void> connect();
  Future<void> disconnect();
  Future<void> pairRemoteController();
  Stream<DroneConnectionState> get connectionStateStream;
  Stream<ConnectionHealth> get connectionHealthStream;

  // Flight Control
  Future<void> takeoff();
  Future<void> land();
  Future<void> returnToHome();
  Future<void> pauseFlight();
  Future<void> resumeFlight();
  Future<void> emergencyStop();

  // Telemetry
  Stream<DroneTelemetry> get telemetryStream;

  // Mission System
  Future<void> uploadMission(List<DroneWaypoint> waypoints);
  Future<void> startMission();
  Future<void> abortMission();
  Stream<int> get activeWaypointIndexStream;

  // Camera & Gimbal
  Future<void> capturePhoto();
  Future<void> startIntervalShooting(int intervalSeconds);
  Future<void> stopIntervalShooting();
  Future<void> startVideoRecording();
  Future<void> stopVideoRecording();
  Future<void> updateCameraParameters(CameraParameters params);
  Future<void> setGimbalPitch(double degree);
  Future<void> updateGimbalParameters(GimbalParameters params);

  // Media Management
  Future<List<DroneMediaFile>> fetchMediaList();
  Future<void> downloadMediaFile(DroneMediaFile file, String destinationPath);
  Future<void> deleteMediaFile(DroneMediaFile file);

  // Video Streaming (FPV)
  Stream<Uint8List> get fpvByteStream;
  Future<void> startFpvStream();
  Future<void> stopFpvStream();
}
