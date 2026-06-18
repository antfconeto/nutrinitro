import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

class MissionDetailsState extends Equatable {
  final bool isLoading;
  final MissionModel? mission;
  final String? errorMessage;

  const MissionDetailsState({
    this.isLoading = false,
    this.mission,
    this.errorMessage,
  });

  MissionDetailsState copyWith({
    bool? isLoading,
    MissionModel? mission,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MissionDetailsState(
      isLoading: isLoading ?? this.isLoading,
      mission: mission ?? this.mission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, mission, errorMessage];
}
