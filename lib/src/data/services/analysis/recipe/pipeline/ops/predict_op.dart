import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/prediction_runner.dart';

class PredictOp extends PipelineOp {
  final PredictionRunner _predictionRunner;

  PredictOp({PredictionRunner? predictionRunner})
      : _predictionRunner = predictionRunner ?? const PredictionRunner();

  @override
  String get id => 'predict';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    if (context.blockCount <= 0) return;

    context.emitStage('predict');

    final targets = step.params['targets'] as List<dynamic>?;
    final predictions = targets == null
        ? context.recipe.predictions
        : context.recipe.predictions
            .where((p) => targets.contains(p.target))
            .toList();

    for (final prediction in predictions) {
      final value = _predictionRunner.run(
        prediction,
        context.featureVectors,
        context.predictionValues,
      );
      context.predictionValues[prediction.target] = value;
    }

    final primaryFeatures = context.featureVectors.values.isNotEmpty
        ? context.featureVectors.values.first
        : null;

    context.emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'predict',
      gridRows: context.rows,
      gridCols: context.cols,
      blockWidth: context.gridSize,
      blockHeight: context.gridSize,
      revealedGridRows: context.rows,
      vegetationBlocks: context.vegetationBlocks,
      revealedVegetationRows: context.rows,
      vegetationBlockCount: context.blockCount,
      rgb28Features: primaryFeatures,
      spadPrediction: context.predictionValues['chlorophyll'],
      stageProgress: 1.0,
    ));
  }
}
