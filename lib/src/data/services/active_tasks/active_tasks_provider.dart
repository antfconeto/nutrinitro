import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/active_tasks/active_tasks_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_tasks_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveTasks extends _$ActiveTasks {
  @override
  ActiveTasksState build() {
    Future.microtask(_fetch);
    return const ActiveTasksState();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final missionRepo = await ref.read(missionRepositoryProvider.future);
      final analysisRepo = await ref.read(analysisRepositoryProvider.future);

      final missionsResult = await missionRepo.findByStatus(MissionStatus.executing);
      final analysesResult = await analysisRepo.findActive();

      state = ActiveTasksState(
        executingMissions: switch (missionsResult) {
          Success(:final value) => value,
          Failure() => [],
        },
        interruptedAnalyses: switch (analysesResult) {
          Success(:final value) => value,
          Failure() => [],
        },
      );
    } catch (_) {}
  }
}
