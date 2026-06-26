import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';

class DronePanelState extends Equatable {
  final DroneConnectionState connectionState;
  final TelemetryData? telemetry;
  final bool isConnecting;
  final String? errorMessage;

  const DronePanelState({
    this.connectionState = DroneConnectionState.disconnected,
    this.telemetry,
    this.isConnecting = false,
    this.errorMessage,
  });

  bool get isConnected => connectionState == DroneConnectionState.connected;
  bool get isDisconnected =>
      connectionState == DroneConnectionState.disconnected;
  bool get hasError => connectionState == DroneConnectionState.error;
  bool get hasTelemetry => telemetry != null;

  DronePanelState copyWith({
    DroneConnectionState? connectionState,
    TelemetryData? telemetry,
    bool? isConnecting,
    String? errorMessage,
    bool clearError = false,
    bool clearTelemetry = false,
  }) {
    return DronePanelState(
      connectionState: connectionState ?? this.connectionState,
      telemetry: clearTelemetry ? null : (telemetry ?? this.telemetry),
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    connectionState,
    telemetry,
    isConnecting,
    errorMessage,
  ];
}
