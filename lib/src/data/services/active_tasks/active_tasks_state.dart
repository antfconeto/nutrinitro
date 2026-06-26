import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

class ActiveTasksState {
  final List<MissionModel> executingMissions;
  final List<AnalysisModel> interruptedAnalyses;

  const ActiveTasksState({
    this.executingMissions = const [],
    this.interruptedAnalyses = const [],
  });

  int get totalCount => executingMissions.length + interruptedAnalyses.length;

  ActiveTasksState copyWith({
    List<MissionModel>? executingMissions,
    List<AnalysisModel>? interruptedAnalyses,
  }) {
    return ActiveTasksState(
      executingMissions: executingMissions ?? this.executingMissions,
      interruptedAnalyses: interruptedAnalyses ?? this.interruptedAnalyses,
    );
  }
}
