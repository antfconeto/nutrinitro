import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:opencv_dart/opencv.dart' as cv;

class ImageBlockGrid {
  final List<List<RgbColor>> matrix;
  final String processedImagePath;
  final int imageWidth;
  final int imageHeight;

  const ImageBlockGrid({
    required this.matrix,
    required this.processedImagePath,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class RgbColor {
  final double r;
  final double g;
  final double b;

  const RgbColor(this.r, this.g, this.b);

  @override
  String toString() => 'RgbColor(r: $r, g: $g, b: $b)';
}

class ImageAnalysisHelper {
  static const int kBilateralDiameter = 9;
  static const double kBilateralSigmaColor = 75.0;
  static const double kBilateralSigmaSpace = 75.0;
  static const double kGamma = 0.8;

  static List<int> _gammaLookupTable([double gamma = kGamma]) {
    return List.generate(256, (i) {
      return (255.0 * math.pow(i / 255.0, 1.0 / gamma)).round().clamp(0, 255);
    });
  }

  static void _emitStage(
    void Function(AnalysisStageUpdate stage)? onStage,
    String stageId,
    List<AnalysisStageUpdate> stageCatalog,
  ) {
    onStage?.call(resolveAnalysisStage(stageId, stageCatalog));
  }

  static const int kPreviewMaxDim = 480;
  static const int kPreviewJpegQuality = 72;
  static const int kMaxProgressiveFrames = 28;

  static int _progressiveStep(int total, {int maxFrames = kMaxProgressiveFrames}) {
    if (total <= 0) return 1;
    return (total / maxFrames).ceil().clamp(1, total);
  }

  static (cv.Mat previewMat, int width, int height) _resizeForPreview(cv.Mat source) {
    final int w = source.cols;
    final int h = source.rows;
    if (w <= kPreviewMaxDim && h <= kPreviewMaxDim) {
      return (source.clone(), w, h);
    }
    final double scale = kPreviewMaxDim / math.max(w, h);
    final int newW = (w * scale).round().clamp(1, kPreviewMaxDim);
    final int newH = (h * scale).round().clamp(1, kPreviewMaxDim);
    final cv.Mat resized = cv.resize(source, (newW, newH));
    return (resized, newW, newH);
  }

  static Uint8List _matToPreviewJpeg(cv.Mat mat) {
    final resized = _resizeForPreview(mat);
    final cv.Mat preview = resized.$1;
    final bool ownsPreview = resized.$2 != mat.cols || resized.$3 != mat.rows;
    final cv.VecI32 params = cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, kPreviewJpegQuality]);
    final (_, Uint8List bytes) = cv.imencode('.jpg', preview, params: params);
    params.dispose();
    if (ownsPreview) preview.dispose();
    return bytes;
  }

  static void _emitSnapshot(
    PipelineSnapshotCallback? onSnapshot,
    AnalysisPipelineSnapshot snapshot,
  ) {
    onSnapshot?.call(snapshot);
  }

  /// Decodes an image file and divides it into blocks of [blockWidth] x [blockHeight].
  ///
  /// Pipeline: bilateral (OpenCV nativo) → gamma 0.8 → grade NxN (sem crop).
  static Future<ImageBlockGrid> calculateBlockRgbAverages(
    File imageFile, {
    required int blockWidth,
    required int blockHeight,
    int bilateralDiameter = kBilateralDiameter,
    double bilateralSigmaColor = kBilateralSigmaColor,
    double bilateralSigmaSpace = kBilateralSigmaSpace,
    double gamma = kGamma,
    void Function(AnalysisStageUpdate stage)? onStage,
    PipelineSnapshotCallback? onSnapshot,
    List<AnalysisStageUpdate> stageCatalog = const [],
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final cv.Mat decoded = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (decoded.rows == 0 || decoded.cols == 0) {
      decoded.dispose();
      throw Exception('Não foi possível decodificar a imagem.');
    }

    cv.Mat? processedMat;
    int previewW = 0;
    int previewH = 0;
    Uint8List? previewJpeg;
    try {
      final Uint8List originalJpeg = _matToPreviewJpeg(decoded);
      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'original',
        imageJpeg: originalJpeg,
        imageWidth: decoded.cols,
        imageHeight: decoded.rows,
        stageProgress: 0.0,
      ));

      _emitStage(onStage, 'bilateral', stageCatalog);
      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'bilateral',
        imageJpeg: originalJpeg,
        imageWidth: decoded.cols,
        imageHeight: decoded.rows,
        stageProgress: 0.15,
      ));

