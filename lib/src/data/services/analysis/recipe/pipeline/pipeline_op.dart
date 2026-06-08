import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';

/// Handler de uma operação atômica do pipeline.
abstract class PipelineOp {
  String get id;

  Future<void> execute(
    PipelineStep step,
    PipelineContext context,
  );
}

class UnsupportedPipelineOpException implements Exception {
  final String op;
  const UnsupportedPipelineOpException(this.op);

  @override
  String toString() => 'UnsupportedPipelineOpException: $op';
}
