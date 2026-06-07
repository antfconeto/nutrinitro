class FeatureStats {
  FeatureStats._();

  static double percentile(List<double> values, double percentileFraction) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final int idx = ((sorted.length - 1) * percentileFraction).round();
    return sorted[idx];
  }

  static double mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double computeStat(List<double> values, String stat) {
    switch (stat) {
      case 'p50':
        return percentile(values, 0.50);
      case 'mean':
        return mean(values);
      case 'p75':
        return percentile(values, 0.75);
      case 'p90':
        return percentile(values, 0.90);
      default:
        throw ArgumentError('Unsupported statistic: $stat');
    }
  }

  static List<double> aggregateFeatures({
    required Map<String, List<double>> channelValues,
    required List<String> channels,
    required List<String> statistics,
    required String layout,
  }) {
    switch (layout) {
      case 'stat_major':
        return _aggregateStatMajor(channelValues, channels, statistics);
      case 'channel_major':
        return _aggregateChannelMajor(channelValues, channels, statistics);
      default:
        throw ArgumentError('Unsupported feature layout: $layout');
    }
  }

  static List<double> _aggregateStatMajor(
    Map<String, List<double>> channelValues,
    List<String> channels,
    List<String> statistics,
  ) {
    final List<double> features = [];
    for (final stat in statistics) {
      for (final channel in channels) {
        final values = channelValues[channel] ?? const [];
        features.add(computeStat(values, stat));
      }
    }
    return features;
  }

  static List<double> _aggregateChannelMajor(
    Map<String, List<double>> channelValues,
    List<String> channels,
    List<String> statistics,
  ) {
    final List<double> features = [];
    for (final channel in channels) {
      final values = channelValues[channel] ?? const [];
      for (final stat in statistics) {
        features.add(computeStat(values, stat));
      }
    }
    return features;
  }

  static List<double> expandBlockFeatures({
    required Map<String, double> channelValues,
    required List<String> channels,
    required int repeatGroups,
  }) {
    final List<double> base = [
      for (final channel in channels) channelValues[channel] ?? 0.0,
    ];
    return [
      for (int i = 0; i < repeatGroups; i++) ...base,
    ];
  }

  static Map<String, double> deriveChannels({
    required double r,
    required double g,
    required double b,
  }) {
    return {
      'r': r,
      'g': g,
      'b': b,
      'rg': (r + g) / 2.0,
      'rb': (r + b) / 2.0,
      'gb': (g + b) / 2.0,
      'rgb': (r + g + b) / 3.0,
    };
  }

  static double computeExg(double r, double g, double b) => 2.0 * g - r - b;
}
