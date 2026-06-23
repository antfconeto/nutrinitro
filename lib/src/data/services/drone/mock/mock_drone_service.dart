import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/core/const/drone/gps_signal_level.dart';
import 'package:nutrinitro/src/core/const/resource.dart';
import 'package:nutrinitro/src/data/models/drone/camera_parameters.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';
import 'package:nutrinitro/src/data/services/drone/core/i_drone_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MockDroneService implements IDroneService {
  final _random = Random();

  static const _mockPhotos = [
    R.ASSETS_MOCK_DRONE_18_05_2026_P07_BLOCO2_CHLO36_90_JPG,
    R.ASSETS_MOCK_DRONE_21_05_2026_P04_BLOCO1_CHLO34_43_JPG,
    R.ASSETS_MOCK_DRONE_21_05_2026_P07_BLOCO2_CHLO34_49_JPG,
    R.ASSETS_MOCK_DRONE_21_05_2026_P12_BLOCO3_CHLO33_39_JPG,
    R.ASSETS_MOCK_DRONE_26_05_2026_P04_BLOCO1_CHLO33_19_JPG,
    R.ASSETS_MOCK_DRONE_26_05_2026_P07_BLOCO2_CHLO30_34_JPG,
    R.ASSETS_MOCK_DRONE_26_05_2026_P12_BLOCO3_CHLO30_79_JPG,
  ];

  // ─── State ──────────────────────────────────────────────────────────────────

  DroneConnectionState _connectionState = DroneConnectionState.disconnected;
  TelemetryData? _lastTelemetry;
  MissionModel? _currentMission;
  int _currentWaypointIndex = 0;

  double _lat = -7.219120;
  double _lng = -44.367890;
  double _alt = 0.0;
  double _heading = 0.0;
  int _battery = 100;
  bool _inFlight = false;
  bool _missionRunning = false;
  bool _intervalShooting = false;

  // ─── Controllers ────────────────────────────────────────────────────────────

  final _connectionCtrl = StreamController<DroneConnectionState>.broadcast();
  final _telemetryCtrl = StreamController<TelemetryData>.broadcast();
  final _missionCtrl = StreamController<int>.broadcast();
  final _videoCtrl = StreamController<List<int>>.broadcast();
  final _photoCtrl = StreamController<String>.broadcast();

  Timer? _telemetryTimer;
  Timer? _intervalTimer;
  Timer? _batteryTimer;

  // ─── Connection ─────────────────────────────────────────────────────────────

  @override
  DroneConnectionState get connectionState => _connectionState;

  @override
  Stream<DroneConnectionState> get connectionStream => _connectionCtrl.stream;

  @override
  Future<void> connect() async {
    _emitConnection(DroneConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 1500));
    _emitConnection(DroneConnectionState.connected);
    _startTelemetry();
    _startBatteryDrain();
  }

  @override
  Future<void> disconnect() async {
    _stopAll();
    _inFlight = false;
    _missionRunning = false;
    _emitConnection(DroneConnectionState.disconnected);
  }

  void _emitConnection(DroneConnectionState state) {
    _connectionState = state;
    _connectionCtrl.add(state);
  }

  // ─── Telemetry ──────────────────────────────────────────────────────────────

  @override
  TelemetryData? get lastTelemetry => _lastTelemetry;

  @override
  Stream<TelemetryData> get telemetryStream => _telemetryCtrl.stream;

  void _startTelemetry() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_inFlight) {
        _lat += (_random.nextDouble() - 0.5) * 0.00002;
        _lng += (_random.nextDouble() - 0.5) * 0.00002;
        _heading = (_heading + _random.nextDouble() * 2 - 1) % 360;
      }

      final data = TelemetryData(
        latitude: _lat,
        longitude: _lng,
        altitude: _alt,
        speed: _inFlight ? 3.0 + _random.nextDouble() * 4 : 0.0,
        heading: _heading,
        pitch: _inFlight ? (_random.nextDouble() - 0.5) * 4 : 0.0,
        roll: _inFlight ? (_random.nextDouble() - 0.5) * 4 : 0.0,
        yaw: _heading,
        batteryPercent: _battery,
        batteryVoltage: 11.1 + (_battery / 100) * 1.5,
        gpsSatellites: 10 + _random.nextInt(4),
        gpsSignal: GpsSignalLevel.excellent,
        connectionState: _connectionState,
        timestamp: DateTime.now(),
      );

      _lastTelemetry = data;
      _telemetryCtrl.add(data);
    });
  }

  void _startBatteryDrain() {
    _batteryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_inFlight && _battery > 0) _battery--;
    });
  }

  // ─── Flight control ─────────────────────────────────────────────────────────

  @override
  Future<void> takeoff() async {
    _inFlight = true;
    await _animateAltitude(0, 30);
  }

  @override
  Future<void> land() async {
    await _animateAltitude(_alt, 0);
    _inFlight = false;
  }

  @override
  Future<void> returnToHome() async {
    _missionRunning = false;
    await land();
  }

  @override
  Future<void> pauseFlight() async {
    _missionRunning = false;
  }

  @override
  Future<void> resumeFlight() async {
    if (_currentMission != null) _executeMission();
  }

  @override
  Future<void> emergencyStop() async {
    _stopAll();
    _inFlight = false;
    _missionRunning = false;
  }

  Future<void> _animateAltitude(double from, double to) async {
    const steps = 20;
    final delta = (to - from) / steps;
    for (int i = 0; i < steps; i++) {
      _alt += delta;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _alt = to;
  }

  // ─── Mission ────────────────────────────────────────────────────────────────

  @override
  Stream<int> get missionProgressStream => _missionCtrl.stream;

  @override
  Future<void> uploadMission(MissionModel mission) async {
    _currentMission = mission;
    _currentWaypointIndex = 0;
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<void> startMission() async {
    if (_currentMission == null) return;
    if (!_inFlight) await takeoff();
    _executeMission();
  }

  void _executeMission() {
    if (_currentMission == null) return;
    _missionRunning = true;
    _runNextWaypoint();
  }

  Future<void> _runNextWaypoint() async {
    if (!_missionRunning || _currentMission == null) return;
    final waypoints = _currentMission!.waypoints;

    if (_currentWaypointIndex >= waypoints.length) {
      _missionRunning = false;
      await land();
      return;
    }

    final wp = waypoints[_currentWaypointIndex];

    // Animate drone flying toward the waypoint
    await _animatePosition(_lat, _lng, wp.latitude, wp.longitude, wp.altitude);
    if (!_missionRunning) return;

    _missionCtrl.add(_currentWaypointIndex);
    if (wp.capturePhoto) await capturePhoto();

    _currentWaypointIndex++;
    await Future.delayed(const Duration(milliseconds: 400));
    _runNextWaypoint();
  }

  Future<void> _animatePosition(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    double toAlt,
  ) async {
    const steps = 25;
    const stepDelay = Duration(milliseconds: 120);
    final dLat = (toLat - fromLat) / steps;
    final dLng = (toLng - fromLng) / steps;
    final dAlt = (toAlt - _alt) / steps;
    for (int i = 0; i < steps; i++) {
      if (!_missionRunning) return;
      _lat += dLat;
      _lng += dLng;
      _alt += dAlt;
      await Future.delayed(stepDelay);
    }
    _lat = toLat;
    _lng = toLng;
    _alt = toAlt;
  }

  @override
  Future<void> abortMission() async {
    _missionRunning = false;
    _currentWaypointIndex = 0;
    await returnToHome();
  }

  // ─── Camera ─────────────────────────────────────────────────────────────────

  @override
  Stream<String> get missionPhotoStream => _photoCtrl.stream;

  @override
  Future<void> capturePhoto() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final missionId = _currentMission?.id;
    if (missionId == null) return;
    try {
      final assetPath = _mockPhotos[_random.nextInt(_mockPhotos.length)];
      final bytes = await rootBundle.load(assetPath);
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'missions', missionId.toString()));
      await dir.create(recursive: true);
      final file = File(
        p.join(dir.path, 'mock_${DateTime.now().millisecondsSinceEpoch}.jpg'),
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      _photoCtrl.add(file.path);
    } catch (_) {}
  }

  @override
  Future<void> startIntervalShooting(Duration interval) async {
    _intervalShooting = true;
    _intervalTimer = Timer.periodic(interval, (_) async {
      if (!_intervalShooting) return;
      await capturePhoto();
    });
  }

  @override
  Future<void> stopIntervalShooting() async {
    _intervalShooting = false;
    _intervalTimer?.cancel();
  }

  @override
  Future<void> setCameraParameters(CameraParameters params) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> setGimbalPitch(double pitch) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  // ─── Media ──────────────────────────────────────────────────────────────────

  @override
  Future<List<String>> listMediaFiles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(
      5,
      (i) => 'DJI_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
    );
  }

  @override
  Future<String> downloadFile(String remotePath, String localPath) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return localPath;
  }

  @override
  Future<void> deleteFile(String remotePath) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ─── Video stream ───────────────────────────────────────────────────────────

  @override
  Stream<List<int>> get videoStream => _videoCtrl.stream;

  @override
  Future<void> startVideoStream() async {}

  @override
  Future<void> stopVideoStream() async {}

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  void _stopAll() {
    _telemetryTimer?.cancel();
    _intervalTimer?.cancel();
    _batteryTimer?.cancel();
  }

  @override
  void dispose() {
    _stopAll();
    _connectionCtrl.close();
    _telemetryCtrl.close();
    _missionCtrl.close();
    _videoCtrl.close();
    _photoCtrl.close();
  }
}
