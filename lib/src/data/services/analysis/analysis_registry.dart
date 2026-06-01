import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:nutrinitro/src/data/services/analysis/image_analysis_helper.dart';

class AnalysisMethod {
  final String id;
  final String name;
  final String description;
  final String iconName;

  const AnalysisMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });
}

abstract class RegisteredAnalysis {
  String get id;
  String get name;
  List<String> get supportedCropNames; // Crop names supported by this analysis
  List<AnalysisMethod> get methods => const [];

  Future<Map<String, dynamic>> run(File imageFile, {SendPort? progressPort});
}

class StandardAgronomicAnalysis extends RegisteredAnalysis {
  @override
  String get id => 'agronomic';

  @override
  String get name => 'Análise Agronômica Padrão';

  @override
  List<String> get supportedCropNames => ['Milho', 'Feijao'];

  @override
  Future<Map<String, dynamic>> run(File imageFile, {SendPort? progressPort}) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      "status": "mock",
      "crop": "detected",
      "moisture": "13.5%",
      "protein": "8.2%",
      "quality": "Good",
      "notes": "Simulated result. Real analysis pending implementation."
    };
  }
}

abstract class BaseNitrogenAnalysis extends RegisteredAnalysis {
  @override
  List<String> get supportedCropNames => ['Capim Marandu'];

  double predictChlorophyll(double r, double g, double b, double rNorm, double gNorm, double bNorm);

  String get methodName;

  @override
  Future<Map<String, dynamic>> run(File imageFile, {SendPort? progressPort}) async {
    final String originalDir = imageFile.parent.path;
    final String fileName = imageFile.uri.pathSegments.last;
    final String nameWithoutExtension = fileName.substring(0, fileName.lastIndexOf('.'));
    final String outputPath = '$originalDir/${nameWithoutExtension}_${id}_heatmap.png';

    // 1. Calculate RGB averages in blocks of 10x10 pixels (matching block_size=10)
    final List<List<RgbColor>> rgbMatrix = await ImageAnalysisHelper.calculateBlockRgbAverages(
      imageFile,
      blockWidth: 10,
      blockHeight: 10,
    );

    final int rows = rgbMatrix.length;
    final int cols = rows > 0 ? rgbMatrix[0].length : 0;

    final List<List<double>> chlorophyllMatrix = List.generate(
      rows,
      (_) => List.filled(cols, 0.0),
    );

    double totalChlorophyll = 0.0;
    int blockCount = 0;

    // 2. Compute vegetative index ExG > 0.15 and custom regression equation for each block
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rgb = rgbMatrix[r][c];
        final double rVal = rgb.r;
        final double gVal = rgb.g;
        final double bVal = rgb.b;

        final double sum = rVal + gVal + bVal;
        double exg = 0.0;
        bool isVegetation = false;

        double rNorm = 0.0;
        double gNorm = 0.0;
        double bNorm = 0.0;

        if (sum > 0.0) {
          rNorm = rVal / sum;
          gNorm = gVal / sum;
          bNorm = bVal / sum;
          exg = 2.0 * gNorm - rNorm - bNorm;
          isVegetation = exg > 0.15;
        }

        if (isVegetation) {
          final double y = predictChlorophyll(rVal, gVal, bVal, rNorm, gNorm, bNorm);
          chlorophyllMatrix[r][c] = y;
          totalChlorophyll += y;
          blockCount++;
        } else {
          // Flag indicating non-vegetation block
          chlorophyllMatrix[r][c] = -1.0;
        }
      }

      if (progressPort != null) {
        final List<List<double>> copy = chlorophyllMatrix.map((row) => List<double>.from(row)).toList();
        progressPort.send(copy);
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }

    final double averageChlorophyll = blockCount > 0 ? totalChlorophyll / blockCount : 0.0;
    // Calibrate nitrogen estimation (exclusively for Capim Marandu): N = -10.21 + 0.911 * SPAD (clamped to >= 0.0)
    final double averageNitrogen = (averageChlorophyll > 0) ? math.max(0.0, -10.21 + 0.911 * averageChlorophyll) : 0.0;

    // 3. Generate heatmap (scale = 10 matching block_size=10)
    final File heatmapFile = await ImageAnalysisHelper.generateChlorophyllHeatmap(
      chlorophyllMatrix: chlorophyllMatrix,
      outputPath: outputPath,
      originalImagePath: imageFile.path.replaceAll('.jpg', '_cropped.jpg'),
      scale: 10,
    );

    return {
      "status": "success",
      "chlorophyll_spad": "${averageChlorophyll.toStringAsFixed(1)} SPAD",
      "nitrogen_content": "${averageNitrogen.toStringAsFixed(2)} g/kg",
      "notes": "Análise de Nitrogênio ($methodName) concluída. Clorofila: ${averageChlorophyll.toStringAsFixed(1)} SPAD. Nitrogênio estimado: ${averageNitrogen.toStringAsFixed(2)} g/kg (Capim Marandu).",
      "heatmap_path": heatmapFile.path,
      "cropped_original_path": imageFile.path.replaceAll('.jpg', '_cropped.jpg'),
      "prediction_method": methodName,
    };
  }
}

class NitrogenAnalysis extends RegisteredAnalysis {
  @override
  String get id => 'nitrogen';

  @override
  String get name => 'Análise de Nitrogênio';

  @override
  List<String> get supportedCropNames => ['Capim Marandu'];

