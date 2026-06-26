import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/extract_features_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/generate_heatmap_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/image_preprocess_ops.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/predict_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/process_blocks_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/ops/vegetation_mask_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/prediction_runner.dart';

class OpRegistry {
  final Map<String, PipelineOp> _ops;
  final PredictionRunner _predictionRunner;

  OpRegistry({
    Map<String, PipelineOp>? ops,
    PredictionRunner? predictionRunner,
  })  : _predictionRunner = predictionRunner ?? const PredictionRunner(),
        _ops = ops ?? _defaultOps(predictionRunner ?? const PredictionRunner());

  static Map<String, PipelineOp> _defaultOps(PredictionRunner predictionRunner) {
    final processBlocks = ProcessBlocksOp(predictionRunner: predictionRunner);
    final predict = PredictOp(predictionRunner: predictionRunner);

    return {
      for (final op in [
        BilateralFilterOp(),
        GammaCorrectionOp(),
        BlockGridOp(),
        VegetationMaskOp(),
        processBlocks,
        ExtractFeaturesOp(),
        predict,
        GenerateHeatmapOp(),
      ])
        op.id: op,
    };
  }

  factory OpRegistry.standard() => OpRegistry();

  bool supports(String opId) => _ops.containsKey(opId);

  List<String> get registeredOps => List.unmodifiable(_ops.keys);

  void register(PipelineOp op) {
    _ops[op.id] = op;
  }

  Future<void> execute(PipelineStep step, PipelineContext context) async {
    final handler = _ops[step.op];
    if (handler == null) {
      throw UnsupportedPipelineOpException(step.op);
    }
    await handler.execute(step, context);
  }

  Future<void> executeAll(
    List<PipelineStep> steps,
    PipelineContext context,
  ) async {
    for (final step in steps) {
      await execute(step, context);
    }
  }
}
