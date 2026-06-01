import 'dart:io';
import 'package:image/image.dart' as img;

class RgbColor {
  final double r;
  final double g;
  final double b;

  const RgbColor(this.r, this.g, this.b);

  @override
  String toString() => 'RgbColor(r: $r, g: $g, b: $b)';
}

class ImageAnalysisHelper {
  /// Decodes an image file and divides it into blocks of [blockWidth] x [blockHeight],
  /// returning a 2D matrix of the average R, G, B values for each block.
  static Future<List<List<RgbColor>>> calculateBlockRgbAverages(
    File imageFile, {
    required int blockWidth,
    required int blockHeight,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Não foi possível decodificar a imagem.');
    }

    final int imgWidth = image.width;
    final int imgHeight = image.height;

    // Downscale full original image directly to 800px wide (no crop)
    final int newW = 800;
    final int newH = (imgHeight * 800 / imgWidth).round();
    final img.Image resizedImage = img.copyResize(image, width: newW, height: newH);

    // Save the resized image as a new _cropped.jpg file (preserving the path name for DB/UI compatibility)
    final String croppedPath = imageFile.path.replaceAll('.jpg', '_cropped.jpg');
    final File croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(resizedImage));

    final int finalWidth = resizedImage.width;
    final int finalHeight = resizedImage.height;

    // Determine grid size based on block dimensions
    final int cols = (finalWidth / blockWidth).floor();
    final int rows = (finalHeight / blockHeight).floor();

    if (cols <= 0 || rows <= 0) {
      throw Exception('O tamanho do bloco ($blockWidth x $blockHeight) é maior do que a imagem ($finalWidth x $finalHeight).');
    }

    final List<List<RgbColor>> matrix = List.generate(
      rows,
      (_) => List.filled(cols, const RgbColor(0, 0, 0)),
    );

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

            if (pixelX < finalWidth && pixelY < finalHeight) {
              final pixel = resizedImage.getPixel(pixelX, pixelY);
              sumR += pixel.r;
              sumG += pixel.g;
              sumB += pixel.b;
              count++;
            }
          }
        }

        if (count > 0) {
          matrix[r][c] = RgbColor(sumR / count, sumG / count, sumB / count);
        }
      }
    }

    return matrix;
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

    // Color gradient interpolation helper
    // Clamps index values between 15.0 and 65.0 to represent a typical SPAD scale for pasture
    const double minSpad = 15.0;
    const double maxSpad = 65.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double spad = chlorophyllMatrix[r][c];

        if (spad >= 0.0) {
          final double norm = ((spad - minSpad) / (maxSpad - minSpad)).clamp(0.0, 1.0);
          
          int red = 0;
          int green = 0;
          int blue = 0;

          if (norm <= 0.3) {
            // Interpolate between Red [255, 0, 0] and Orange [255, 165, 0]
            final double t = norm / 0.3;
            red = 255;
            green = (0 + 165 * t).round();
            blue = 0;
          } else if (norm <= 0.6) {
            // Interpolate between Orange [255, 165, 0] and Light Green [139, 195, 74]
            final double t = (norm - 0.3) / 0.3;
            red = (255 + (139 - 255) * t).round();
            green = (165 + (195 - 165) * t).round();
            blue = (0 + 74 * t).round();
          } else {
            // Interpolate between Light Green [139, 195, 74] and Dark Green [27, 94, 32]
            final double t = (norm - 0.6) / 0.4;
            red = (139 + (27 - 139) * t).round();
            green = (195 + (94 - 195) * t).round();
            blue = (74 + (32 - 74) * t).round();
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
