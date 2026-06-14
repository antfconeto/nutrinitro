import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/data/models/drone/camera_parameters.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint.dart';
import 'package:nutrinitro/src/data/models/drone/gimbal_parameters.dart';

import 'drone_service.dart';

class MockDroneService implements DroneService {
  final _connectionStateController = StreamController<DroneConnectionState>.broadcast();
  final _connectionHealthController = StreamController<ConnectionHealth>.broadcast();
  final _telemetryController = StreamController<DroneTelemetry>.broadcast();
  final _activeWaypointController = StreamController<int>.broadcast();
  final _fpvByteStreamController = StreamController<Uint8List>.broadcast();

  DroneConnectionState _connectionState = DroneConnectionState.disconnected;
  ConnectionHealth _connectionHealth = ConnectionHealth.none;
  DroneTelemetry _telemetry = DroneTelemetry.empty();
  int _activeWaypointIndex = -1;

  Timer? _telemetryTimer;
  Timer? _missionTimer;
  Timer? _fpvTimer;
  Timer? _intervalPhotoTimer;

  // Drone State
  double _homeLat = -21.1775;
  double _homeLng = -47.8103;
  double _currentLat = -21.1775;
  double _currentLng = -47.8103;
  double _currentAlt = 0.0;
  double _currentSpeedHor = 0.0;
  double _currentSpeedVer = 0.0;
  double _currentYaw = 0.0;
  double _currentPitch = 0.0;
  double _currentRoll = 0.0;
  int _currentBattery = 100;
  bool _isFlying = false;
  bool _isRecordingVideo = false;

  DateTime? _takeoffTime;

  // Media List Mock State
  final List<DroneMediaFile> _mockMediaList = [];

  // Mission
  List<DroneWaypoint> _waypoints = [];
  bool _isMissionRunning = false;
  bool _isMissionPaused = false;

  CameraParameters _cameraParams = const CameraParameters();
  GimbalParameters _gimbalParams = const GimbalParameters();

  MockDroneService() {
    // Inicializar lista mockada de arquivos
    _resetMediaList();
  }

