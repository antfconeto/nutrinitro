import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

class DroneMissionsState extends Equatable {
  final bool isLoading;
  final List<MissionModel> missions;
  final String? errorMessage;

  const DroneMissionsState({
    this.isLoading = false,
    this.missions = const [],
    this.errorMessage,
  });

  DroneMissionsState copyWith({
    bool? isLoading,
    List<MissionModel>? missions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneMissionsState(
      isLoading: isLoading ?? this.isLoading,
      missions: missions ?? this.missions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, missions, errorMessage];
}