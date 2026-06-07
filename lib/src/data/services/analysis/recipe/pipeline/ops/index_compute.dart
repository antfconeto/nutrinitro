import 'package:nutrinitro/src/data/services/analysis/recipe/prediction/feature_stats.dart';

class IndexCompute {
  IndexCompute._();

  static double compute(String index, double r, double g, double b) {
    switch (index) {
      case 'exg':
        return FeatureStats.computeExg(r, g, b);
      case 'vari':
        return (g - r) / (g + r - b + 1e-6);
      default:
        throw ArgumentError('Unsupported vegetation index: $index');
    }
  }
}
