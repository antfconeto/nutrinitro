enum WhiteBalance {
  auto,
  sunny,
  cloudy,
  incandescent,
  fluorescent;

  String get label {
    switch (this) {
      case WhiteBalance.auto:
        return 'Automático';
      case WhiteBalance.sunny:
        return 'Ensolarado';
      case WhiteBalance.cloudy:
        return 'Nublado';
      case WhiteBalance.incandescent:
        return 'Incandescente';
      case WhiteBalance.fluorescent:
        return 'Fluorescente';
    }
  }
}