  @override
  List<AnalysisMethod> get methods => const [
        AnalysisMethod(
          id: 'nitrogen_si',
          name: 'SI (Inclinação Espectral)',
          description: '🏆 1º Lugar — Altíssima correlação linear. Baseado no índice espectral (r-b)/(r+b).',
          iconName: 'trending_up',
        ),
        AnalysisMethod(
          id: 'nitrogen_br',
          name: 'b/r (Razão Azul/Vermelho)',
          description: '🥈 2º Lugar — Equação linear tradicional baseada na razão simples entre os canais Azul e Vermelho.',
          iconName: 'waves',
        ),
        AnalysisMethod(
          id: 'nitrogen_mlp',
          name: 'MLP 2 (Rede Neural MLP)',
          description: '🥉 3º Lugar — Inteligência Artificial não-linear. Utiliza Matiz H, Luminosidade L e b/r com ReLU.',
          iconName: 'psychology',
        ),
      ];

  @override
  Future<Map<String, dynamic>> run(File imageFile, {SendPort? progressPort}) async {
    return NitrogenSiAnalysis().run(imageFile, progressPort: progressPort);
  }
}

class NitrogenSiAnalysis extends BaseNitrogenAnalysis {
  @override
  String get id => 'nitrogen_si';

  @override
  String get name => 'Nitrogênio - SI (Inclinação Espectral)';

  @override
  String get methodName => 'SI (Inclinação Espectral)';

  @override
  double predictChlorophyll(double r, double g, double b, double rNorm, double gNorm, double bNorm) {
    final double denom = rNorm + bNorm;
    final double si = denom == 0 ? 0.0 : (rNorm - bNorm) / denom;
    return -59.40071050 * si + 56.67808051;
  }
}

class NitrogenBrAnalysis extends BaseNitrogenAnalysis {
  @override
  String get id => 'nitrogen_br';

  @override
  String get name => 'Nitrogênio - b/r (Razão Azul/Vermelho)';

  @override
  String get methodName => 'b/r (Razão Azul/Vermelho)';

  @override
  double predictChlorophyll(double r, double g, double b, double rNorm, double gNorm, double bNorm) {
    final double x = r == 0 ? 0.0 : b / r;
    return 51.68715570 * x + 10.59936178;
  }
}

class NitrogenMlpAnalysis extends BaseNitrogenAnalysis {
  @override
  String get id => 'nitrogen_mlp';

  @override
  String get name => 'Nitrogênio - MLP 2 (Rede Neural)';

  @override
  String get methodName => 'MLP 2 (Rede Neural)';

  @override
  double predictChlorophyll(double r, double g, double b, double rNorm, double gNorm, double bNorm) {
    final double x1 = r == 0 ? 0.0 : b / r;

    // Convert r, g, b to HSL Space for Hue and Lightness
    final double rFrac = r / 255.0;
    final double gFrac = g / 255.0;
    final double bFrac = b / 255.0;

    final double max = math.max(rFrac, math.max(gFrac, bFrac));
    final double min = math.min(rFrac, math.min(gFrac, bFrac));
    final double delta = max - min;

    double h = 0.0;
    double l = (max + min) / 2.0;

    if (delta != 0.0) {
      if (max == rFrac) {
        h = ((gFrac - bFrac) / delta) % 6;
      } else if (max == gFrac) {
        h = ((bFrac - rFrac) / delta) + 2;
      } else if (max == bFrac) {
        h = ((rFrac - gFrac) / delta) + 4;
      }
      h *= 60.0;
      if (h < 0) {
        h += 360.0;
      }
    }

    final double x2 = h;
    final double x3 = l;

    // StandardScaler:
    // Mean: [ 0.53641253 78.62078575  0.33908484]
    // Scale/Std: [0.06366811 4.7430906  0.00817559]
    final double z1 = (x1 - 0.53641253) / 0.06366811;
    final double z2 = (x2 - 78.62078575) / 4.74309060;
    final double z3 = (x3 - 0.33908484) / 0.00817559;

    // hidden layers weights + biases calculation
    final double a1 = (z1 * -0.00000435536636) + (z2 * -0.00000579526116) + (z3 * 0.0000162276496) - 1.08173206;
    final double a2 = (z1 * 1.49092668) + (z2 * 0.29708743) + (z3 * 0.00135857442) + 20.19215947;

    final double h1 = a1 < 0.0 ? 0.0 : a1;
    final double h2 = a2 < 0.0 ? 0.0 : a2;

    // output node prediction
    return (h1 * -0.0000212041572) + (h2 * 1.52023062) + 7.62826175;
  }
}

class AnalysisRegistry {
  static final Map<String, RegisteredAnalysis> _registry = {
    'agronomic': StandardAgronomicAnalysis(),
    'nitrogen': NitrogenAnalysis(),
    'nitrogen_si': NitrogenSiAnalysis(),
    'nitrogen_br': NitrogenBrAnalysis(),
    'nitrogen_mlp': NitrogenMlpAnalysis(),
  };

  static final List<RegisteredAnalysis> _analyses = [
    _registry['agronomic']!,
    _registry['nitrogen']!,
  ];

  static List<RegisteredAnalysis> get all => _analyses;

  static RegisteredAnalysis? getById(String id) {
    if (id == 'nitrogen' || id == 'chlorophyll') {
      return _registry['nitrogen_si'];
    }
    if (id == 'chlorophyll_si' || id == 'nitrogen_si') {
      return _registry['nitrogen_si'];
    }
    if (id == 'chlorophyll_br' || id == 'nitrogen_br') {
      return _registry['nitrogen_br'];
    }
    if (id == 'chlorophyll_mlp' || id == 'nitrogen_mlp') {
      return _registry['nitrogen_mlp'];
    }
    return _registry[id];
  }

  // Developer-level registration method
  static void register(RegisteredAnalysis analysis) {
    _registry[analysis.id] = analysis;
    if (!_analyses.any((a) => a.id == analysis.id)) {
      _analyses.add(analysis);
    }
  }
}
