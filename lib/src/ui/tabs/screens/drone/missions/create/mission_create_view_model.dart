import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mission_create_view_model.g.dart';

@riverpod
class MissionCreateViewModel extends _$MissionCreateViewModel {
  @override
  MissionCreateState build() => const MissionCreateState();

  // ─── Init from existing mission (edit mode) ────────────────────────────────

  void initFromMission(MissionModel mission) {
    state = state.copyWith(
      missionId: mission.id,
      title: mission.title,
      notes: mission.notes,
      waypoints: mission.waypoints,
    );
  }

  // ─── Form ──────────────────────────────────────────────────────────────────

  void updateTitle(String value) =>
      state = state.copyWith(title: value, clearError: true);

  void updateNotes(String? value) =>
      state = state.copyWith(notes: value, clearError: true);

  // ─── Waypoints ─────────────────────────────────────────────────────────────

  void addWaypoint(LatLng point) {
    final newWaypoint = DroneWaypointModel(
      missionId: 0,
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: 50.0,
      speed: 5.0,
      heading: 0.0,
      capturePhoto: true,
      orderIndex: state.waypoints.length,
    );
    state = state.copyWith(
      waypoints: [...state.waypoints, newWaypoint],
      clearError: true,
    );
  }

  void updateWaypoint(int index, DroneWaypointModel updated) {
    final list = List<DroneWaypointModel>.from(state.waypoints)
      ..[index] = updated;
    state = state.copyWith(waypoints: list);
  }

  void insertWaypoint(int afterIndex, LatLng position) {
    final prev = state.waypoints[afterIndex];
    final newWp = DroneWaypointModel(
      missionId: 0,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: prev.altitude,
      speed: prev.speed,
      heading: 0.0,
      capturePhoto: prev.capturePhoto,
      orderIndex: afterIndex + 1,
    );
    final list = List<DroneWaypointModel>.from(state.waypoints)
      ..insert(afterIndex + 1, newWp);
    final reordered = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(orderIndex: e.key))
        .toList();
    state = state.copyWith(waypoints: reordered, clearError: true);
  }

  void moveWaypoint(int index, LatLng position) {
    final list = List<DroneWaypointModel>.from(state.waypoints)
      ..[index] = state.waypoints[index].copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
        );
    state = state.copyWith(waypoints: list);
  }

  void removeWaypoint(int index) {
    final list = List<DroneWaypointModel>.from(state.waypoints)
      ..removeAt(index);
    final reordered = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(orderIndex: e.key))
        .toList();
    state = state.copyWith(waypoints: reordered);
  }

  void reorderWaypoints(int oldIndex, int newIndex) {
    final list = List<DroneWaypointModel>.from(state.waypoints);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final reordered = list
        .asMap()
        .entries
        .map((e) => e.value.copyWith(orderIndex: e.key))
        .toList();
    state = state.copyWith(waypoints: reordered);
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    state = state.copyWith(submitted: true);
    if (!state.isFormValid) return;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final repo = await ref.read(missionRepositoryProvider.future);
      final editing = state.missionId != null;

      final result = editing
          ? await repo.updateWithWaypoints(
              missionId: state.missionId!,
              title: state.title,
              notes: state.notes,
              waypoints: state.waypoints,
            )
          : await repo.create(
              title: state.title,
              notes: state.notes,
              waypoints: state.waypoints,
            );

      switch (result) {
        case Failure(:final error):
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
          );
        case Success():
          state = state.copyWith(
            isSubmitting: false,
            successMessage: editing
                ? 'Missão atualizada com sucesso!'
                : 'Missão criada com sucesso!',
          );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}
