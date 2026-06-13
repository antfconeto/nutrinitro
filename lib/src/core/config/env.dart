import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'DEBUG', defaultValue: false)
  static const bool debug = _Env.debug == 'true';

  @EnviedField(varName: 'USE_MOCK_DRONE', defaultValue: true)
  static const bool useMockDrone = _Env.useMockDrone;
}
