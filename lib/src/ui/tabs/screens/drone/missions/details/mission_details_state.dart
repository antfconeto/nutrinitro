import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

class MissionDetailsState extends Equatable {
  final bool isLoading;
  final bool isStarting;
  final MissionModel? mission;
  final List<DroneImageModel> images;
  final String? errorMessage;

  const MissionDetailsState({
    this.isLoading = false,
    this.isStarting = false,
    this.mission,
    this.images = const [],
    this.errorMessage,
  });

  MissionDetailsState copyWith({
    bool? isLoading,
    bool? isStarting,
    MissionModel? mission,
    List<DroneImageModel>? images,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MissionDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isStarting: isStarting ?? this.isStarting,
      mission: mission ?? this.mission,
      images: images ?? this.images,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, isStarting, mission, images, errorMessage];
}
