enum GpsSignalLevel {
  none,
  poor,
  fair,
  good,
  excellent;

  String get label {
    switch (this) {
      case GpsSignalLevel.none:
        return 'Sem sinal';
      case GpsSignalLevel.poor:
        return 'Fraco';
      case GpsSignalLevel.fair:
        return 'Regular';
      case GpsSignalLevel.good:
        return 'Bom';
      case GpsSignalLevel.excellent:
        return 'Excelente';
    }
  }
}
