import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/models/analysis_payload.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_registry.dart';

class AnalysisService {
  Future<AnalysisResult> analyze({
    required String imagePath,
    required String analysisDataJson,
    required String analysisType,
    int blockSize = 10,
    void Function(AnalysisStageUpdate stage)? onStage,
    void Function(AnalysisPipelineSnapshot snapshot)? onSnapshot,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _runAnalysis,
      AnalysisPayload(
        sendPort: receivePort.sendPort,
        imagePath: imagePath,
        analysisDataJson: analysisDataJson,
        analysisType: analysisType,
        blockSize: blockSize,
      ),
    );

    AnalysisResult? finalResult;

    await for (final msg in receivePort) {
      if (msg is AnalysisStageUpdate) {
        onStage?.call(msg);
      } else if (msg is AnalysisPipelineSnapshot) {
        onSnapshot?.call(msg);
      } else if (msg is AnalysisResult) {
        finalResult = msg;
        break;
      }
    }

    receivePort.close();
    return finalResult!;
  }

  static void _runAnalysis(AnalysisPayload payload) async {
    // Retrieve the registered analysis dynamically from the registry
    final analysis = AnalysisRegistry.getById(payload.analysisType) ??
        StandardAgronomicAnalysis();

    // Execute the custom analysis logic safely in the isolate background
    final resultData = await analysis.run(
      File(payload.imagePath),
      progressPort: payload.sendPort,
      blockSize: payload.blockSize,
      analysisType: payload.analysisType,
    );

    final String analyzedPath = resultData['heatmap_path'] as String?
        ?? resultData['processed_image_path'] as String?
        ?? resultData['cropped_original_path'] as String?
        ?? payload.imagePath;

    final result = AnalysisResult(
      analyzedPath: analyzedPath,
      result: json.encode(resultData),
    );

    payload.sendPort.send(result);
  }
}