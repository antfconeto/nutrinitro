import 'dart:async';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/camera_parameters.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';

abstract class IDroneService {
  // ─── Connection ─────────────────────────────────────────────────────────────

  Future<void> connect();
  Future<void> disconnect();
  Stream<DroneConnectionState> get connectionStream;
  DroneConnectionState get connectionState;

  // ─── Telemetry ──────────────────────────────────────────────────────────────

  Stream<TelemetryData> get telemetryStream;
  TelemetryData? get lastTelemetry;

  // ─── Flight control ─────────────────────────────────────────────────────────

  Future<void> takeoff();
  Future<void> land();
  Future<void> returnToHome();
  Future<void> pauseFlight();
  Future<void> resumeFlight();
  Future<void> emergencyStop();

  // ─── Mission ────────────────────────────────────────────────────────────────

  Future<void> uploadMission(MissionModel mission);
  Future<void> startMission();
  Future<void> abortMission();
  Stream<int> get missionProgressStream;

  // ─── Camera ─────────────────────────────────────────────────────────────────

  Future<void> capturePhoto();
  Future<void> startIntervalShooting(Duration interval);
  Future<void> stopIntervalShooting();
  Future<void> setCameraParameters(CameraParameters params);
  Future<void> setGimbalPitch(double pitch);

  // ─── Media ──────────────────────────────────────────────────────────────────

  Future<List<String>> listMediaFiles();
  Future<String> downloadFile(String remotePath, String localPath);
  Future<void> deleteFile(String remotePath);

  // ─── Video stream ───────────────────────────────────────────────────────────

  Stream<List<int>> get videoStream;
  Future<void> startVideoStream();
  Future<void> stopVideoStream();

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  void dispose();
}
