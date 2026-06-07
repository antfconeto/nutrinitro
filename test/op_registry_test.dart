import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/op_registry.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/validation/recipe_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Marandu recipe pipeline uses only registered ops', () async {
    final jsonString = await rootBundle.loadString('assets/recipes/marandu_nutrients_v1.json');
    final recipe = AnalysisRecipe.fromJsonString(jsonString);
    const RecipeValidator().validate(recipe);

    final registry = OpRegistry.standard();
    final ops = recipe.pipeline.map((s) => s.op).toList();

    expect(ops, [
      'bilateral_filter',
      'gamma_correction',
      'block_grid',
      'vegetation_mask',
      'process_blocks',
      'extract_features',
      'predict',
      'generate_heatmap',
    ]);

    for (final op in ops) {
      expect(registry.supports(op), isTrue, reason: 'Op $op should be registered');
    }
  });

  test('OpRegistry rejects unknown op at runtime', () async {
    final registry = OpRegistry.standard();
    final invalidRecipe = AnalysisRecipe.fromJson({
      'id': 'invalid',
      'version': '1.0.0',
      'name': 'Invalid',
      'targets': ['chlorophyll'],
      'pipeline': [
        {'op': 'unknown_op', 'params': {}},
      ],
      'feature_extractions': [
        {
          'id': 'f1',
          'scope': 'parcel',
          'channels': ['r'],
          'statistics': ['mean'],
          'layout': 'stat_major',
        },
      ],
      'predictions': [
        {
          'target': 'chlorophyll',
          'model_type': 'linear',
          'feature_set': 'f1',
          'parameters': {'intercept': 0, 'slope': 1},
        },
      ],
      'outputs': [],
      'ui': {
        'method_label': 'test',
        'stages': [],
      },
    });

    expect(
      () => const RecipeValidator().validate(invalidRecipe),
      throwsA(isA<RecipeValidationException>()),
    );
  });
}
