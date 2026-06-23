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
    return const DronePanelState();
  }

  // ─── Connection ─────────────────────────────────────────────────────────────

  Future<void> connect() async {
    state = state.copyWith(isConnecting: true, clearError: true);

    try {
      final drone = ref.read(droneServiceProvider);

      _connectionSub = drone.connectionStream.listen((connectionState) {
        state = state.copyWith(connectionState: connectionState);

        if (connectionState == DroneConnectionState.connected) {
          state = state.copyWith(isConnecting: false);
          _listenTelemetry();
        }

        if (connectionState == DroneConnectionState.error) {
          state = state.copyWith(
            isConnecting: false,
            errorMessage: 'Erro ao conectar com o drone.',
          );
        }
      });

      await drone.connect();
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  Future<void> disconnect() async {
    try {
      final drone = ref.read(droneServiceProvider);
      await drone.disconnect();
      _cancelSubscriptions();
      state = state.copyWith(
        connectionState: DroneConnectionState.disconnected,
        clearTelemetry: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao desconectar: $e');
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
    final drone = ref.read(droneServiceProvider);
    _telemetrySub = drone.telemetryStream.listen((telemetry) {
      state = state.copyWith(telemetry: telemetry);
    });
  }

  void _cancelSubscriptions() {
    _connectionSub?.cancel();
    _telemetrySub?.cancel();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
