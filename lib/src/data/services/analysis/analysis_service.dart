import 'dart:isolate';

import 'package:nutrinitro/src/data/models/analysis_payload.dart';

class AnalysisService {
  Future<AnalysisResult> analyze({
    required String imagePath,
    required String analysisDataJson,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _runAnalysis,
      AnalysisPayload(
        sendPort: receivePort.sendPort,
        imagePath: imagePath,
        analysisDataJson: analysisDataJson,
      ),
    );

    final result = await receivePort.first as AnalysisResult;
    return result;
  }

  static void _runAnalysis(AnalysisPayload payload) async {
    // ─────────────────────────────────────────────────────────────────────
    // TODO: replace with real image analysis model
    // e.g. TFLite, ONNX, or a local processing service
    // ─────────────────────────────────────────────────────────────────────

    // Simulates processing time
    await Future.delayed(const Duration(seconds: 2));

    final result = AnalysisResult(
      analyzedPath: payload.imagePath, // same image until real model is ready
      result: '''{
        "status": "mock",
        "crop": "detected",
        "moisture": "13.5%",
        "protein": "8.2%",
        "quality": "Good",
        "notes": "Simulated result. Real analysis pending implementation."
      }''',
    );

    payload.sendPort.send(result);
  }
}