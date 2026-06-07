import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/services/analysis/registered_analysis.dart';

class StandardAgronomicAnalysis extends RegisteredAnalysis {
  @override
  String get id => 'agronomic';

  @override
  String get name => 'Análise Agronômica Padrão';

  @override
  List<String> get supportedCropNames => ['Milho', 'Feijao'];

  @override
  Future<Map<String, dynamic>> run(
    File imageFile, {
    SendPort? progressPort,
    int blockSize = 10,
    String? analysisType,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'status': 'mock',
      'crop': 'detected',
      'moisture': '13.5%',
      'protein': '8.2%',
      'quality': 'Good',
      'notes': 'Simulated result. Real analysis pending implementation.',
    };
  }
}
