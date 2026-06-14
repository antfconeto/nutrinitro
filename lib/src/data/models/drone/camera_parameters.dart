import 'package:equatable/equatable.dart';

class CameraParameters extends Equatable {
  final String iso; // ex: "Auto", "100", "200", "400", "800", "1600", "3200"
  final String shutterSpeed; // ex: "Auto", "1/30", "1/60", "1/125", "1/250", "1/500", "1/1000"
  /// null = automático; caso contrário, temperatura de cor em Kelvin (ex: 5600).
  final int? whiteBalanceKelvin;
  final bool isExposureLocked;
  final String focusMode; // ex: "AF-C", "AF-S", "MF"

  const CameraParameters({
    this.iso = "Auto",
    this.shutterSpeed = "Auto",
    this.whiteBalanceKelvin,
    this.isExposureLocked = false,
    this.focusMode = "AF-C",
  });

  CameraParameters copyWith({
    String? iso,
    String? shutterSpeed,
    int? whiteBalanceKelvin,
    bool? isExposureLocked,
    String? focusMode,
  }) {
    return CameraParameters(
      iso: iso ?? this.iso,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      whiteBalanceKelvin: whiteBalanceKelvin ?? this.whiteBalanceKelvin,
      isExposureLocked: isExposureLocked ?? this.isExposureLocked,
      focusMode: focusMode ?? this.focusMode,
    );
  }

  @override
  List<Object?> get props => [
        iso,
        shutterSpeed,
        whiteBalanceKelvin,
        isExposureLocked,
        focusMode,
      ];
}
