/// Extração das 28 features espaciais (7 canais × 4 estatísticas).
class Rgb28FeatureExtractor {
  Rgb28FeatureExtractor._();

  static const List<String> channelOrder = ['r', 'g', 'b', 'rg', 'rb', 'gb', 'rgb'];

  static double percentile(List<double> values, double percentileFraction) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final int idx = ((sorted.length - 1) * percentileFraction).round();
    return sorted[idx];
  }

  /// Features de um único bloco de vegetação (repetição por estatística no vetor rgb28).
  static List<double> blockFeatures({
    required double rNorm,
    required double gNorm,
    required double bNorm,
    required double rg,
    required double rb,
    required double gb,
    required double rgbCoord,
  }) {
    return [
      rNorm, gNorm, bNorm, rg, rb, gb, rgbCoord,
      rNorm, gNorm, bNorm, rg, rb, gb, rgbCoord,
      rNorm, gNorm, bNorm, rg, rb, gb, rgbCoord,
      rNorm, gNorm, bNorm, rg, rb, gb, rgbCoord,
    ];
  }

  /// Agrega listas de canais normalizados em 28 estatísticas (p50, média, p75, p90).
  static List<double> aggregateParcelFeatures({
    required List<double> rList,
    required List<double> gList,
    required List<double> bList,
    required List<double> rgList,
    required List<double> rbList,
    required List<double> gbList,
    required List<double> rgbList,
  }) {
    final List<List<double>> channelLists = [
      rList, gList, bList, rgList, rbList, gbList, rgbList,
    ];
    final List<double> features = [];

    for (final list in channelLists) {
      features.add(percentile(list, 0.50));
    }
    for (final list in channelLists) {
      features.add(list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length);
    }
    for (final list in channelLists) {
      features.add(percentile(list, 0.75));
    }
    for (final list in channelLists) {
      features.add(percentile(list, 0.90));
    }

    return features;
  }
}
