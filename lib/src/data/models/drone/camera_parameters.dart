import 'package:nutrinitro/src/core/const/drone/focus_mode.dart';
import 'package:nutrinitro/src/core/const/drone/white_balance.dart';

class CameraParameters {
  final int iso;
  final double shutterSpeed;
  final WhiteBalance whiteBalance;
  final FocusMode focusMode;
  final bool exposureLock;
  final double gimbalPitch;

  const CameraParameters({
    this.iso = 100,
    this.shutterSpeed = 0.001,
    this.whiteBalance = WhiteBalance.auto,
    this.focusMode = FocusMode.auto,
    this.exposureLock = false,
    this.gimbalPitch = -90.0,
  });

  CameraParameters copyWith({
    int? iso,
    double? shutterSpeed,
    WhiteBalance? whiteBalance,
    FocusMode? focusMode,
    bool? exposureLock,
    double? gimbalPitch,
  }) {
    return CameraParameters(
      iso: iso ?? this.iso,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      focusMode: focusMode ?? this.focusMode,
      exposureLock: exposureLock ?? this.exposureLock,
      gimbalPitch: gimbalPitch ?? this.gimbalPitch,
    );
  }

  @override
  String toString() =>
      'CameraParameters(iso: $iso, shutter: $shutterSpeed, wb: $whiteBalance, focus: $focusMode)';

  @override
  bool operator ==(covariant CameraParameters other) {
    if (identical(this, other)) return true;
    return other.iso == iso &&
        other.shutterSpeed == shutterSpeed &&
        other.whiteBalance == whiteBalance &&
        other.focusMode == focusMode &&
        other.exposureLock == exposureLock &&
        other.gimbalPitch == gimbalPitch;
  }

  @override
  int get hashCode =>
      iso.hashCode ^
      shutterSpeed.hashCode ^
      whiteBalance.hashCode ^
      focusMode.hashCode ^
      exposureLock.hashCode ^
      gimbalPitch.hashCode;
}
