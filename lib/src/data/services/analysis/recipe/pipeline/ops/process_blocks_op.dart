import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/feature_stats.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/index_compute.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/prediction_runner.dart';

class ProcessBlocksOp extends PipelineOp {
  static const int maxProgressiveFrames = 28;

  final PredictionRunner _predictionRunner;

  ProcessBlocksOp({PredictionRunner? predictionRunner})
      : _predictionRunner = predictionRunner ?? const PredictionRunner();

  @override
  String get id => 'process_blocks';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    final grid = context.grid;
    if (grid == null) {
      throw StateError('process_blocks requires block_grid to run first.');
    }

    context.emitStage('exg');

    final rgbMatrix = grid.matrix;
    final rows = context.rows;
    final cols = context.cols;
    final gridSize = context.gridSize;
    final mask = context.vegetationMask;

    final blockExtractions = context.recipe.featureExtractions
        .where((e) => e.scope == 'block')
        .toList();

    final heatmapTarget = step.params['heatmap_target'] as String? ?? 'chlorophyll';
    final heatmapPrediction = _findPrediction(context.recipe, heatmapTarget);
    final FeatureExtraction? blockExtraction =
        blockExtractions.isNotEmpty ? blockExtractions.first : null;

    context.vegetationBlocks = List.filled(rows * cols, false);
    context.parcelChannelValues.clear();
    context.blockCount = 0;

    if (heatmapPrediction != null) {
      context.heatmapMatrices[heatmapTarget] = List.generate(
        rows,
        (_) => List.filled(cols, -1.0),
      );
    }

    final heatmapMatrix = context.heatmapMatrices[heatmapTarget];
    final exgStep = _progressiveStep(rows);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rgb = rgbMatrix[r][c];
        final double sum = rgb.r + rgb.g + rgb.b;
        if (sum <= 0.0) continue;

        final double rNorm = rgb.r / sum;
        final double gNorm = rgb.g / sum;
        final double bNorm = rgb.b / sum;
        final channels = FeatureStats.deriveChannels(r: rNorm, g: gNorm, b: bNorm);

        final double indexValue = IndexCompute.compute(mask.index, rNorm, gNorm, bNorm);
        final bool isVegetation = mask.passes(indexValue);
        context.vegetationBlocks[r * cols + c] = isVegetation;
        if (!isVegetation) continue;

        for (final entry in channels.entries) {
          context.parcelChannelValues.putIfAbsent(entry.key, () => []).add(entry.value);
        }

        if (blockExtraction != null && heatmapPrediction != null && heatmapMatrix != null) {
          final blockFeatures = FeatureStats.expandBlockFeatures(
            channelValues: channels,
            channels: blockExtraction.channels,
            repeatGroups: blockExtraction.repeatGroups ?? 4,
          );
          heatmapMatrix[r][c] = _predictionRunner.predict(heatmapPrediction, blockFeatures);
        }

        context.blockCount++;
      }

      final bool emitExgFrame = r == 0 || r == rows - 1 || (r + 1) % exgStep == 0;
      if (emitExgFrame) {
        context.emitSnapshot(AnalysisPipelineSnapshot(
          stageId: 'exg',
          gridRows: rows,
          gridCols: cols,
          blockWidth: gridSize,
          blockHeight: gridSize,
          revealedGridRows: rows,
          vegetationBlocks: List<bool>.from(context.vegetationBlocks),
          revealedVegetationRows: r + 1,
          vegetationBlockCount: context.blockCount,
          stageProgress: (r + 1) / rows,
        ));
      }
    }

    context.emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'exg',
      gridRows: rows,
      gridCols: cols,
      blockWidth: gridSize,
      blockHeight: gridSize,
      revealedGridRows: rows,
      vegetationBlocks: context.vegetationBlocks,
      revealedVegetationRows: rows,
      vegetationBlockCount: context.blockCount,
      stageProgress: 1.0,
    ));
  }

  PredictionModel? _findPrediction(AnalysisRecipe recipe, String target) {
    for (final prediction in recipe.predictions) {
      if (prediction.target == target) return prediction;
    }
    return null;
  }

  static int _progressiveStep(int total) {
    if (total <= 0) return 1;
    return (total / maxProgressiveFrames).ceil().clamp(1, total);
  }
}
