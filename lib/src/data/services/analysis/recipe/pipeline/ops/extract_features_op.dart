import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/feature_stats.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';

class ExtractFeaturesOp extends PipelineOp {
  @override
  String get id => 'extract_features';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    if (context.blockCount <= 0) return;

    context.emitStage('features');

    final rows = context.rows;
    final cols = context.cols;
    final gridSize = context.gridSize;

    final parcelExtractions = context.recipe.featureExtractions
        .where((e) => e.scope == 'parcel')
        .toList();

    for (final extraction in parcelExtractions) {
      context.featureVectors[extraction.id] = _extract(extraction, context);
    }

    final primaryFeatures = parcelExtractions.isNotEmpty
        ? context.featureVectors[parcelExtractions.first.id]
        : null;

    context.emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'features',
      gridRows: rows,
      gridCols: cols,
      blockWidth: gridSize,
      blockHeight: gridSize,
      revealedGridRows: rows,
      vegetationBlocks: context.vegetationBlocks,
      revealedVegetationRows: rows,
      vegetationBlockCount: context.blockCount,
      rgb28Features: primaryFeatures,
      stageProgress: 0.5,
    ));

    context.emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'features',
      gridRows: rows,
      gridCols: cols,
      blockWidth: gridSize,
      blockHeight: gridSize,
      revealedGridRows: rows,
      vegetationBlocks: context.vegetationBlocks,
      revealedVegetationRows: rows,
      vegetationBlockCount: context.blockCount,
      rgb28Features: primaryFeatures,
      stageProgress: 1.0,
    ));
  }

  List<double> _extract(FeatureExtraction extraction, PipelineContext context) {
    return FeatureStats.aggregateFeatures(
      channelValues: context.parcelChannelValues,
      channels: extraction.channels,
      statistics: extraction.statistics,
      layout: extraction.layout,
    );
  }
}
