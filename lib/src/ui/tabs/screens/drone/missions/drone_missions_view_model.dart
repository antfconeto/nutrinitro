import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
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
        state = state.copyWith(isLoading: false, allMissions: missions);
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void toggleStatusFilter(MissionStatus status) {
    final current = List<MissionStatus>.from(state.statusFilter);
    if (current.contains(status)) {
      current.remove(status);
    } else {
      current.add(status);
    }
    state = state.copyWith(statusFilter: current);
  }

  void setDateFrom(DateTime? date) => state = state.copyWith(dateFrom: date);

  void setDateTo(DateTime? date) => state = state.copyWith(dateTo: date);

  void updateSortOrder(MissionSortOrder order) =>
      state = state.copyWith(sortOrder: order);

  void clearFilters() => state = state.copyWith(
        searchQuery: '',
        statusFilter: [],
        dateFrom: null,
        dateTo: null,
        sortOrder: MissionSortOrder.newestFirst,
      );

  Future<bool> delete(int missionId) async {
    final repo = await ref.read(missionRepositoryProvider.future);
    final storageService = ref.read(storageServiceProvider);

    final result = await repo.delete(missionId);

    switch (result) {
      case Success():
        await storageService.deleteMissionFiles(missionId);
        state = state.copyWith(
          allMissions:
              state.allMissions.where((m) => m.id != missionId).toList(),
        );
        return true;
      case Failure(:final error):
        state = state.copyWith(errorMessage: error.toString());
        return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
