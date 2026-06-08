import 'dart:math' as math;

class LinearModelRunner {
  const LinearModelRunner();

  double predictFromFeatures(List<double> features, Map<String, dynamic> parameters) {
    final coefficients = parameters['coefficients'] as List<dynamic>?;
    final intercept = (parameters['intercept'] as num?)?.toDouble() ?? 0.0;

    if (coefficients != null) {
      double sum = intercept;
      for (int i = 0; i < coefficients.length; i++) {
        final coef = (coefficients[i] as num).toDouble();
        final value = i < features.length ? features[i] : 0.0;
        sum += coef * value;
      }
      return _applyClamp(sum, parameters);
    }

    final slope = (parameters['slope'] as num?)?.toDouble() ?? 0.0;
    final input = features.isNotEmpty ? features.first : 0.0;
    return _applyClamp(intercept + slope * input, parameters);
  }

  double predictFromValue(double input, Map<String, dynamic> parameters) {
    final intercept = (parameters['intercept'] as num?)?.toDouble() ?? 0.0;
    final slope = (parameters['slope'] as num?)?.toDouble() ?? 0.0;
    if (input <= 0 && parameters.containsKey('zero_if_non_positive')) {
      return 0.0;
    }
    return _applyClamp(intercept + slope * input, parameters);
  }

  double _applyClamp(double value, Map<String, dynamic> parameters) {
    final clampMin = (parameters['clamp_min'] as num?)?.toDouble();
    if (clampMin != null) {
      return math.max(clampMin, value);
    }
    return value;
  }
}

class MlpModelRunner {
  const MlpModelRunner();

  double predict(List<double> rawFeatures, Map<String, dynamic> parameters) {
    final normalization = parameters['normalization'] as Map<String, dynamic>;
    final means = (normalization['means'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
    final scales = (normalization['scales'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

    if (rawFeatures.length != means.length) {
      throw ArgumentError(
        'Feature vector length ${rawFeatures.length} does not match normalization size ${means.length}.',
      );
    }

    final List<double> scaled = List.filled(rawFeatures.length, 0.0);
    for (int i = 0; i < rawFeatures.length; i++) {
      scaled[i] = (rawFeatures[i] - means[i]) / scales[i];
    }

    final layers = parameters['layers'] as List<dynamic>;
    List<double> activations = scaled;

    for (int layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      final layer = layers[layerIndex] as Map<String, dynamic>;
      final bias = (layer['bias'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      final activation = layer['activation'] as String? ??
          (layerIndex == layers.length - 1 ? 'linear' : 'relu');
      final weights = layer['weights'];

      if (weights is Map<String, dynamic>) {
        activations = _matmulColumns(weights, activations, bias, activation: activation);
      } else if (weights is List<dynamic>) {
        final w = weights.map((e) => (e as num).toDouble()).toList();
        double sum = bias.isNotEmpty ? bias.first : 0.0;
        for (int i = 0; i < activations.length && i < w.length; i++) {
          sum += activations[i] * w[i];
        }
        activations = [sum];
      } else {
        throw ArgumentError('Unsupported MLP weight format.');
      }
    }

    return activations.isNotEmpty ? activations.first : 0.0;
  }

  List<double> _matmulColumns(
    Map<String, dynamic> weights,
    List<double> input,
    List<double> bias, {
    required String activation,
  }) {
    final cols = (weights['cols'] as num).toInt();
    final rows = (weights['rows'] as num).toInt();
    final data = weights['data'] as List<dynamic>;

    final List<double> output = List.filled(cols, 0.0);
    for (int c = 0; c < cols; c++) {
      double sum = c < bias.length ? bias[c] : 0.0;
      final column = data[c] as List<dynamic>;
      for (int r = 0; r < rows && r < input.length; r++) {
        sum += input[r] * (column[r] as num).toDouble();
      }
      output[c] = activation == 'relu' ? math.max(0.0, sum) : sum;
    }
    return output;
  }
}
