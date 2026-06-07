import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';

class VegetationMaskOp extends PipelineOp {
  @override
  String get id => 'vegetation_mask';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    context.vegetationMask = VegetationMaskConfig.fromParams(step.params);
  }
}
