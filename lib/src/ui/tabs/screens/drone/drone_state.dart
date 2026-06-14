import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint.dart';

class DroneState extends Equatable {
  final DroneConnectionState connectionState;
  final ConnectionHealth connectionHealth;
  final DroneTelemetry telemetry;
  final List<DroneWaypoint> waypoints;
  final int activeWaypointIndex;
  final bool isSimulatorMode;
  final bool isRecordingVideo;
  final bool isExecutingMission;
  final String? errorMessage;

  const DroneState({
    this.connectionState = DroneConnectionState.disconnected,
    this.connectionHealth = ConnectionHealth.none,
    required this.telemetry,
    this.waypoints = const [],
    this.activeWaypointIndex = -1,
    this.isSimulatorMode = true, // Simulação ativa por padrão para testes locais
    this.isRecordingVideo = false,
    this.isExecutingMission = false,
    this.errorMessage,
  });

  DroneState copyWith({
    DroneConnectionState? connectionState,
    ConnectionHealth? connectionHealth,
    DroneTelemetry? telemetry,
    List<DroneWaypoint>? waypoints,
    int? activeWaypointIndex,
    bool? isSimulatorMode,
    bool? isRecordingVideo,
    bool? isExecutingMission,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneState(
      connectionState: connectionState ?? this.connectionState,
      connectionHealth: connectionHealth ?? this.connectionHealth,
      telemetry: telemetry ?? this.telemetry,
      waypoints: waypoints ?? this.waypoints,
      activeWaypointIndex: activeWaypointIndex ?? this.activeWaypointIndex,
      isSimulatorMode: isSimulatorMode ?? this.isSimulatorMode,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isExecutingMission: isExecutingMission ?? this.isExecutingMission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        connectionState,
        connectionHealth,
        telemetry,
        waypoints,
        activeWaypointIndex,
        isSimulatorMode,
        isRecordingVideo,
        isExecutingMission,
        errorMessage,
      ];
}
