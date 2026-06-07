import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';

/// Monta o JSON de resultado a partir de [recipe.outputs] e [predictionValues].
class RecipeResultBuilder {
  const RecipeResultBuilder();

  Map<String, dynamic> build(PipelineContext context) {
    final recipe = context.recipe;
    final result = <String, dynamic>{
      'status': 'success',
      'recipe_id': recipe.id,
      'recipe_version': recipe.version,
      'predictions': Map<String, double>.from(context.predictionValues),
      'notes': _buildNotes(context),
    };

    for (final outputKey in recipe.outputs) {
      final value = _resolveOutput(outputKey, context);
      if (value != null) {
        result[outputKey] = value;
      }
    }

    return result;
  }

  dynamic _resolveOutput(String key, PipelineContext context) {
    switch (key) {
      case 'chlorophyll_spad':
        return _formatTarget('chlorophyll', context);
      case 'nitrogen_content':
        return _formatTarget('nitrogen', context);
      case 'heatmap_path':
        return context.heatmapPath;
      case 'vegetation_blocks':
        return context.blockCount;
      case 'prediction_method':
        return context.recipe.ui.methodLabel;
      case 'processed_image_path':
        return context.grid?.processedImagePath;
      case 'processed_width':
        return context.grid?.imageWidth;
      case 'processed_height':
        return context.grid?.imageHeight;
      default:
        // Suporte a outputs derivados de targets: ex. "protein_content" → target "protein"
        final target = _targetFromOutputKey(key);
        if (target != null && context.predictionValues.containsKey(target)) {
          return _formatTarget(target, context);
        }
        return null;
    }
  }

  String? _targetFromOutputKey(String outputKey) {
    const suffixes = ['_content', '_spad', '_value', '_estimate'];
    for (final suffix in suffixes) {
      if (outputKey.endsWith(suffix)) {
        return outputKey.substring(0, outputKey.length - suffix.length);
      }
    }
    return null;
  }

  String? _formatTarget(String target, PipelineContext context) {
    final value = context.predictionValues[target];
    if (value == null) return null;

    final format = _targetFormats[target];
    if (format == null) {
      return value.toStringAsFixed(2);
    }
    return '${value.toStringAsFixed(format.decimals)} ${format.unit}'.trim();
  }

  String _buildNotes(PipelineContext context) {
    final parts = <String>[];
    for (final target in context.recipe.targets) {
      final formatted = _formatTarget(target, context);
      if (formatted != null) {
        parts.add('${_targetLabels[target] ?? target}: $formatted');
      }
    }

    final details = parts.isEmpty ? '' : ' ${parts.join('. ')}.';
    return 'Análise (${context.recipe.ui.methodLabel}) concluída.$details';
  }
}

class _TargetFormat {
  final int decimals;
  final String unit;

  const _TargetFormat({required this.decimals, required this.unit});
}

const Map<String, _TargetFormat> _targetFormats = {
  'chlorophyll': _TargetFormat(decimals: 1, unit: 'SPAD'),
  'nitrogen': _TargetFormat(decimals: 2, unit: 'g/kg'),
};

const Map<String, String> _targetLabels = {
  'chlorophyll': 'Clorofila',
  'nitrogen': 'Nitrogênio estimado',
};
