import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/services/drone/drone_service_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_view_model.dart';

void main() {
  group('Drone Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is disconnected and simulator is active', () {
      final state = container.read(droneViewModelProvider);
      
      expect(state.connectionState, equals(DroneConnectionState.disconnected));
      expect(state.isSimulatorMode, isTrue);
      expect(state.waypoints, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('Connecting changes connection state to connected', () async {
      // Escutar o provider para mantê-lo ativo durante as chamadas assíncronas
      final keepAliveSub = container.listen(droneViewModelProvider, (_, __) {});
      final viewModel = container.read(droneViewModelProvider.notifier);
      
      await viewModel.connectDrone();
      
      // Pequeno delay para processar os eventos assíncronos das Streams do MockDroneService
      await Future.delayed(const Duration(seconds: 2));
      
      final state = container.read(droneViewModelProvider);
      expect(state.connectionState, equals(DroneConnectionState.connected));
      expect(state.connectionHealth, equals(ConnectionHealth.excellent));
      
      keepAliveSub.close();
    });

    test('Disconnecting changes connection state back to disconnected', () async {
      final keepAliveSub = container.listen(droneViewModelProvider, (_, __) {});
      final viewModel = container.read(droneViewModelProvider.notifier);
      
      await viewModel.connectDrone();
      await Future.delayed(const Duration(seconds: 2));
      
      await viewModel.disconnectDrone();
      await Future.delayed(const Duration(milliseconds: 600));
      
      final state = container.read(droneViewModelProvider);
      expect(state.connectionState, equals(DroneConnectionState.disconnected));
      
      keepAliveSub.close();
    });

    test('Adding, clearing, and removing waypoints works correctly', () {
      final viewModel = container.read(droneViewModelProvider.notifier);

      viewModel.addWaypoint(const LatLng(-21.0, -47.0));
      viewModel.addWaypoint(const LatLng(-21.1, -47.1));
      
      var state = container.read(droneViewModelProvider);
      expect(state.waypoints.length, equals(2));
      expect(state.waypoints[0].id, equals(1));
      expect(state.waypoints[1].id, equals(2));

      // Remove the first waypoint
      viewModel.removeWaypoint(1);
      state = container.read(droneViewModelProvider);
      expect(state.waypoints.length, equals(1));
      expect(state.waypoints[0].id, equals(1)); // Should have reindexed to 1

      // Clear all
      viewModel.clearWaypoints();
      state = container.read(droneViewModelProvider);
      expect(state.waypoints, isEmpty);
    });

    test('Waypoint path optimization orders nearest points first', () {
      final viewModel = container.read(droneViewModelProvider.notifier);

      // Decolagem / Ponto Inicial
      viewModel.addWaypoint(const LatLng(-21.000, -47.000));
      // Ponto distante
      viewModel.addWaypoint(const LatLng(-21.010, -47.010));
      // Ponto próximo
      viewModel.addWaypoint(const LatLng(-21.001, -47.001));

      viewModel.optimizeWaypoints();
      final state = container.read(droneViewModelProvider);

      expect(state.waypoints.length, equals(3));
      // O primeiro ponto deve permanecer o mesmo
      expect(state.waypoints[0].coordinate.latitude, equals(-21.000));
      // O segundo ponto deve ser o mais próximo (-21.001) ao invés do distante (-21.010)
      expect(state.waypoints[1].coordinate.latitude, equals(-21.001));
      expect(state.waypoints[2].coordinate.latitude, equals(-21.010));
    });
  });
}
