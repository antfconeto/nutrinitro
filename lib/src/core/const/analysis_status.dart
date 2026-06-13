enum AnalysisStatus {
  pending,
  processing,
  completed,
  error;

  String get label {
    switch (this) {
      case AnalysisStatus.pending:
        return 'Pendente';
      case AnalysisStatus.processing:
        return 'Processando';
      case AnalysisStatus.completed:
        return 'Concluída';
      case AnalysisStatus.error:
        return 'Erro';
    }
  }

  static AnalysisStatus fromString(String value) {
    return AnalysisStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisStatus.pending,
    );
  }
}