  void _resetMediaList() {
    _mockMediaList.clear();
    _takeoffTime = null;
    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      _mockMediaList.add(
        DroneMediaFile(
          id: 'media_$i',
          name: 'DJI_${i.toString().padLeft(4, '0')}.JPG',
          sizeBytes: 4 * 1024 * 1024 + (i * 250 * 1024),
          createdTime: now.subtract(Duration(minutes: 15 + (i * 5))),
          type: DroneMediaType.photo,
          category: DroneMediaCategory.preFlight,
        ),
      );
    }
    for (int i = 4; i <= 5; i++) {
      _mockMediaList.add(
        DroneMediaFile(
          id: 'media_$i',
          name: 'DJI_${i.toString().padLeft(4, '0')}.JPG',
          sizeBytes: 4 * 1024 * 1024 + (i * 250 * 1024),
          createdTime: now.subtract(Duration(minutes: 8 - i)),
          type: DroneMediaType.photo,
          category: DroneMediaCategory.inFlight,
        ),
      );
    }
    _mockMediaList.add(
      DroneMediaFile(
        id: 'media_6',
        name: 'DJI_0006.MP4',
        sizeBytes: 45 * 1024 * 1024,
        createdTime: now.subtract(const Duration(minutes: 2)),
        type: DroneMediaType.video,
        category: DroneMediaCategory.inFlight,
      ),
    );
  }

  @override
  Stream<DroneConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<ConnectionHealth> get connectionHealthStream => _connectionHealthController.stream;

  @override
  Stream<DroneTelemetry> get telemetryStream => _telemetryController.stream;

  @override
  Stream<int> get activeWaypointIndexStream => _activeWaypointController.stream;

  @override
  Stream<Uint8List> get fpvByteStream => _fpvByteStreamController.stream;

  @override
  Future<bool> registerSdk() async {
    _connectionState = DroneConnectionState.sdkRegistered;
    _connectionStateController.add(_connectionState);
    return true;
  }

  void _sanitizeStoredMedia() {
    for (var i = 0; i < _mockMediaList.length; i++) {
      _mockMediaList[i] = _mockMediaList[i].normalized();
    }
  }

  @override
  Future<void> connect() async {
    _connectionState = DroneConnectionState.connecting;
    _connectionStateController.add(_connectionState);
    
    await Future.delayed(const Duration(seconds: 1));
    
    _connectionState = DroneConnectionState.connected;
    _connectionStateController.add(_connectionState);
    
    _connectionHealth = ConnectionHealth.excellent;
    _connectionHealthController.add(_connectionHealth);

    _sanitizeStoredMedia();
    _startTelemetryLoop();
    _startFpvStreamLoop();
  }

  @override
  Future<void> disconnect() async {
    _connectionState = DroneConnectionState.disconnecting;
    _connectionStateController.add(_connectionState);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _stopTelemetryLoop();
    _stopFpvStreamLoop();
    _stopMissionLoop();
    _stopIntervalPhotoTimer();
    
    _connectionState = DroneConnectionState.disconnected;
    _connectionStateController.add(_connectionState);
    
    _connectionHealth = ConnectionHealth.none;
    _connectionHealthController.add(_connectionHealth);
  }

  @override
  Future<void> pairRemoteController() async {
    if (_connectionState != DroneConnectionState.connected) return;
    // Simular pareamento rápido
    await Future.delayed(const Duration(seconds: 1));
  }

  // ─── Flight Control ────────────────────────────────────────────────────────

  @override
  Future<void> takeoff() async {
    if (_isFlying) return;
    _takeoffTime = DateTime.now();
    _isFlying = true;
    _currentSpeedVer = 1.0;
    
    // Subir até 1.5m
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentAlt += 0.3;
    }
    _currentSpeedVer = 0.0;
  }

  @override
  Future<void> land() async {
    if (!_isFlying) return;
    _currentSpeedVer = -1.0;
    
    // Descer gradualmente
    while (_currentAlt > 0) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentAlt -= 0.5;
      if (_currentAlt < 0) _currentAlt = 0;
    }
    _currentSpeedVer = 0.0;
    _isFlying = false;
    _currentSpeedHor = 0.0;
  }

  @override
  Future<void> returnToHome() async {
    if (!_isFlying) return;
    // Subir para altitude de RTH (ex: 30m)
    if (_currentAlt < 30.0) {
      _currentSpeedVer = 1.5;
      while (_currentAlt < 30.0) {
        await Future.delayed(const Duration(milliseconds: 200));
        _currentAlt += 0.5;
      }
      _currentSpeedVer = 0.0;
    }

    // Rotacionar em direção à Home
    final targetYaw = const Distance().bearing(LatLng(_currentLat, _currentLng), LatLng(_homeLat, _homeLng));
    _currentYaw = targetYaw;

    // Voar de volta
    _currentSpeedHor = 8.0;
    final points = 20;
    final latStep = (_homeLat - _currentLat) / points;
    final lngStep = (_homeLng - _currentLng) / points;
    
    for (int i = 0; i < points; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      _currentLat += latStep;
      _currentLng += lngStep;
    }
    _currentSpeedHor = 0.0;
    
    // Pousar
    await land();
  }

  @override
  Future<void> pauseFlight() async {
    _isMissionPaused = true;
    _currentSpeedHor = 0.0;
    _currentSpeedVer = 0.0;
  }

  @override
  Future<void> resumeFlight() async {
    _isMissionPaused = false;
  }

  @override
  Future<void> emergencyStop() async {
    _stopMissionLoop();
    _stopIntervalPhotoTimer();
    _isFlying = false;
    _currentSpeedHor = 0.0;
    _currentSpeedVer = 0.0;
    _currentAlt = 0.0;
  }

  // ─── Mission System ────────────────────────────────────────────────────────

  @override
  Future<void> uploadMission(List<DroneWaypoint> waypoints) async {
    _waypoints = List.from(waypoints);
    _activeWaypointIndex = -1;
    _activeWaypointController.add(_activeWaypointIndex);
  }

  @override
  Future<void> startMission() async {
    if (_waypoints.isEmpty) return;
    if (!_isFlying) {
      await takeoff();
    }
    
    _isMissionRunning = true;
    _isMissionPaused = false;
    _activeWaypointIndex = 0;
    _activeWaypointController.add(_activeWaypointIndex);
    
    _missionTimer?.cancel();
    
    _missionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMissionPaused) return;
      if (_activeWaypointIndex >= _waypoints.length) {
        _stopMissionLoop();
        returnToHome();
        return;
      }

      final target = _waypoints[_activeWaypointIndex];
      final targetCoord = target.coordinate;
      
      // Mover drone em direção ao waypoint ativo
      final distance = const Distance().as(LengthUnit.Meter, LatLng(_currentLat, _currentLng), targetCoord);
      _currentSpeedHor = target.speed;

      // Orientação/Yaw em direção ao ponto
      _currentYaw = const Distance().bearing(LatLng(_currentLat, _currentLng), targetCoord);

      // Mudar altitude
      if ((_currentAlt - target.altitude).abs() > 0.5) {
        if (_currentAlt < target.altitude) {
          _currentAlt += 1.0;
          _currentSpeedVer = 1.0;
        } else {
          _currentAlt -= 1.0;
          _currentSpeedVer = -1.0;
        }
      } else {
        _currentSpeedVer = 0.0;
      }

      if (distance < 5.0) {
        // Drone chegou perto do waypoint, executar ação
        _executeWaypointAction(target.action, target.actionParameter);
        
        // Passar para o próximo waypoint
        _activeWaypointIndex++;
        if (_activeWaypointIndex < _waypoints.length) {
          _activeWaypointController.add(_activeWaypointIndex);
        } else {
          _stopMissionLoop();
          returnToHome();
        }
      } else {
        // Interpolação linear de posição por segundo
        final ratio = math.min(1.0, _currentSpeedHor / distance);
        _currentLat += (targetCoord.latitude - _currentLat) * ratio;
        _currentLng += (targetCoord.longitude - _currentLng) * ratio;
      }
    });
  }

  void _executeWaypointAction(WaypointAction action, double parameter) {
    switch (action) {
      case WaypointAction.shootPhoto:
        capturePhoto();
        break;
      case WaypointAction.startRecord:
        startVideoRecording();
        break;
      case WaypointAction.stopRecord:
        stopVideoRecording();
        break;
      case WaypointAction.rotateGimbal:
        setGimbalPitch(parameter);
        break;
      case WaypointAction.none:
      default:
        break;
    }
  }

  @override
  Future<void> abortMission() async {
    _stopMissionLoop();
    pauseFlight();
  }

  void _stopMissionLoop() {
    _isMissionRunning = false;
    _missionTimer?.cancel();
    _activeWaypointIndex = -1;
    _activeWaypointController.add(_activeWaypointIndex);
  }

  // ─── Camera & Gimbal ───────────────────────────────────────────────────────

  @override
  Future<void> capturePhoto() async {
    final now = DateTime.now();
    final name = 'DJI_${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}.JPG';
    
    // Adicionar à lista de mídias local mockada
    _mockMediaList.add(
      DroneMediaFile(
        id: 'media_new_${now.millisecondsSinceEpoch}',
        name: name,
        sizeBytes: 4 * 1024 * 1024,
        createdTime: now,
        type: DroneMediaType.photo,
        category: _isFlying
            ? DroneMediaCategory.inFlight
            : DroneMediaCategory.preFlight,
      ),
    );
  }

  @override
  Future<void> startIntervalShooting(int intervalSeconds) async {
    _stopIntervalPhotoTimer();
    _intervalPhotoTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      capturePhoto();
    });
  }

  @override
  Future<void> stopIntervalShooting() async {
    _stopIntervalPhotoTimer();
  }

  void _stopIntervalPhotoTimer() {
    _intervalPhotoTimer?.cancel();
  }

  @override
  Future<void> startVideoRecording() async {
    _isRecordingVideo = true;
  }

  @override
  Future<void> stopVideoRecording() async {
    if (!_isRecordingVideo) return;
    _isRecordingVideo = false;
    
    final now = DateTime.now();
    final name = 'DJI_${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}.MP4';
    
    _mockMediaList.add(
      DroneMediaFile(
        id: 'media_new_${now.millisecondsSinceEpoch}',
        name: name,
        sizeBytes: 18 * 1024 * 1024,
        createdTime: now,
        type: DroneMediaType.video,
        category: DroneMediaCategory.inFlight,
      ),
    );
  }

  @override
  Future<void> updateCameraParameters(CameraParameters params) async {
    _cameraParams = params;
  }

  @override
  Future<void> setGimbalPitch(double degree) async {
    _gimbalParams = _gimbalParams.copyWith(pitch: degree);
  }

  @override
  Future<void> updateGimbalParameters(GimbalParameters params) async {
    _gimbalParams = params;
  }

  // ─── Media Management ──────────────────────────────────────────────────────

  @override
  Future<List<DroneMediaFile>> fetchMediaList() async {
    return _mockMediaList.map((file) => file.normalized()).toList();
  }

  @override
  Future<void> downloadMediaFile(DroneMediaFile file, String destinationPath) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final dest = File(destinationPath);
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    if (file.type == DroneMediaType.photo) {
      await dest.writeAsBytes(List.filled(512, 0xFF));
    } else {
      await dest.writeAsBytes(List.filled(2048, 0x00));
    }
  }

  @override
  Future<void> deleteMediaFile(DroneMediaFile file) async {
    _mockMediaList.removeWhere((item) => item.id == file.id);
  }

  // ─── Video Streaming ───────────────────────────────────────────────────────

  @override
  Future<void> startFpvStream() async {
    _startFpvStreamLoop();
  }

  @override
  Future<void> stopFpvStream() async {
    _stopFpvStreamLoop();
  }

  void _startFpvStreamLoop() {
    _fpvTimer?.cancel();
    
    int frameCount = 0;
    _fpvTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) { // ~30 fps
      frameCount++;
      
      // Gerar frames dinâmicos simples (gradiente dinâmico com ruído)
      final width = 160;
      final height = 120;
      final yuvSize = (width * height * 1.5).toInt();
      final frame = Uint8List(yuvSize);
      
      // Preencher o canal Y com um gradiente dinâmico que se move ao longo do tempo
      final offset = (frameCount * 2) % 256;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          // Gradiente linear dependente de x, y e frame
          final brightness = ((x * 255 ~/ width) + (y * 255 ~/ height) + offset) % 256;
          frame[idx] = brightness;
        }
      }
      
      // Canais U e V (cor) constantes para criar um feed colorido de teste (esverdeado/azulado)
      final uvOffset = width * height;
      for (int i = 0; i < (yuvSize - uvOffset); i++) {
        frame[uvOffset + i] = 128 + (16 * math.sin(frameCount * 0.05)).toInt();
      }
      
      _fpvByteStreamController.add(frame);
    });
  }

  void _stopFpvStreamLoop() {
    _fpvTimer?.cancel();
  }

  // ─── Private Telemetry Loop ────────────────────────────────────────────────

  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _currentBattery = 100;
    
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Dreno de bateria
      if (_currentBattery > 0) {
        if (_isFlying) {
          _currentBattery = math.max(0, _currentBattery - (timer.tick % 5 == 0 ? 1 : 0));
        } else {
          _currentBattery = math.max(0, _currentBattery - (timer.tick % 30 == 0 ? 1 : 0));
        }
      }

      // Adicionar pequenos tremores na telemetria de posição para simular instabilidade de vento
      final windLat = _isFlying ? (math.Random().nextDouble() - 0.5) * 0.00002 : 0.0;
      final windLng = _isFlying ? (math.Random().nextDouble() - 0.5) * 0.00002 : 0.0;
      
      // GPS signal level
      final gpsLevel = 4.0 + (math.Random().nextDouble() * 1.0);
      
      // Conexão cai se a bateria for a 0
      if (_currentBattery <= 0) {
        _currentAlt = 0;
        _isFlying = false;
        disconnect();
        return;
      }

      _telemetry = DroneTelemetry(
        batteryPercentage: _currentBattery,
        latitude: _currentLat + windLat,
        longitude: _currentLng + windLng,
        altitude: _currentAlt,
        speedHorizontal: _currentSpeedHor,
        speedVertical: _currentSpeedVer,
        yaw: _currentYaw,
        pitch: _currentPitch,
        roll: _currentRoll,
        satelliteCount: _isFlying ? 16 : 12,
        gpsSignalLevel: gpsLevel,
        isFlying: _isFlying,
      );
      
      _telemetryController.add(_telemetry);
    });
  }

  void _stopTelemetryLoop() {
    _telemetryTimer?.cancel();
  }
}
