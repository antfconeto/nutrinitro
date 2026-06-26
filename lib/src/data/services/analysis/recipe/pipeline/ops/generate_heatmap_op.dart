import 'dart:io';
import 'dart:typed_data';

import 'package:nutrinitro/src/data/models/analysis/analysis_recipe.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/imaging/image_analysis_helper.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_context.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/pipeline/pipeline_op.dart';

class GenerateHeatmapOp extends PipelineOp {
  @override
  String get id => 'generate_heatmap';

  @override
  Future<void> execute(PipelineStep step, PipelineContext context) async {
    if (context.blockCount <= 0) return;

    final target = step.params['target'] as String? ?? 'chlorophyll';
    final matrix = context.heatmapMatrices[target];
    final grid = context.grid;
    if (matrix == null || grid == null) return;

    final dotIndex = context.imageFile.path.lastIndexOf('.');
    final heatmapPath = dotIndex != -1
        ? '${context.imageFile.path.substring(0, dotIndex)}_heatmap.png'
        : '${context.imageFile.path}_heatmap.png';

    await ImageAnalysisHelper.generateChlorophyllHeatmap(
      chlorophyllMatrix: matrix,
      outputPath: heatmapPath,
      originalImagePath: grid.processedImagePath,
      scale: context.gridSize,
    );

    context.heatmapPath = heatmapPath;

    final chlorophyll = context.predictionValues['chlorophyll'] ?? 0.0;
    final primaryFeatures = context.featureVectors.values.isNotEmpty
        ? context.featureVectors.values.first
        : null;

    final heatmapBytes = await File(heatmapPath).readAsBytes();
    context.emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'heatmap',
      imageJpeg: heatmapBytes,
      gridRows: context.rows,
      gridCols: context.cols,
      blockWidth: context.gridSize,
      blockHeight: context.gridSize,
      revealedGridRows: context.rows,
      vegetationBlocks: context.vegetationBlocks,
      revealedVegetationRows: context.rows,
      vegetationBlockCount: context.blockCount,
      rgb28Features: primaryFeatures,
      spadPrediction: chlorophyll > 0 ? chlorophyll : null,
      stageProgress: 1.0,
    ));
  }
}
