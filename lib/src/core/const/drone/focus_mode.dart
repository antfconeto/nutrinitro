enum FocusMode {
  auto,
  manual,
  infinity;

  String get label {
    switch (this) {
      case FocusMode.auto:
        return 'Automático';
      case FocusMode.manual:
        return 'Manual';
      case FocusMode.infinity:
        return 'Infinito';
    }
  }
}
