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
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  /// Uploads the mission to the drone service and redirects to the panel.
  Future<bool> startMission() async {
    if (state.mission == null) return false;

    try {
      final droneService = ref.read(droneServiceProvider);
      await droneService.uploadMission(state.mission!);
      await droneService.startMission();

      // Update status in DB
      final repo = await ref.read(missionRepositoryProvider.future);
      await repo.update(state.mission!.id!, {
        'status': MissionStatus.executing.name,
        'started_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao iniciar missão: $e');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
