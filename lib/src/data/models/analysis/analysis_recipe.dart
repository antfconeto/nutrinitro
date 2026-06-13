import 'dart:convert';

class AnalysisRecipe {
  final String id;
  final String version;
  final String name;
  final List<String> targets;
  final List<PipelineStep> pipeline;
  final List<FeatureExtraction> featureExtractions;
  final List<PredictionModel> predictions;
  final List<String> outputs;
  final RecipeUiConfig ui;

  const AnalysisRecipe({
    required this.id,
    required this.version,
    required this.name,
    required this.targets,
    required this.pipeline,
    required this.featureExtractions,
    required this.predictions,
    required this.outputs,
    required this.ui,
  });

  factory AnalysisRecipe.fromJson(Map<String, dynamic> json) {
    return AnalysisRecipe(
      id: json['id'] as String,
      version: json['version'] as String,
      name: json['name'] as String,
      targets: (json['targets'] as List<dynamic>).map((e) => e as String).toList(),
      pipeline: (json['pipeline'] as List<dynamic>)
          .map((e) => PipelineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      featureExtractions: (json['feature_extractions'] as List<dynamic>)
          .map((e) => FeatureExtraction.fromJson(e as Map<String, dynamic>))
          .toList(),
      predictions: (json['predictions'] as List<dynamic>)
          .map((e) => PredictionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>).map((e) => e as String).toList(),
      ui: RecipeUiConfig.fromJson(json['ui'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'name': name,
        'targets': targets,
        'pipeline': pipeline.map((e) => e.toJson()).toList(),
        'feature_extractions': featureExtractions.map((e) => e.toJson()).toList(),
        'predictions': predictions.map((e) => e.toJson()).toList(),
        'outputs': outputs,
        'ui': ui.toJson(),
      };

  String toJsonString() => json.encode(toJson());

  factory AnalysisRecipe.fromJsonString(String source) =>
      AnalysisRecipe.fromJson(json.decode(source) as Map<String, dynamic>);

  ImagePreprocessConfig get imagePreprocess {
    int bilateralD = 9;
    double sigmaColor = 75;
    double sigmaSpace = 75;
    double gamma = 0.8;
    int blockSize = 10;

    for (final step in pipeline) {
      switch (step.op) {
        case 'bilateral_filter':
          bilateralD = (step.params['d'] as num?)?.toInt() ?? bilateralD;
          sigmaColor = (step.params['sigma_color'] as num?)?.toDouble() ?? sigmaColor;
          sigmaSpace = (step.params['sigma_space'] as num?)?.toDouble() ?? sigmaSpace;
        case 'gamma_correction':
          gamma = (step.params['gamma'] as num?)?.toDouble() ?? gamma;
        case 'block_grid':
          blockSize = (step.params['block_size'] as num?)?.toInt() ?? blockSize;
      }
    }

    return ImagePreprocessConfig(
      bilateralD: bilateralD,
      sigmaColor: sigmaColor,
      sigmaSpace: sigmaSpace,
      gamma: gamma,
      blockSize: blockSize,
    );
  }

  VegetationMaskConfig? get vegetationMask {
    for (final step in pipeline) {
      if (step.op == 'vegetation_mask') {
        return VegetationMaskConfig.fromParams(step.params);
      }
    }
    return null;
  }
}

class PipelineStep {
  final String op;
  final Map<String, dynamic> params;

  const PipelineStep({required this.op, this.params = const {}});

  factory PipelineStep.fromJson(Map<String, dynamic> json) => PipelineStep(
        op: json['op'] as String,
        params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {'op': op, 'params': params};
}

class FeatureExtraction {
  final String id;
  final String scope;
  final List<String> channels;
  final List<String> statistics;
  final String layout;
  final int? outputSize;
  final int? repeatGroups;

  const FeatureExtraction({
    required this.id,
    required this.scope,
    required this.channels,
    required this.statistics,
    required this.layout,
    this.outputSize,
    this.repeatGroups,
  });

  factory FeatureExtraction.fromJson(Map<String, dynamic> json) => FeatureExtraction(
        id: json['id'] as String,
        scope: json['scope'] as String,
        channels: (json['channels'] as List<dynamic>).map((e) => e as String).toList(),
        statistics: (json['statistics'] as List<dynamic>).map((e) => e as String).toList(),
        layout: json['layout'] as String,
        outputSize: (json['output_size'] as num?)?.toInt(),
        repeatGroups: (json['repeat_groups'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope,
        'channels': channels,
        'statistics': statistics,
        'layout': layout,
        if (outputSize != null) 'output_size': outputSize,
        if (repeatGroups != null) 'repeat_groups': repeatGroups,
      };
}

class PredictionModel {
  final String target;
  final String modelType;
  final String? featureSet;
  final Map<String, dynamic>? architecture;
  final Map<String, dynamic> parameters;
  final PredictionDependency? dependsOn;

  const PredictionModel({
    required this.target,
    required this.modelType,
    this.featureSet,
    this.architecture,
    required this.parameters,
    this.dependsOn,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) => PredictionModel(
        target: json['target'] as String,
        modelType: json['model_type'] as String,
        featureSet: json['feature_set'] as String?,
        architecture: json['architecture'] != null
            ? Map<String, dynamic>.from(json['architecture'] as Map)
            : null,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
        dependsOn: json['depends_on'] != null
            ? PredictionDependency.fromJson(json['depends_on'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'target': target,
        'model_type': modelType,
        if (featureSet != null) 'feature_set': featureSet,
        if (architecture != null) 'architecture': architecture,
        'parameters': parameters,
        if (dependsOn != null) 'depends_on': dependsOn!.toJson(),
      };
}

class PredictionDependency {
  final String target;

  const PredictionDependency({required this.target});

  factory PredictionDependency.fromJson(Map<String, dynamic> json) =>
      PredictionDependency(target: json['target'] as String);

  Map<String, dynamic> toJson() => {'target': target};
}

class RecipeUiConfig {
  final String methodLabel;
  final String? description;
  final List<RecipeStage> stages;

  const RecipeUiConfig({
    required this.methodLabel,
    this.description,
    required this.stages,
  });

  factory RecipeUiConfig.fromJson(Map<String, dynamic> json) => RecipeUiConfig(
        methodLabel: json['method_label'] as String,
        description: json['description'] as String?,
        stages: (json['stages'] as List<dynamic>)
            .map((e) => RecipeStage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'method_label': methodLabel,
        if (description != null) 'description': description,
        'stages': stages.map((e) => e.toJson()).toList(),
      };
}

class RecipeStage {
  final String id;
  final String label;

  const RecipeStage({required this.id, required this.label});

  factory RecipeStage.fromJson(Map<String, dynamic> json) => RecipeStage(
        id: json['id'] as String,
        label: json['label'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

class ImagePreprocessConfig {
  final int bilateralD;
  final double sigmaColor;
  final double sigmaSpace;
  final double gamma;
  final int blockSize;

  const ImagePreprocessConfig({
    required this.bilateralD,
    required this.sigmaColor,
    required this.sigmaSpace,
    required this.gamma,
    required this.blockSize,
  });
}

class VegetationMaskConfig {
  final String index;
  final String operator;
  final double threshold;

  const VegetationMaskConfig({
    required this.index,
    required this.operator,
    required this.threshold,
  });

  factory VegetationMaskConfig.fromParams(Map<String, dynamic> params) =>
      VegetationMaskConfig(
        index: params['index'] as String? ?? 'exg',
        operator: params['operator'] as String? ?? 'gt',
        threshold: (params['threshold'] as num?)?.toDouble() ?? 0.15,
      );

  bool passes(double indexValue) {
    switch (operator) {
      case 'gt':
        return indexValue > threshold;
      case 'gte':
        return indexValue >= threshold;
      case 'lt':
        return indexValue < threshold;
      case 'lte':
        return indexValue <= threshold;
      default:
        return indexValue > threshold;
    }
  }
}

class AnalysisRecipeRecord {
  final String id;
  final String name;
  final String version;
  final List<String> targets;
  final String recipeJson;
  final bool isActive;

  const AnalysisRecipeRecord({
    required this.id,
    required this.name,
    required this.version,
    required this.targets,
    required this.recipeJson,
    this.isActive = true,
  });

  AnalysisRecipe toRecipe() => AnalysisRecipe.fromJsonString(recipeJson);

  factory AnalysisRecipeRecord.fromMap(Map<String, dynamic> map) {
    final targetsJson = map['targets'] as String;
    return AnalysisRecipeRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      version: map['version'] as String,
      targets: (json.decode(targetsJson) as List<dynamic>).map((e) => e as String).toList(),
      recipeJson: map['recipe_json'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'version': version,
        'targets': json.encode(targets),
        'recipe_json': recipeJson,
        'is_active': isActive ? 1 : 0,
      };

  factory AnalysisRecipeRecord.fromRecipe(AnalysisRecipe recipe) =>
      AnalysisRecipeRecord(
        id: recipe.id,
        name: recipe.name,
        version: recipe.version,
        targets: recipe.targets,
        recipeJson: recipe.toJsonString(),
      );
}
