import 'package:equatable/equatable.dart';

enum GimbalMode {
  fpv,
  free,
  yawFollow,
}

class GimbalParameters extends Equatable {
  final double pitch; // -90.0 (pointing down) to +30.0 (pointing up)
  final GimbalMode mode;

  const GimbalParameters({
    this.pitch = 0.0,
    this.mode = GimbalMode.yawFollow,
  });

  GimbalParameters copyWith({
    double? pitch,
    GimbalMode? mode,
  }) {
    return GimbalParameters(
      pitch: pitch ?? this.pitch,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [pitch, mode];
}
