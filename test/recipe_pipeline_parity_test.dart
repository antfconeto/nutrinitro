import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/feature_stats.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/model_runners.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/validation/recipe_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe parity', () {
    late AnalysisRecipe recipe;
    late List<double> sampleFeatures;

    setUp(() async {
      final jsonString = await rootBundle.loadString('assets/recipes/marandu_nutrients_v1.json');
      recipe = AnalysisRecipe.fromJsonString(jsonString);
      const RecipeValidator().validate(recipe);

      sampleFeatures = FeatureStats.aggregateFeatures(
        channelValues: {
          'r': [0.3, 0.35, 0.32],
          'g': [0.45, 0.5, 0.48],
          'b': [0.25, 0.15, 0.2],
          'rg': [0.375, 0.425, 0.4],
          'rb': [0.275, 0.25, 0.26],
          'gb': [0.35, 0.325, 0.34],
          'rgb': [0.333, 0.333, 0.333],
        },
        channels: ['r', 'g', 'b', 'rg', 'rb', 'gb', 'rgb'],
        statistics: ['p50', 'mean', 'p75', 'p90'],
        layout: 'stat_major',
      );
    });

    test('MlpModelRunner is deterministic for parcel features', () {
      final chlorophyllModel = recipe.predictions.firstWhere((p) => p.target == 'chlorophyll');
      final mlpRunner = const MlpModelRunner();
      final first = mlpRunner.predict(sampleFeatures, chlorophyllModel.parameters);
      final second = mlpRunner.predict(sampleFeatures, chlorophyllModel.parameters);

      expect(first, second);
      expect(first, isA<double>());
    });

    test('Linear nitrogen model from SPAD', () {
      const spad = 42.5;
      final nitrogenModel = recipe.predictions.firstWhere((p) => p.target == 'nitrogen');
      final linearRunner = const LinearModelRunner();
      final nitrogen = linearRunner.predictFromValue(spad, nitrogenModel.parameters);

      expect(nitrogen, closeTo(28.5075, 0.001));
    });

    test('block proxy features have 28 dimensions', () {
      final extraction = recipe.featureExtractions.firstWhere((e) => e.id == 'rgb28_block_proxy');
      final fromStats = FeatureStats.expandBlockFeatures(
        channelValues: FeatureStats.deriveChannels(r: 0.3, g: 0.45, b: 0.25),
        channels: extraction.channels,
        repeatGroups: extraction.repeatGroups ?? 4,
      );

      expect(fromStats.length, 28);
      expect(fromStats.first, 0.3);
      expect(fromStats[7], 0.3);
    });

    test('RecipeValidator rejects invalid MLP input size', () {
      final invalid = AnalysisRecipe.fromJson({
        ...recipe.toJson(),
        'predictions': [
          {
            'target': 'chlorophyll',
            'model_type': 'mlp',
            'feature_set': 'rgb28_parcel',
            'architecture': {'input_size': 10},
            'parameters': {
              'normalization': {'means': [1.0], 'scales': [1.0]},
              'layers': [],
            },
          },
        ],
      });

      expect(
        () => const RecipeValidator().validate(invalid),
        throwsA(isA<RecipeValidationException>()),
      );
    });
  });
}
