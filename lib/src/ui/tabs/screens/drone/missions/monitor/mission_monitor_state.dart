import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';

class MissionMonitorState extends Equatable {
  final bool isLoading;
  final MissionModel? mission;
  final TelemetryData? telemetry;
  final int currentWaypointIndex;
  final bool isPaused;
  final bool isAborting;
  final bool isMissionComplete;
  final int photoCount;
  final String? errorMessage;

  const MissionMonitorState({
    this.isLoading = false,
    this.mission,
    this.telemetry,
    this.currentWaypointIndex = -1,
    this.isPaused = false,
    this.isAborting = false,
    this.isMissionComplete = false,
    this.photoCount = 0,
    this.errorMessage,
  });

  bool get hasTelemetry => telemetry != null;

  bool get isLastWaypointReached {
    final total = mission?.waypoints.length ?? 0;
    return total > 0 && currentWaypointIndex >= total - 1;
  }

  LatLng? get dronePosition => telemetry != null
      ? LatLng(telemetry!.latitude, telemetry!.longitude)
      : null;

  int get totalWaypoints => mission?.waypoints.length ?? 0;

  MissionMonitorState copyWith({
    bool? isLoading,
    MissionModel? mission,
    TelemetryData? telemetry,
    int? currentWaypointIndex,
    bool? isPaused,
    bool? isAborting,
    bool? isMissionComplete,
    int? photoCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MissionMonitorState(
      isLoading: isLoading ?? this.isLoading,
      mission: mission ?? this.mission,
      telemetry: telemetry ?? this.telemetry,
      currentWaypointIndex:
          currentWaypointIndex ?? this.currentWaypointIndex,
      isPaused: isPaused ?? this.isPaused,
      isAborting: isAborting ?? this.isAborting,
      isMissionComplete: isMissionComplete ?? this.isMissionComplete,
      photoCount: photoCount ?? this.photoCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    mission,
    telemetry,
    currentWaypointIndex,
    isPaused,
    isAborting,
    isMissionComplete,
    photoCount,
    errorMessage,
  ];
}
