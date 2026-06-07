import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/recipe_result_builder.dart';

void main() {
  final recipe = AnalysisRecipe.fromJson({
    'id': 'test_recipe',
    'version': '1.0.0',
    'name': 'Teste',
    'targets': ['chlorophyll', 'nitrogen'],
    'pipeline': [
      {'op': 'block_grid', 'params': {'block_size': 10}},
    ],
    'feature_extractions': [],
    'predictions': [],
    'outputs': [
      'chlorophyll_spad',
      'nitrogen_content',
      'vegetation_blocks',
      'prediction_method',
    ],
    'ui': {
      'method_label': 'Modelo Teste',
      'stages': [],
    },
  });

  test('builds result from recipe.outputs and predictionValues', () {
    final context = PipelineContext(
      recipe: recipe,
      imageFile: File('/tmp/test.jpg'),
    );
    context.predictionValues['chlorophyll'] = 42.5;
    context.predictionValues['nitrogen'] = 28.5075;
    context.blockCount = 15;

    final result = const RecipeResultBuilder().build(context);

    expect(result['chlorophyll_spad'], '42.5 SPAD');
    expect(result['nitrogen_content'], '28.51 g/kg');
    expect(result['vegetation_blocks'], 15);
    expect(result['prediction_method'], 'Modelo Teste');
    expect(result['predictions'], {'chlorophyll': 42.5, 'nitrogen': 28.5075});
    expect(result['recipe_id'], 'test_recipe');
  });

  test('supports future target via output key convention', () {
    final moistureRecipe = AnalysisRecipe.fromJson({
      ...recipe.toJson(),
      'targets': ['moisture'],
      'outputs': ['moisture_content'],
    });

    final context = PipelineContext(
      recipe: moistureRecipe,
      imageFile: File('/tmp/test.jpg'),
    );
    context.predictionValues['moisture'] = 13.4;

    final result = const RecipeResultBuilder().build(context);

    expect(result['moisture_content'], '13.40');
    expect(result['predictions'], {'moisture': 13.4});
  });
}
