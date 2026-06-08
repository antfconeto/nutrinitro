import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/op_registry.dart';

class RecipeValidationException implements Exception {
  final String message;
  const RecipeValidationException(this.message);

  @override
  String toString() => 'RecipeValidationException: $message';
}

class RecipeValidator {
  const RecipeValidator();

  void validate(AnalysisRecipe recipe) {
    if (recipe.id.isEmpty) {
      throw const RecipeValidationException('Recipe id is required.');
    }
    if (recipe.pipeline.isEmpty) {
      throw const RecipeValidationException('Pipeline must have at least one step.');
    }
    if (recipe.featureExtractions.isEmpty) {
      throw const RecipeValidationException('At least one feature extraction is required.');
    }
    if (recipe.predictions.isEmpty) {
      throw const RecipeValidationException('At least one prediction model is required.');
    }

    final featureIds = recipe.featureExtractions.map((e) => e.id).toSet();
    if (featureIds.length != recipe.featureExtractions.length) {
      throw const RecipeValidationException('Duplicate feature extraction ids.');
    }

    _validatePipeline(recipe);

    for (final extraction in recipe.featureExtractions) {
      _validateFeatureExtraction(extraction);
    }

    final targetIds = <String>{};
    for (final prediction in recipe.predictions) {
      _validatePrediction(prediction, featureIds, targetIds);
      targetIds.add(prediction.target);
    }
  }

  void _validatePipeline(AnalysisRecipe recipe) {
    final registry = OpRegistry.standard();
    for (final step in recipe.pipeline) {
      if (!registry.supports(step.op)) {
        throw RecipeValidationException('Unsupported pipeline op "${step.op}".');
      }
    }

    final ops = recipe.pipeline.map((s) => s.op).toList();
    if (!ops.contains('block_grid')) {
      throw const RecipeValidationException('Pipeline must include block_grid.');
    }
  }

  void _validateFeatureExtraction(FeatureExtraction extraction) {
    if (!['stat_major', 'channel_major'].contains(extraction.layout)) {
      throw RecipeValidationException(
        'Feature extraction "${extraction.id}" has unsupported layout "${extraction.layout}".',
      );
    }
    if (extraction.channels.isEmpty) {
      throw RecipeValidationException(
        'Feature extraction "${extraction.id}" must define channels.',
      );
    }

    if (extraction.scope == 'parcel') {
      if (extraction.statistics.isEmpty) {
        throw RecipeValidationException(
          'Parcel feature extraction "${extraction.id}" must define statistics.',
        );
      }
      final expected = extraction.channels.length * extraction.statistics.length;
      if (extraction.outputSize != null && extraction.outputSize != expected) {
        throw RecipeValidationException(
          'Feature extraction "${extraction.id}" output_size mismatch: '
          'expected $expected, got ${extraction.outputSize}.',
        );
      }
    }

    if (extraction.scope == 'block') {
      final groups = extraction.repeatGroups ?? 1;
      final expected = extraction.channels.length * groups;
      if (extraction.outputSize != null && extraction.outputSize != expected) {
        throw RecipeValidationException(
          'Block feature extraction "${extraction.id}" output_size mismatch: '
          'expected $expected, got ${extraction.outputSize}.',
        );
      }
    }
  }

  void _validatePrediction(
    PredictionModel prediction,
    Set<String> featureIds,
    Set<String> existingTargets,
  ) {
    if (existingTargets.contains(prediction.target)) {
      throw RecipeValidationException(
        'Duplicate prediction target "${prediction.target}".',
      );
    }

    switch (prediction.modelType) {
      case 'mlp':
        _validateMlp(prediction, featureIds);
      case 'linear':
        _validateLinear(prediction, featureIds, existingTargets);
      default:
        throw RecipeValidationException(
          'Unsupported model_type "${prediction.modelType}" for target "${prediction.target}".',
        );
    }
  }

  void _validateMlp(PredictionModel prediction, Set<String> featureIds) {
    final featureSet = prediction.featureSet;
    if (featureSet == null || !featureIds.contains(featureSet)) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" references unknown feature_set "$featureSet".',
      );
    }

    final architecture = prediction.architecture;
    if (architecture == null) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" requires architecture.',
      );
    }

    final inputSize = (architecture['input_size'] as num?)?.toInt();
    if (inputSize == null || inputSize <= 0) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" requires positive input_size.',
      );
    }

    final params = prediction.parameters;
    final normalization = params['normalization'] as Map<String, dynamic>?;
    if (normalization == null) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" requires normalization parameters.',
      );
    }

    final means = normalization['means'] as List<dynamic>?;
    final scales = normalization['scales'] as List<dynamic>?;
    if (means == null || scales == null || means.length != inputSize || scales.length != inputSize) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" normalization size must match input_size.',
      );
    }

    final layers = params['layers'] as List<dynamic>?;
    if (layers == null || layers.isEmpty) {
      throw RecipeValidationException(
        'MLP target "${prediction.target}" requires at least one layer.',
      );
    }
  }

  void _validateLinear(
    PredictionModel prediction,
    Set<String> featureIds,
    Set<String> existingTargets,
  ) {
    if (prediction.dependsOn != null) {
      final dep = prediction.dependsOn!.target;
      if (!existingTargets.contains(dep)) {
        throw RecipeValidationException(
          'Linear target "${prediction.target}" depends on "$dep" which must be defined first.',
        );
      }
      return;
    }

    final featureSet = prediction.featureSet;
    if (featureSet == null || !featureIds.contains(featureSet)) {
      throw RecipeValidationException(
        'Linear target "${prediction.target}" references unknown feature_set "$featureSet".',
      );
    }
  }
}
