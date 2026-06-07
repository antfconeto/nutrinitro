import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:nutrinitro/src/data/services/analysis/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/analysis/chlorophyll_mlp_predictor.dart';
import 'package:nutrinitro/src/data/services/analysis/image_analysis_helper.dart';
import 'package:nutrinitro/src/data/services/analysis/rgb28_feature_extractor.dart';

/// Pipeline definitivo: bilateral → gamma → grade 10×10 → ExG → rgb28 → MLP.
class ChlorophyllAnalysisPipeline {
  static const double exgThreshold = 0.15;
  static const int modelBlockSize = 10;
  static const int maxProgressiveFrames = 28;
  static const String methodLabel = 'MLP Campeã (bilateral, rgb28, R²≈0.75)';

  static int _progressiveStep(int total) {
    if (total <= 0) return 1;
    return (total / maxProgressiveFrames).ceil().clamp(1, total);
  }

  Future<Map<String, dynamic>> run(
    File imageFile, {
    SendPort? progressPort,
  }) async {
    final int gridSize = modelBlockSize;

    void emitSnapshot(AnalysisPipelineSnapshot snapshot) {
      reportPipelineSnapshot(progressPort, snapshot);
    }

    final ImageBlockGrid grid = await ImageAnalysisHelper.calculateBlockRgbAverages(
      imageFile,
      blockWidth: gridSize,
      blockHeight: gridSize,
      onStage: (stage) => progressPort?.send(stage),
      onSnapshot: emitSnapshot,
    );
    final List<List<RgbColor>> rgbMatrix = grid.matrix;

    reportAnalysisStage(progressPort, 'exg');

    final int rows = rgbMatrix.length;
    final int cols = rows > 0 ? rgbMatrix[0].length : 0;

    final List<double> rList = [];
    final List<double> gList = [];
    final List<double> bList = [];
    final List<double> rgList = [];
    final List<double> rbList = [];
    final List<double> gbList = [];
    final List<double> rgbList = [];
    final List<bool> vegetationBlocks = List.filled(rows * cols, false);
    final List<List<double>> chlorophyllMatrix = List.generate(
      rows,
      (_) => List.filled(cols, -1.0),
    );

    int blockCount = 0;
    final int exgStep = _progressiveStep(rows);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rgb = rgbMatrix[r][c];
        final double rVal = rgb.r;
        final double gVal = rgb.g;
        final double bVal = rgb.b;

        final double sum = rVal + gVal + bVal;
        if (sum <= 0.0) continue;

        final double rNorm = rVal / sum;
        final double gNorm = gVal / sum;
        final double bNorm = bVal / sum;

        final double exg = 2.0 * gNorm - rNorm - bNorm;
        final bool isVegetation = exg > exgThreshold;
        vegetationBlocks[r * cols + c] = isVegetation;
        if (!isVegetation) continue;

        final double rg = (rNorm + gNorm) / 2.0;
        final double rb = (rNorm + bNorm) / 2.0;
        final double gb = (gNorm + bNorm) / 2.0;
        final double rgbCoord = (rNorm + gNorm + bNorm) / 3.0;

        chlorophyllMatrix[r][c] = ChlorophyllMlpPredictor.predict(
          Rgb28FeatureExtractor.blockFeatures(
            rNorm: rNorm,
            gNorm: gNorm,
            bNorm: bNorm,
            rg: rg,
            rb: rb,
            gb: gb,
            rgbCoord: rgbCoord,
          ),
        );

        rList.add(rNorm);
        gList.add(gNorm);
        bList.add(bNorm);
        rgList.add(rg);
        rbList.add(rb);
        gbList.add(gb);
        rgbList.add(rgbCoord);
        blockCount++;
      }

