enum MissionStatus {
  planned,
  executing,
  completed,
  aborted;

  String get label {
    switch (this) {
      case MissionStatus.planned:
        return 'Planejada';
      case MissionStatus.executing:
        return 'Em execução';
      case MissionStatus.completed:
        return 'Concluída';
      case MissionStatus.aborted:
        return 'Abortada';
    }
  }

  static MissionStatus fromString(String value) {
    return MissionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MissionStatus.planned,
    );
  }
}
