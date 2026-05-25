enum AnalysisStatus {
  pending,
  processing,
  completed,
  error;

  String get label {
    switch (this) {
      case AnalysisStatus.pending:
        return 'Pending';
      case AnalysisStatus.processing:
        return 'Processing';
      case AnalysisStatus.completed:
        return 'Completed';
      case AnalysisStatus.error:
        return 'Error';
    }
  }

  static AnalysisStatus fromString(String value) {
    return AnalysisStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisStatus.pending,
    );
  }
}
