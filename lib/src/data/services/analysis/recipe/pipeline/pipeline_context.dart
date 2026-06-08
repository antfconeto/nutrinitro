import 'dart:io';
import 'dart:isolate';

import 'package:nutrinitro/src/data/models/recipe/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/imaging/image_analysis_helper.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/recipe_result_builder.dart';

class PipelineContext {
  final AnalysisRecipe recipe;
  final File imageFile;
  final SendPort? progressPort;

  ImagePreprocessConfig preprocessConfig = const ImagePreprocessConfig(
    bilateralD: 9,
    sigmaColor: 75,
    sigmaSpace: 75,
    gamma: 0.8,
    blockSize: 10,
  );

  VegetationMaskConfig vegetationMask = const VegetationMaskConfig(
    index: 'exg',
    operator: 'gt',
    threshold: 0.15,
  );

  ImageBlockGrid? grid;
  int rows = 0;
  int cols = 0;

  final Map<String, List<double>> parcelChannelValues = {};
  List<bool> vegetationBlocks = const [];
  final Map<String, List<List<double>>> heatmapMatrices = {};
  final Map<String, List<double>> featureVectors = {};
  final Map<String, double> predictionValues = {};

  int blockCount = 0;
  String? heatmapPath;

  late final List<AnalysisStageUpdate> stageCatalog = analysisStagesFromRecipe(recipe);

  PipelineContext({
    required this.recipe,
    required this.imageFile,
    this.progressPort,
  });

  int get gridSize => preprocessConfig.blockSize;

  void emitSnapshot(AnalysisPipelineSnapshot snapshot) {
    reportPipelineSnapshot(progressPort, snapshot);
  }

  void emitStage(String stageId) {
    reportAnalysisStage(progressPort, stageId, stageCatalog);
  }

  Map<String, dynamic> toResult() => const RecipeResultBuilder().build(this);
}
