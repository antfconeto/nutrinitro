import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/imaging/image_analysis_helper.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';

class BilateralFilterOp extends PipelineOp {
  @override
  String get id => 'bilateral_filter';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    final current = context.preprocessConfig;
    context.preprocessConfig = ImagePreprocessConfig(
      bilateralD: (step.params['d'] as num?)?.toInt() ?? current.bilateralD,
      sigmaColor: (step.params['sigma_color'] as num?)?.toDouble() ?? current.sigmaColor,
      sigmaSpace: (step.params['sigma_space'] as num?)?.toDouble() ?? current.sigmaSpace,
      gamma: current.gamma,
      blockSize: current.blockSize,
    );
  }
}

class GammaCorrectionOp extends PipelineOp {
  @override
  String get id => 'gamma_correction';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    final current = context.preprocessConfig;
    context.preprocessConfig = ImagePreprocessConfig(
      bilateralD: current.bilateralD,
      sigmaColor: current.sigmaColor,
      sigmaSpace: current.sigmaSpace,
      gamma: (step.params['gamma'] as num?)?.toDouble() ?? current.gamma,
      blockSize: current.blockSize,
    );
  }
}

class BlockGridOp extends PipelineOp {
  @override
  String get id => 'block_grid';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    final current = context.preprocessConfig;
    final blockSize = (step.params['block_size'] as num?)?.toInt() ?? current.blockSize;

    context.preprocessConfig = ImagePreprocessConfig(
      bilateralD: current.bilateralD,
      sigmaColor: current.sigmaColor,
      sigmaSpace: current.sigmaSpace,
      gamma: current.gamma,
      blockSize: blockSize,
    );

    final preprocess = context.preprocessConfig;
    context.grid = await ImageAnalysisHelper.calculateBlockRgbAverages(
      context.imageFile,
      blockWidth: preprocess.blockSize,
      blockHeight: preprocess.blockSize,
      bilateralDiameter: preprocess.bilateralD,
      bilateralSigmaColor: preprocess.sigmaColor,
      bilateralSigmaSpace: preprocess.sigmaSpace,
      gamma: preprocess.gamma,
      onStage: (stage) => context.progressPort?.send(stage),
      onSnapshot: context.emitSnapshot,
      stageCatalog: context.stageCatalog,
    );

    context.rows = context.grid!.matrix.length;
    context.cols = context.rows > 0 ? context.grid!.matrix[0].length : 0;
  }
}
