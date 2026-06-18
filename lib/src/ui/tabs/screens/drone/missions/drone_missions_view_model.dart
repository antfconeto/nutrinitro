import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/drone_missions_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drone_missions_view_model.g.dart';

@riverpod
class DroneMissionsViewModel extends _$DroneMissionsViewModel {
  @override
  DroneMissionsState build() {
    Future.microtask(() => fetchMissions());
    return const DroneMissionsState();
  }

  Future<void> fetchMissions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = await ref.read(missionRepositoryProvider.future);
    final result = await repo.all();

    switch (result) {
      case Success(value: final missions):
        state = state.copyWith(isLoading: false, missions: missions);
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  Future<bool> delete(int missionId) async {
    final repo = await ref.read(missionRepositoryProvider.future);
    final storageService = ref.read(storageServiceProvider);

    final result = await repo.delete(missionId);

    switch (result) {
      case Success():
        await storageService.deleteMissionFiles(missionId);
        state = state.copyWith(
          missions: state.missions.where((m) => m.id != missionId).toList(),
        );
        return true;
      case Failure(:final error):
        state = state.copyWith(errorMessage: error.toString());
        return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
