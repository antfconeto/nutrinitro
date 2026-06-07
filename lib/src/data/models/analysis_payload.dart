import 'dart:isolate';

class AnalysisPayload {
  final SendPort sendPort;
  final String imagePath;
  final String analysisDataJson;
  final String analysisType;
  final int blockSize;
  final String? recipeJson;
  final String? recipeId;
  final String? recipeVersion;

  AnalysisPayload({
    required this.sendPort,
    required this.imagePath,
    required this.analysisDataJson,
    required this.analysisType,
    this.blockSize = 10,
    this.recipeJson,
    this.recipeId,
    this.recipeVersion,
  });
}

class AnalysisResult {
  final String analyzedPath;
  final String result;

  AnalysisResult({
    required this.analyzedPath,
    required this.result,
  });
}
