import 'dart:io';
import 'dart:isolate';

/// Metadados de um método de predição disponível em uma análise registrada.
class AnalysisMethod {
  final String id;
  final String name;
  final String description;
  final String iconName;

  const AnalysisMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });
}

/// Contrato para análises plugáveis no [AnalysisRegistry].
abstract class RegisteredAnalysis {
  String get id;
  String get name;
  String get description;
  List<String> get supportedCropNames;
  List<AnalysisMethod> get methods => const [];
  bool get generatesImage => false;

  Future<Map<String, dynamic>> run(
    File imageFile, {
    SendPort? progressPort,
    int blockSize = 10,
    String? analysisType,
    String? recipeJson,
  });
}
