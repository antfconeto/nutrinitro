import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'drone_service.dart';
import 'mock_drone_service.dart';
import 'dji_drone_service.dart';

part 'drone_service_provider.g.dart';

@Riverpod(keepAlive: true)
class DroneServiceMode extends _$DroneServiceMode {
  @override
  bool build() {
    // Retorna true (simulação ativa) por padrão para desenvolvimento e testes
    return true;
  }

  void setSimulationMode(bool enable) {
    state = enable;
  }
}

@Riverpod(keepAlive: true)
DroneService droneService(Ref ref) {
  final isSimulation = ref.watch(droneServiceModeProvider);
  if (isSimulation) {
    return MockDroneService();
  } else {
    return DjiDroneService();
  }
}
