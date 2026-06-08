import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/models/analysis_payload.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_registry.dart';

class AnalysisService {
  Future<AnalysisResult> analyze({
    required String imagePath,
    required String analysisDataJson,
    required String analysisType,
    int blockSize = 10,
    String? recipeJson,
    String? recipeId,
    String? recipeVersion,
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
        recipeJson: recipeJson,
        recipeId: recipeId,
        recipeVersion: recipeVersion,
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
    final analysis = AnalysisRegistry.getById(payload.analysisType) ??
        StandardAgronomicAnalysis();

    final resultData = await analysis.run(
      File(payload.imagePath),
      progressPort: payload.sendPort,
      blockSize: payload.blockSize,
      analysisType: payload.analysisType,
      recipeJson: payload.recipeJson,
    );

    if (payload.recipeId != null) {
      resultData['recipe_id'] = payload.recipeId;
    }
    if (payload.recipeVersion != null) {
      resultData['recipe_version'] = payload.recipeVersion;
    }

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
