import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';

class MissionCreateState extends Equatable {
  final int? missionId;
  final bool isSubmitting;
  final bool submitted;
  final String title;
  final String? notes;
  final List<DroneWaypointModel> waypoints;
  final String? errorMessage;
  final String? successMessage;

  const MissionCreateState({
    this.missionId,
    this.isSubmitting = false,
    this.submitted = false,
    this.title = '',
    this.notes,
    this.waypoints = const [],
    this.errorMessage,
    this.successMessage,
  });

  bool get isFormValid => title.isNotEmpty && waypoints.length >= 2;
  bool get titleError => submitted && title.isEmpty;
  bool get waypointsError => submitted && waypoints.length < 2;

  MissionCreateState copyWith({
    int? missionId,
    bool? isSubmitting,
    bool? submitted,
    String? title,
    String? notes,
    List<DroneWaypointModel>? waypoints,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearNotes = false,
  }) {
    return MissionCreateState(
      missionId: missionId ?? this.missionId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      waypoints: waypoints ?? this.waypoints,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    missionId,
    isSubmitting,
    submitted,
    title,
    notes,
    waypoints,
    errorMessage,
    successMessage,
  ];
}
