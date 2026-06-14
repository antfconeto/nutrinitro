import 'dart:async';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint.dart';
import 'package:nutrinitro/src/data/services/drone/drone_service_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drone_view_model.g.dart';

@riverpod
class DroneViewModel extends _$DroneViewModel {
  StreamSubscription? _connectionStateSub;
  StreamSubscription? _connectionHealthSub;
  StreamSubscription? _telemetrySub;
  StreamSubscription? _waypointSub;

  @override
  DroneState build() {
    final service = ref.watch(droneServiceProvider);
    final isSim = ref.watch(droneServiceModeProvider);

    _cancelSubscriptions();

    _connectionStateSub = service.connectionStateStream.listen((stateVal) {
      state = state.copyWith(connectionState: stateVal);
    });

    _connectionHealthSub = service.connectionHealthStream.listen((healthVal) {
      state = state.copyWith(connectionHealth: healthVal);
    });

    _telemetrySub = service.telemetryStream.listen((telemetryVal) {
      state = state.copyWith(telemetry: telemetryVal);
    });

    _waypointSub = service.activeWaypointIndexStream.listen((indexVal) {
      state = state.copyWith(activeWaypointIndex: indexVal);
    });

    ref.onDispose(() {
      _cancelSubscriptions();
    });

    return DroneState(
      telemetry: DroneTelemetry.empty(),
      isSimulatorMode: isSim,
    );
  }

  void _cancelSubscriptions() {
    _connectionStateSub?.cancel();
    _connectionHealthSub?.cancel();
    _telemetrySub?.cancel();
    _waypointSub?.cancel();
  }

  void toggleSimulatorMode(bool enable) {
    ref.read(droneServiceModeProvider.notifier).setSimulationMode(enable);
  }

  Future<void> connectDrone() async {
    final service = ref.read(droneServiceProvider);
    try {
      state = state.copyWith(clearError: true);
      await service.registerSdk();
      await service.connect();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> disconnectDrone() async {
    final service = ref.read(droneServiceProvider);
    try {
      await service.disconnect();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ─── Flight Control ────────────────────────────────────────────────────────

  Future<void> takeoff() async {
    try {
      await ref.read(droneServiceProvider).takeoff();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> land() async {
    try {
      await ref.read(droneServiceProvider).land();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> returnToHome() async {
    try {
      await ref.read(droneServiceProvider).returnToHome();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> emergencyStop() async {
    try {
      await ref.read(droneServiceProvider).emergencyStop();
      state = state.copyWith(isExecutingMission: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ─── Waypoint Mission Management ──────────────────────────────────────────

  void addWaypoint(LatLng latLng) {
    final newId = state.waypoints.length + 1;
    final wp = DroneWaypoint(
      id: newId,
      coordinate: latLng,
      altitude: 30.0, // Altitude padrão de 30 metros para captação de imagens
      speed: 5.0, // Velocidade padrão de 5 m/s
    );
    state = state.copyWith(waypoints: [...state.waypoints, wp]);
  }

  void removeWaypoint(int id) {
    final updated = state.waypoints.where((wp) => wp.id != id).toList();
    // Reindexar waypoints restantes
    final reindexed = List.generate(updated.length, (index) {
      final oldWp = updated[index];
      return oldWp.copyWith(id: index + 1);
    });
    state = state.copyWith(waypoints: reindexed);
  }

  void clearWaypoints() {
    state = state.copyWith(waypoints: const []);
  }

  void optimizeWaypoints() {
    if (state.waypoints.length < 3) return;

    final List<DroneWaypoint> optimized = [];
    final List<DroneWaypoint> remaining = List.from(state.waypoints);

    // Mantém o primeiro ponto inserido como a base da decolagem
    optimized.add(remaining.removeAt(0));

    while (remaining.isNotEmpty) {
      final current = optimized.last.coordinate;
      int nearestIdx = 0;
      double minDist = double.maxFinite;

      for (int i = 0; i < remaining.length; i++) {
        final dist = const Distance().as(LengthUnit.Meter, current, remaining[i].coordinate);
        if (dist < minDist) {
          minDist = dist;
          nearestIdx = i;
        }
      }
      optimized.add(remaining.removeAt(nearestIdx));
    }

    // Reindexar
    final reindexed = List.generate(optimized.length, (index) {
      return optimized[index].copyWith(id: index + 1);
    });

    state = state.copyWith(waypoints: reindexed);
  }

  Future<void> startMission() async {
    if (state.waypoints.isEmpty) return;
    final service = ref.read(droneServiceProvider);
    try {
      state = state.copyWith(isExecutingMission: true, clearError: true);
      await service.uploadMission(state.waypoints);
      await service.startMission();
    } catch (e) {
      state = state.copyWith(isExecutingMission: false, errorMessage: e.toString());
    }
  }

  Future<void> abortMission() async {
    final service = ref.read(droneServiceProvider);
    try {
      await service.abortMission();
      state = state.copyWith(isExecutingMission: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ─── Camera Control ────────────────────────────────────────────────────────

  Future<void> capturePhoto() async {
    try {
      await ref.read(droneServiceProvider).capturePhoto();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> toggleVideoRecording() async {
    final service = ref.read(droneServiceProvider);
    try {
      if (state.isRecordingVideo) {
        await service.stopVideoRecording();
        state = state.copyWith(isRecordingVideo: false);
      } else {
        await service.startVideoRecording();
        state = state.copyWith(isRecordingVideo: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> setGimbalPitch(double pitch) async {
    try {
      await ref.read(droneServiceProvider).setGimbalPitch(pitch);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ─── Media Gallery ─────────────────────────────────────────────────────────

  Future<List<DroneMediaFile>> fetchMediaList() async {
    final files = await ref.read(droneServiceProvider).fetchMediaList();
    return files.map((file) => file.normalized()).toList();
  }

  Future<String> downloadMediaFile(DroneMediaFile file) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'drone_media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final destination = p.join(dir.path, file.name);
    await ref.read(droneServiceProvider).downloadMediaFile(file, destination);
    return destination;
  }
}
