import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/op_registry.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/validation/recipe_validator.dart';

/// Orquestrador que interpreta a receita passo a passo via [OpRegistry].
class PipelineExecutor {
  final RecipeValidator _validator;
  final OpRegistry _registry;

  PipelineExecutor({
    RecipeValidator? validator,
    OpRegistry? registry,
  })  : _validator = validator ?? const RecipeValidator(),
        _registry = registry ?? OpRegistry.standard();

  OpRegistry get registry => _registry;

  Future<Map<String, dynamic>> run(
    AnalysisRecipe recipe,
    File imageFile, {
    SendPort? progressPort,
  }) async {
    _validator.validate(recipe);

    final context = PipelineContext(
      recipe: recipe,
      imageFile: imageFile,
      progressPort: progressPort,
    );

    await _registry.executeAll(recipe.pipeline, context);

    return context.toResult();
  }
}
