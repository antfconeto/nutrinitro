import 'dart:isolate';
import 'dart:typed_data';

/// Atualização de progresso enviada do isolate para a UI durante a análise.
class AnalysisStageUpdate {
  final String id;
  final String label;
  final int step;
  final int totalSteps;

  const AnalysisStageUpdate({
    required this.id,
    required this.label,
    required this.step,
    required this.totalSteps,
  });

  double get progress => totalSteps > 0 ? step / totalSteps : 0.0;
}

/// Estágios padrão da predição de clorofila por parcela.
class ChlorophyllAnalysisStages {
  static const int total = 6;

  static const List<AnalysisStageUpdate> labels = [
    AnalysisStageUpdate(id: 'bilateral', label: 'Filtro bilateral', step: 1, totalSteps: total),
    AnalysisStageUpdate(id: 'gamma', label: 'Correção gamma (0.8)', step: 2, totalSteps: total),
    AnalysisStageUpdate(id: 'grid', label: 'Grade de blocos 10×10', step: 3, totalSteps: total),
    AnalysisStageUpdate(id: 'exg', label: 'Máscara ExG > 0.15', step: 4, totalSteps: total),
    AnalysisStageUpdate(id: 'features', label: 'Estatísticas rgb28', step: 5, totalSteps: total),
    AnalysisStageUpdate(id: 'predict', label: 'Predição por parcela', step: 6, totalSteps: total),
  ];

  static AnalysisStageUpdate byId(String id) {
    return labels.firstWhere(
      (s) => s.id == id,
      orElse: () => AnalysisStageUpdate(id: id, label: id, step: 1, totalSteps: total),
    );
  }
}

void reportAnalysisStage(SendPort? port, String id) {
  if (port == null) return;
  port.send(ChlorophyllAnalysisStages.byId(id));
}

/// Frame visual do pipeline enviado do isolate para animação na UI.
///
/// [imageJpeg] nulo significa reutilizar a última imagem recebida na UI.
class AnalysisPipelineSnapshot {
  final String stageId;
  final Uint8List? imageJpeg;
  final int imageWidth;
  final int imageHeight;
  final int gridRows;
  final int gridCols;
  final int blockWidth;
  final int blockHeight;
  final int revealedGridRows;
  final List<bool>? vegetationBlocks;
  final int revealedVegetationRows;
  final List<double>? rgb28Features;
  final double? spadPrediction;
  final double stageProgress;
  final int vegetationBlockCount;

  const AnalysisPipelineSnapshot({
    required this.stageId,
    this.imageJpeg,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.gridRows = 0,
    this.gridCols = 0,
    this.blockWidth = 10,
    this.blockHeight = 10,
    this.revealedGridRows = 0,
    this.vegetationBlocks,
    this.revealedVegetationRows = 0,
    this.rgb28Features,
    this.spadPrediction,
    this.stageProgress = 0.0,
    this.vegetationBlockCount = 0,
  });

  static const List<String> rgb28Labels = [
    'R p50', 'G p50', 'B p50', 'RG p50', 'RB p50', 'GB p50', 'RGB p50',
    'R média', 'G média', 'B média', 'RG média', 'RB média', 'GB média', 'RGB média',
    'R p75', 'G p75', 'B p75', 'RG p75', 'RB p75', 'GB p75', 'RGB p75',
    'R p90', 'G p90', 'B p90', 'RG p90', 'RB p90', 'GB p90', 'RGB p90',
  ];
}

typedef PipelineSnapshotCallback = void Function(AnalysisPipelineSnapshot snapshot);

void reportPipelineSnapshot(SendPort? port, AnalysisPipelineSnapshot snapshot) {
  port?.send(snapshot);
}
