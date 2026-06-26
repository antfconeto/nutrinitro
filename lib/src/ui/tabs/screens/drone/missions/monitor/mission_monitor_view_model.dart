import 'dart:async';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/monitor/mission_monitor_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mission_monitor_view_model.g.dart';

@riverpod
class MissionMonitorViewModel extends _$MissionMonitorViewModel {
  StreamSubscription<TelemetryData>? _telemetrySub;
  StreamSubscription<int>? _progressSub;
  StreamSubscription<String>? _photoSub;

  @override
  MissionMonitorState build() {
    ref.onDispose(_cancelSubs);
    return const MissionMonitorState();
  }

  Future<void> init(int missionId) async {
    state = state.copyWith(isLoading: true);

    final repo = await ref.read(missionRepositoryProvider.future);
    final result = await repo.find(missionId);

    switch (result) {
      case Success(value: final mission):
        final drone = ref.read(droneServiceProvider);
        state = state.copyWith(
          isLoading: false,
          mission: mission,
          telemetry: drone.lastTelemetry,
        );
        _subscribeStreams();
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  void _subscribeStreams() {
    final drone = ref.read(droneServiceProvider);
    _telemetrySub = drone.telemetryStream.listen(_onTelemetry);
    _progressSub = drone.missionProgressStream.listen(_onProgress);
    _photoSub = drone.missionPhotoStream.listen(_onPhoto);
  }

  void _onTelemetry(TelemetryData data) {
    state = state.copyWith(telemetry: data);

    // Detect completion: all waypoints visited and drone has landed
    if (state.isLastWaypointReached &&
        !state.isMissionComplete &&
        !state.isAborting &&
        data.altitude < 1.0) {
      _completeMission();
    }
  }

  void _onProgress(int index) {
    state = state.copyWith(currentWaypointIndex: index);
  }

  void _onPhoto(String path) async {
    state = state.copyWith(photoCount: state.photoCount + 1);

    final missionId = state.mission?.id;
    if (missionId == null) return;

    final tel = state.telemetry;
    final image = DroneImageModel(
      missionId: missionId,
      localPath: path,
      latitude: tel?.latitude,
      longitude: tel?.longitude,
      altitude: tel?.altitude,
      datetime: DateTime.now(),
    );

    final imageRepo = await ref.read(droneImageRepositoryProvider.future);
    await imageRepo.create(image);
  }

  void _completeMission() async {
    final missionId = state.mission?.id;
    if (missionId == null) return;

    state = state.copyWith(isMissionComplete: true);

    final repo = await ref.read(missionRepositoryProvider.future);
    await repo.update(missionId, {
      'status': MissionStatus.completed.name,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> togglePause() async {
    final drone = ref.read(droneServiceProvider);
    try {
      if (state.isPaused) {
        await drone.resumeFlight();
        state = state.copyWith(isPaused: false);
      } else {
        await drone.pauseFlight();
        state = state.copyWith(isPaused: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro: $e');
    }
  }

  /// Returns true if abort succeeded so the caller can navigate away.
  Future<bool> abortMission() async {
    state = state.copyWith(isAborting: true);
    try {
      await ref.read(droneServiceProvider).abortMission();

      final missionId = state.mission?.id;
      if (missionId != null) {
        final repo = await ref.read(missionRepositoryProvider.future);
        await repo.update(missionId, {'status': MissionStatus.aborted.name});
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isAborting: false,
        errorMessage: 'Erro ao abortar: $e',
      );
      return false;
    }
  }

  void _cancelSubs() {
    _telemetrySub?.cancel();
    _progressSub?.cancel();
    _photoSub?.cancel();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
