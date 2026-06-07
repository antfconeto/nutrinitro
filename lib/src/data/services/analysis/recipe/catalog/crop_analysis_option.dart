/// Análise disponível para uma cultura, com metadados de exibição.
class CropAnalysisOption {
  final String analysisId;
  final String displayName;
  final String description;
  final String? recipeId;
  final String? recipeVersion;

  const CropAnalysisOption({
    required this.analysisId,
    required this.displayName,
    required this.description,
    this.recipeId,
    this.recipeVersion,
  });
}