      final bool emitExgFrame = r == 0 || r == rows - 1 || (r + 1) % exgStep == 0;
      if (emitExgFrame) {
        emitSnapshot(AnalysisPipelineSnapshot(
          stageId: 'exg',
          gridRows: rows,
          gridCols: cols,
          blockWidth: gridSize,
          blockHeight: gridSize,
          revealedGridRows: rows,
          vegetationBlocks: List<bool>.from(vegetationBlocks),
          revealedVegetationRows: r + 1,
          vegetationBlockCount: blockCount,
          stageProgress: (r + 1) / rows,
        ));
      }
    }

    emitSnapshot(AnalysisPipelineSnapshot(
      stageId: 'exg',
      gridRows: rows,
      gridCols: cols,
      blockWidth: gridSize,
      blockHeight: gridSize,
      revealedGridRows: rows,
      vegetationBlocks: vegetationBlocks,
      revealedVegetationRows: rows,
      vegetationBlockCount: blockCount,
      stageProgress: 1.0,
    ));

    reportAnalysisStage(progressPort, 'features');

    double averageChlorophyll = 0.0;
    List<double>? features;

    if (blockCount > 0) {
      features = Rgb28FeatureExtractor.aggregateParcelFeatures(
        rList: rList,
        gList: gList,
        bList: bList,
        rgList: rgList,
        rbList: rbList,
        gbList: gbList,
        rgbList: rgbList,
      );

      emitSnapshot(AnalysisPipelineSnapshot(
        stageId: 'features',
        gridRows: rows,
        gridCols: cols,
        blockWidth: gridSize,
        blockHeight: gridSize,
        revealedGridRows: rows,
        vegetationBlocks: vegetationBlocks,
        revealedVegetationRows: rows,
        vegetationBlockCount: blockCount,
        rgb28Features: features,
        stageProgress: 0.5,
      ));

      averageChlorophyll = ChlorophyllMlpPredictor.predict(features);

      emitSnapshot(AnalysisPipelineSnapshot(
        stageId: 'features',
        gridRows: rows,
        gridCols: cols,
        blockWidth: gridSize,
        blockHeight: gridSize,
        revealedGridRows: rows,
        vegetationBlocks: vegetationBlocks,
        revealedVegetationRows: rows,
        vegetationBlockCount: blockCount,
        rgb28Features: features,
        stageProgress: 1.0,
      ));

      reportAnalysisStage(progressPort, 'predict');

      emitSnapshot(AnalysisPipelineSnapshot(
        stageId: 'predict',
        gridRows: rows,
        gridCols: cols,
        blockWidth: gridSize,
        blockHeight: gridSize,
        revealedGridRows: rows,
        vegetationBlocks: vegetationBlocks,
        revealedVegetationRows: rows,
        vegetationBlockCount: blockCount,
        rgb28Features: features,
        spadPrediction: averageChlorophyll,
        stageProgress: 1.0,
      ));
    }

    final double averageNitrogen =
        ChlorophyllMlpPredictor.estimateNitrogenGPerKg(averageChlorophyll);

    final String? heatmapPath = await _saveChlorophyllHeatmap(
      imageFile: imageFile,
      grid: grid,
      chlorophyllMatrix: chlorophyllMatrix,
      blockCount: blockCount,
      gridSize: gridSize,
    );

    if (heatmapPath != null) {
      final Uint8List heatmapBytes = await File(heatmapPath).readAsBytes();
      emitSnapshot(AnalysisPipelineSnapshot(
        stageId: 'heatmap',
        imageJpeg: heatmapBytes,
        gridRows: rows,
        gridCols: cols,
        blockWidth: gridSize,
        blockHeight: gridSize,
        revealedGridRows: rows,
        vegetationBlocks: vegetationBlocks,
        revealedVegetationRows: rows,
        vegetationBlockCount: blockCount,
        rgb28Features: features,
        spadPrediction: averageChlorophyll > 0 ? averageChlorophyll : null,
        stageProgress: 1.0,
      ));
    }

    return {
      'status': 'success',
      'chlorophyll_spad': '${averageChlorophyll.toStringAsFixed(1)} SPAD',
      'nitrogen_content': '${averageNitrogen.toStringAsFixed(2)} g/kg',
      'notes':
          'Análise de Nitrogênio ($methodLabel) concluída. '
          'Clorofila: ${averageChlorophyll.toStringAsFixed(1)} SPAD. '
          'Nitrogênio estimado: ${averageNitrogen.toStringAsFixed(2)} g/kg (Capim Marandu).',
      'heatmap_path': heatmapPath,
      'processed_image_path': grid.processedImagePath,
      'processed_width': grid.imageWidth,
      'processed_height': grid.imageHeight,
      'prediction_method': methodLabel,
      'vegetation_blocks': blockCount,
    };
  }

  static Future<String?> _saveChlorophyllHeatmap({
    required File imageFile,
    required ImageBlockGrid grid,
    required List<List<double>> chlorophyllMatrix,
    required int blockCount,
    required int gridSize,
  }) async {
    if (blockCount <= 0) return null;

    final int dotIndex = imageFile.path.lastIndexOf('.');
    final String heatmapPath = dotIndex != -1
        ? '${imageFile.path.substring(0, dotIndex)}_heatmap.png'
        : '${imageFile.path}_heatmap.png';

    await ImageAnalysisHelper.generateChlorophyllHeatmap(
      chlorophyllMatrix: chlorophyllMatrix,
      outputPath: heatmapPath,
      originalImagePath: grid.processedImagePath,
      scale: gridSize,
    );
    return heatmapPath;
  }
}