      final cv.Mat filtered = cv.bilateralFilter(
        decoded,
        bilateralDiameter,
        bilateralSigmaColor,
        bilateralSigmaSpace,
      );

      final Uint8List bilateralJpeg = _matToPreviewJpeg(filtered);
      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'bilateral',
        imageJpeg: bilateralJpeg,
        imageWidth: filtered.cols,
        imageHeight: filtered.rows,
        stageProgress: 1.0,
      ));

      _emitStage(onStage, 'gamma', stageCatalog);
      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'gamma',
        imageJpeg: bilateralJpeg,
        imageWidth: filtered.cols,
        imageHeight: filtered.rows,
        stageProgress: 0.2,
      ));

      final cv.Mat lut = cv.Mat.fromList(
        1,
        256,
        cv.MatType.CV_8UC1,
        _gammaLookupTable(gamma),
      );
      processedMat = cv.LUT(filtered, lut);
      lut.dispose();
      filtered.dispose();

      previewJpeg = _matToPreviewJpeg(processedMat);
      previewW = processedMat.cols;
      previewH = processedMat.rows;
      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'gamma',
        imageJpeg: previewJpeg,
        imageWidth: previewW,
        imageHeight: previewH,
        stageProgress: 1.0,
      ));

      final int imgW = processedMat.cols;
      final int imgH = processedMat.rows;
      final Uint8List bgrData = processedMat.data;

      _emitStage(onStage, 'grid', stageCatalog);

      final int cols = (imgW / blockWidth).floor();
      final int rows = (imgH / blockHeight).floor();

      if (cols <= 0 || rows <= 0) {
        throw Exception(
          'O tamanho do bloco ($blockWidth x $blockHeight) é maior que a imagem ($imgW x $imgH).',
        );
      }

      final List<List<RgbColor>> matrix = List.generate(
        rows,
        (_) => List.filled(cols, const RgbColor(0, 0, 0)),
      );

      final int gridStep = _progressiveStep(rows);
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final int startX = c * blockWidth;
          final int startY = r * blockHeight;

          double sumR = 0;
          double sumG = 0;
          double sumB = 0;
          int count = 0;

          for (int y = 0; y < blockHeight; y++) {
            for (int x = 0; x < blockWidth; x++) {
              final int pixelX = startX + x;
              final int pixelY = startY + y;

              if (pixelX < imgW && pixelY < imgH) {
                final int idx = (pixelY * imgW + pixelX) * 3;
                sumB += bgrData[idx];
                sumG += bgrData[idx + 1];
                sumR += bgrData[idx + 2];
                count++;
              }
            }
          }

          if (count > 0) {
            matrix[r][c] = RgbColor(sumR / count, sumG / count, sumB / count);
          }
        }

        final bool emitGridFrame = r == 0 || r == rows - 1 || (r + 1) % gridStep == 0;
        if (emitGridFrame && onSnapshot != null) {
          _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
            stageId: 'grid',
            imageJpeg: previewJpeg,
            imageWidth: previewW,
            imageHeight: previewH,
            gridRows: rows,
            gridCols: cols,
            blockWidth: blockWidth,
            blockHeight: blockHeight,
            revealedGridRows: r + 1,
            stageProgress: (r + 1) / rows,
          ));
        }
      }

      final int dotIndex = imageFile.path.lastIndexOf('.');
      final String processedPath = dotIndex != -1
          ? '${imageFile.path.substring(0, dotIndex)}_processed${imageFile.path.substring(dotIndex)}'
          : '${imageFile.path}_processed';

      final cv.VecI32 encodeParams = cv.VecI32.fromList([
        cv.IMWRITE_JPEG_QUALITY,
        85,
      ]);
      final (_, Uint8List jpgBytes) = cv.imencode('.jpg', processedMat, params: encodeParams);
      encodeParams.dispose();
      await File(processedPath).writeAsBytes(jpgBytes);

      _emitSnapshot(onSnapshot, AnalysisPipelineSnapshot(
        stageId: 'grid',
        imageJpeg: previewJpeg,
        imageWidth: previewW,
        imageHeight: previewH,
        gridRows: rows,
        gridCols: cols,
        blockWidth: blockWidth,
        blockHeight: blockHeight,
        revealedGridRows: rows,
        stageProgress: 1.0,
      ));

      final ImageBlockGrid result = ImageBlockGrid(
        matrix: matrix,
        processedImagePath: processedPath,
        imageWidth: imgW,
        imageHeight: imgH,
      );
      processedMat.dispose();
      processedMat = null;
      return result;
    } finally {
      processedMat?.dispose();
      decoded.dispose();
    }
  }


  /// Generates a visual chlorophyll heatmap image based on a matrix of chlorophyll index values,
  /// color-coded from low (deficiency - red) to high (healthy - vibrant green),
  /// superimposed on top of the original image, and saves it as a PNG file at [outputPath].
  static Future<File> generateChlorophyllHeatmap({
    required List<List<double>> chlorophyllMatrix,
    required String outputPath,
    required String originalImagePath,
    int scale = 16,
  }) async {
    final int rows = chlorophyllMatrix.length;
    final int cols = rows > 0 ? chlorophyllMatrix[0].length : 0;

    if (rows == 0 || cols == 0) {
      throw Exception('Matriz de clorofila vazia.');
    }

    final int width = cols * scale;
    final int height = rows * scale;

    // Load original image to use as background
    final bytes = await File(originalImagePath).readAsBytes();
    final img.Image? baseImage = img.decodeImage(bytes);
    if (baseImage == null) {
      throw Exception('Não foi possível decodificar a imagem original para o heatmap.');
    }

    // Resize original image to match heatmap dimensions exactly
    final img.Image heatmapImage = img.copyResize(baseImage, width: width, height: height);

    // Color gradient interpolation helper matching matplotlib's RdYlGn colormap
    // Clamps index values between 25.0 and 55.0 to represent a typical SPAD scale for pasture with high contrast
    const double minSpad = 25.0;
    const double maxSpad = 55.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double spad = chlorophyllMatrix[r][c];

        if (spad >= 0.0) {
          final double norm = ((spad - minSpad) / (maxSpad - minSpad)).clamp(0.0, 1.0);
          
          int red = 0;
          int green = 0;
          int blue = 0;

          if (norm <= 0.25) {
            // Interpolate from Red [165, 0, 38] to Orange-Red [244, 109, 67]
            final double t = norm / 0.25;
            red = (165 + (244 - 165) * t).round();
            green = (0 + 109 * t).round();
            blue = (38 + (67 - 38) * t).round();
          } else if (norm <= 0.5) {
            // Interpolate from Orange-Red [244, 109, 67] to Yellow [253, 224, 117]
            final double t = (norm - 0.25) / 0.25;
            red = (244 + (253 - 244) * t).round();
            green = (109 + (224 - 109) * t).round();
            blue = (67 + (117 - 67) * t).round();
          } else if (norm <= 0.75) {
            // Interpolate from Yellow [253, 224, 117] to Light Green [166, 217, 106]
            final double t = (norm - 0.5) / 0.25;
            red = (253 + (166 - 253) * t).round();
            green = (224 + (217 - 224) * t).round();
            blue = (117 + (106 - 117) * t).round();
          } else {
            // Interpolate from Light Green [166, 217, 106] to Dark Green [26, 152, 80]
            final double t = (norm - 0.75) / 0.25;
            red = (166 + (26 - 166) * t).round();
            green = (217 + (152 - 217) * t).round();
            blue = (106 + (80 - 106) * t).round();
          }

          // Blending factor: alpha = 160/255 = 0.63 opacity
          const double opacity = 0.63;

          // Fill the scale x scale block in the heatmap image with blended color
          for (int y = 0; y < scale; y++) {
            for (int x = 0; x < scale; x++) {
              final int pixelX = c * scale + x;
              final int pixelY = r * scale + y;
              if (pixelX < width && pixelY < height) {
                final pixel = heatmapImage.getPixel(pixelX, pixelY);
                final double baseR = pixel.r.toDouble();
                final double baseG = pixel.g.toDouble();
                final double baseB = pixel.b.toDouble();

                final int blendedR = (baseR * (1.0 - opacity) + red * opacity).round().clamp(0, 255);
                final int blendedG = (baseG * (1.0 - opacity) + green * opacity).round().clamp(0, 255);
                final int blendedB = (baseB * (1.0 - opacity) + blue * opacity).round().clamp(0, 255);

                heatmapImage.setPixelRgb(pixelX, pixelY, blendedR, blendedG, blendedB);
              }
            }
          }
        }
        // Non-vegetation: we don't modify the pixels, keeping the base image raw/untouched!
      }
    }

    final List<int> pngBytes = img.encodePng(heatmapImage);
    final File outFile = File(outputPath);
    await outFile.create(recursive: true);
    await outFile.writeAsBytes(pngBytes);
    return outFile;
  }
}
