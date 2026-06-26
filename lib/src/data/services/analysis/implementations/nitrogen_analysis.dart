import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_executor.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/validation/recipe_validator.dart';
import 'package:nutrinitro/src/data/services/analysis/core/registered_analysis.dart';

/// Análise de nutrientes (clorofila, nitrogênio, etc.) via receita da cultura.
class NitrogenAnalysis extends RegisteredAnalysis {
  final PipelineExecutor _executor = PipelineExecutor();
  final RecipeValidator _validator = const RecipeValidator();

  @override
  String get id => 'nitrogen';

  @override
  String get name => 'Análise de Nutrientes';

  @override
  String get description =>
      'Predição de nitrogênio foliar (g/kg) por modelo linear a partir do SPAD.';

  @override
  List<String> get supportedCropNames => const [];

  @override
  Future<Map<String, dynamic>> run(
    File imageFile, {
    SendPort? progressPort,
    int blockSize = 10,
    String? analysisType,
    String? recipeJson,
  }) async {
    if (recipeJson == null || recipeJson.isEmpty) {
      throw StateError(
        'NitrogenAnalysis requires recipeJson resolved from the database before execution.',
      );
    }

    final AnalysisRecipe recipe = AnalysisRecipe.fromJsonString(recipeJson);
    _validator.validate(recipe);
    return _executor.run(recipe, imageFile, progressPort: progressPort);
  }
}
