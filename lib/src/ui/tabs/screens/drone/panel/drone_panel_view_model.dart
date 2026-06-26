import 'dart:async';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/panel/drone_panel_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drone_panel_view_model.g.dart';

@riverpod
class DronePanelViewModel extends _$DronePanelViewModel {
  StreamSubscription<dynamic>? _connectionSub;
  StreamSubscription<dynamic>? _telemetrySub;

  @override
  DronePanelState build() {
    ref.onDispose(_cancelSubscriptions);

    final drone = ref.read(droneServiceProvider);

    // Subscribe immediately so state stays in sync even after navigating away and back
    _connectionSub = drone.connectionStream.listen(_onConnectionState);

    if (drone.connectionState == DroneConnectionState.connected) {
      _listenTelemetry();
    }

    return DronePanelState(
      connectionState: drone.connectionState,
      telemetry: drone.lastTelemetry,
    );
  }

  // ─── Connection ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      await ref.read(droneServiceProvider).connect();
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  Future<void> disconnect() async {
    try {
      await ref.read(droneServiceProvider).disconnect();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao desconectar: $e');
    }
  }

  void _onConnectionState(DroneConnectionState connectionState) {
    state = state.copyWith(connectionState: connectionState, isConnecting: false);

    if (connectionState == DroneConnectionState.connected) {
      _listenTelemetry();
    }

    if (connectionState == DroneConnectionState.error) {
      state = state.copyWith(errorMessage: 'Erro ao conectar com o drone.');
    }

    if (connectionState == DroneConnectionState.disconnected) {
      _telemetrySub?.cancel();
      _telemetrySub = null;
      state = state.copyWith(clearTelemetry: true);
    }
  }

  // ─── Flight control ─────────────────────────────────────────────────────────

  Future<void> takeoff() async {
    try {
      await ref.read(droneServiceProvider).takeoff();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao decolar: $e');
    }
  }

  Future<void> land() async {
    try {
      await ref.read(droneServiceProvider).land();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao pousar: $e');
    }
  }

  Future<void> returnToHome() async {
    try {
      await ref.read(droneServiceProvider).returnToHome();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao retornar: $e');
    }
  }

  Future<void> emergencyStop() async {
    try {
      await ref.read(droneServiceProvider).emergencyStop();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao parar: $e');
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _listenTelemetry() {
    _telemetrySub?.cancel();
    _telemetrySub = ref.read(droneServiceProvider).telemetryStream.listen((t) {
      state = state.copyWith(telemetry: t);
    });
  }

  void _cancelSubscriptions() {
    _connectionSub?.cancel();
    _telemetrySub?.cancel();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
