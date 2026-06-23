import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drone_media_view_model.g.dart';

@riverpod
class DroneMediaViewModel extends _$DroneMediaViewModel {
  @override
  DroneMediaState build() {
    Future.microtask(() => fetch());
    return const DroneMediaState();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final imageRepo = await ref.read(droneImageRepositoryProvider.future);
    final missionRepo = await ref.read(missionRepositoryProvider.future);

    final imagesResult = await imageRepo.all();
    final missionsResult = await missionRepo.all();

    final List<DroneImageModel> images;
    switch (imagesResult) {
      case Failure(:final error):
        state =
            state.copyWith(isLoading: false, errorMessage: error.toString());
        return;
      case Success(value: final v):
        images = v;
    }

    final missions = switch (missionsResult) {
      Success(value: final m) => m,
      Failure() => <MissionModel>[],
    };

    final missionMap = {for (final m in missions) m.id: m.title};
    final entries = images
        .map(
          (img) => DroneImageEntry(
            image: img,
            missionTitle:
                missionMap[img.missionId] ?? 'Missão #${img.missionId}',
          ),
        )
        .toList();
    state = state.copyWith(isLoading: false, allEntries: entries);
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setLinkedFilter(bool? value) =>
      state = state.copyWith(linkedFilter: value);

  void setDateFrom(DateTime? date) => state = state.copyWith(dateFrom: date);

  void setDateTo(DateTime? date) => state = state.copyWith(dateTo: date);

  void updateSortOrder(MediaSortOrder order) =>
      state = state.copyWith(sortOrder: order);

  void clearFilters() => state = state.copyWith(
        searchQuery: '',
        linkedFilter: null,
        dateFrom: null,
        dateTo: null,
        sortOrder: MediaSortOrder.newestFirst,
      );

  void clearSearch() => state = state.copyWith(searchQuery: '');
}
