import 'dart:isolate';

class AnalysisPayload {
  final SendPort sendPort;
  final String imagePath;
  final String analysisDataJson;
  final String analysisType;
 
  AnalysisPayload({
    required this.sendPort,
    required this.imagePath,
    required this.analysisDataJson,
    required this.analysisType,
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