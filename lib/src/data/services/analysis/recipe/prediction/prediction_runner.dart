import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/model_runners.dart';

class PredictionRunner {
  final MlpModelRunner _mlpRunner;
  final LinearModelRunner _linearRunner;

  const PredictionRunner({
    MlpModelRunner? mlpRunner,
    LinearModelRunner? linearRunner,
  })  : _mlpRunner = mlpRunner ?? const MlpModelRunner(),
        _linearRunner = linearRunner ?? const LinearModelRunner();

  double predict(
    PredictionModel model,
    List<double> features,
  ) {
    switch (model.modelType) {
      case 'mlp':
        return _mlpRunner.predict(features, model.parameters);
      case 'linear':
        return _linearRunner.predictFromFeatures(features, model.parameters);
      default:
        throw StateError('Unsupported model type: ${model.modelType}');
    }
  }

  double run(
    PredictionModel prediction,
    Map<String, List<double>> featureVectors,
    Map<String, double> predictionValues,
  ) {
    if (prediction.dependsOn != null) {
      final depValue = predictionValues[prediction.dependsOn!.target] ?? 0.0;
      final params = Map<String, dynamic>.from(prediction.parameters);
      if (prediction.target == 'nitrogen') {
        params['zero_if_non_positive'] = true;
      }
      return _linearRunner.predictFromValue(depValue, params);
    }

    final features = featureVectors[prediction.featureSet ?? ''];
    if (features == null) {
      throw StateError(
        'Feature set "${prediction.featureSet}" not found for ${prediction.target}.',
      );
    }
    return predict(prediction, features);
  }
}
