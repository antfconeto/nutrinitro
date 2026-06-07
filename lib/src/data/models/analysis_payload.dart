import 'dart:isolate';

class AnalysisPayload {
  final SendPort sendPort;
  final String imagePath;
  final String analysisDataJson;
  final String analysisType;
  final int blockSize;
 
  AnalysisPayload({
    required this.sendPort,
    required this.imagePath,
    required this.analysisDataJson,
    required this.analysisType,
    this.blockSize = 10,
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