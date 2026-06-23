import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/details/mission_details_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'mission_details_view_model.g.dart';

@riverpod
class MissionDetailsViewModel extends _$MissionDetailsViewModel {
  @override
  MissionDetailsState build() => const MissionDetailsState();

  Future<void> load(int missionId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = await ref.read(missionRepositoryProvider.future);
    final result = await repo.find(missionId);

    switch (result) {
      case Success(value: final mission):
        state = state.copyWith(isLoading: false, mission: mission);
        if (mission.status == MissionStatus.completed) {
          final imageRepo = await ref.read(droneImageRepositoryProvider.future);
          final imagesResult = await imageRepo.findBy('mission_id', missionId);
          if (imagesResult case Success(value: final images)) {
            state = state.copyWith(images: images);
          }
        }
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  /// Uploads the mission to the drone service and starts execution.
  /// Returns the mission ID on success so the caller can navigate to the monitor page.
  Future<int?> startMission() async {
    if (state.mission == null) return null;

    state = state.copyWith(isStarting: true, clearError: true);
    try {
      final droneService = ref.read(droneServiceProvider);
      await droneService.uploadMission(state.mission!);
      await droneService.startMission();

      final repo = await ref.read(missionRepositoryProvider.future);
      await repo.update(state.mission!.id!, {
        'status': MissionStatus.executing.name,
        'started_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(isStarting: false);
      return state.mission!.id!;
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        errorMessage: 'Erro ao iniciar missão: $e',
      );
      return null;
    }
  }

  /// Creates a new mission with the same waypoints (clone / redo).
  /// Returns the new mission's ID on success.
  Future<int?> cloneMission() async {
    if (state.mission == null) return null;

    state = state.copyWith(isStarting: true, clearError: true);
    try {
      final repo = await ref.read(missionRepositoryProvider.future);
      final result = await repo.create(
        title: '${state.mission!.title} (Repetição)',
        notes: state.mission!.notes,
        waypoints: state.mission!.waypoints,
      );
      state = state.copyWith(isStarting: false);
      switch (result) {
        case Success(value: final mission):
          return mission.id;
        case Failure(:final error):
          state = state.copyWith(errorMessage: 'Erro ao clonar missão: $error');
          return null;
      }
    } catch (e) {
      state = state.copyWith(
        isStarting: false,
        errorMessage: 'Erro ao clonar missão: $e',
      );
      return null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
