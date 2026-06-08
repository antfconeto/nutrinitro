import 'package:nutrinitro/src/data/services/analysis/implementations/nitrogen_analysis.dart';
import 'package:nutrinitro/src/data/services/analysis/core/registered_analysis.dart';
import 'package:nutrinitro/src/data/services/analysis/implementations/standard_agronomic_analysis.dart';

export 'package:nutrinitro/src/data/services/analysis/implementations/nitrogen_analysis.dart';
export 'package:nutrinitro/src/data/services/analysis/core/registered_analysis.dart';
export 'package:nutrinitro/src/data/services/analysis/implementations/standard_agronomic_analysis.dart';

/// Registro central de análises disponíveis no app.
class AnalysisRegistry {
  static final Map<String, RegisteredAnalysis> _registry = {
    'agronomic': StandardAgronomicAnalysis(),
    'nitrogen': NitrogenAnalysis(),
  };

  static final List<RegisteredAnalysis> _analyses = [
    _registry['agronomic']!,
    _registry['nitrogen']!,
  ];

  static List<RegisteredAnalysis> get all => List.unmodifiable(_analyses);

  static RegisteredAnalysis? getById(String id) {
    final String normalized = _normalizeId(id);
    return _registry[normalized];
  }

  static void register(RegisteredAnalysis analysis) {
    _registry[analysis.id] = analysis;
    if (!_analyses.any((a) => a.id == analysis.id)) {
      _analyses.add(analysis);
    }
  }

  /// Compatibilidade com IDs legados salvos no banco ou em JSONs antigos.
  static String _normalizeId(String id) {
    const nitrogenAliases = {
      'nitrogen',
      'chlorophyll',
      'nitrogen_mlp',
      'chlorophyll_mlp',
      'nitrogen_si',
      'chlorophyll_si',
      'nitrogen_br',
      'chlorophyll_br',
      'biomass_fusion',
      'biomass_fusion_mlp',
      'biomass_fusion_si',
    };

    if (nitrogenAliases.contains(id)) {
      return 'nitrogen';
    }
    return id;
  }
}
