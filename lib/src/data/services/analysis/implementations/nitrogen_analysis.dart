import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/services/analysis/chlorophyll_analysis_pipeline.dart';
import 'package:nutrinitro/src/data/services/analysis/registered_analysis.dart';

/// Análise de clorofila (SPAD) e nitrogênio foliar via MLP rgb28 definitiva.
class NitrogenAnalysis extends RegisteredAnalysis {
  final ChlorophyllAnalysisPipeline _pipeline = ChlorophyllAnalysisPipeline();

  @override
  String get id => 'nitrogen';

  @override
  String get name => 'Análise de Nitrogênio';

  @override
  List<String> get supportedCropNames => ['Capim Marandu'];

  @override
  List<AnalysisMethod> get methods => const [
    AnalysisMethod(
      id: 'nitrogen_mlp',
      name: 'MLP Campeã (rgb28)',
      description:
          'Predição por parcela: bilateral, ExG>0.15, grade 10×10, 28 features (R² OOF ≈ 0.75).',
      iconName: 'psychology',
    ),
  ];

  @override
  Future<Map<String, dynamic>> run(
    File imageFile, {
    SendPort? progressPort,
    int blockSize = 10,
    String? analysisType,
  }) {
    return _pipeline.run(imageFile, progressPort: progressPort);
  }
}
