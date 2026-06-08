/// Identifica parcelas (P01–P12) por nome de arquivo ou impressão digital da análise.
class ValidationParcelMatcher {
  static const String defaultDateFolder = '26-05';

  static int? parseParcelFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    final base = name.contains('/') ? name.split('/').last : name;
    final patterns = [
      RegExp(r'(?:\d{2}-\d{2}[_-])P(\d{1,2})', caseSensitive: false),
      RegExp(r'^P(\d{1,2})(?:[^0-9]|$)', caseSensitive: false),
      RegExp(r'Ponto[_-]?(\d{1,2})', caseSensitive: false),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(base);
      if (m != null) {
        final p = int.tryParse(m.group(1)!);
        if (p != null && p >= 1 && p <= 12) return p;
      }
    }
    return null;
  }

  static String? parseDateFolderFromName(String? name) {
    if (name == null) return null;
    final m = RegExp(r'(\d{2}-\d{2})').firstMatch(name);
    return m?.group(1);
  }

  /// Impressões digitais esperadas (blocos vegetados + dimensões pós-processamento).
  /// Gerado a partir das imagens croppadas em tcc/data/export_app_validation/.
  static const Map<String, List<ParcelFingerprint>> fingerprintsByDate = {
    '26-05': [
      ParcelFingerprint(ponto: 1, vegetationBlocks: 918, width: 288, height: 339, falkerSpad: 36.94),
      ParcelFingerprint(ponto: 2, vegetationBlocks: 23417, width: 1425, height: 1698, falkerSpad: 37.29),
      ParcelFingerprint(ponto: 3, vegetationBlocks: 21593, width: 1354, height: 1685, falkerSpad: 41.17),
      ParcelFingerprint(ponto: 4, vegetationBlocks: 20701, width: 1351, height: 1695, falkerSpad: 33.19),
      ParcelFingerprint(ponto: 5, vegetationBlocks: 23291, width: 1395, height: 1824, falkerSpad: 40.46),
      ParcelFingerprint(ponto: 6, vegetationBlocks: 20630, width: 1379, height: 1593, falkerSpad: 41.07),
      ParcelFingerprint(ponto: 7, vegetationBlocks: 17152, width: 1382, height: 1635, falkerSpad: 30.34),
      ParcelFingerprint(ponto: 8, vegetationBlocks: 17470, width: 1197, height: 1577, falkerSpad: 30.89),
      ParcelFingerprint(ponto: 9, vegetationBlocks: 23431, width: 1401, height: 1765, falkerSpad: 36.46),
      ParcelFingerprint(ponto: 10, vegetationBlocks: 20218, width: 1299, height: 1632, falkerSpad: 36.19),
      ParcelFingerprint(ponto: 11, vegetationBlocks: 18070, width: 1230, height: 1586, falkerSpad: 36.99),
      ParcelFingerprint(ponto: 12, vegetationBlocks: 17626, width: 1299, height: 1620, falkerSpad: 30.79),
    ],
  };

  static ParcelMatch? matchByFingerprint({
    required int vegetationBlocks,
    int? width,
    int? height,
    String dateFolder = defaultDateFolder,
  }) {
    final refs = fingerprintsByDate[dateFolder];
    if (refs == null || refs.isEmpty) return null;

    ParcelFingerprint? best;
    double bestScore = double.infinity;

    for (final ref in refs) {
      double score = (vegetationBlocks - ref.vegetationBlocks).abs() /
          ref.vegetationBlocks.clamp(1, 999999);
      if (width != null && height != null && ref.width > 0 && ref.height > 0) {
        final dw = (width - ref.width).abs() / ref.width;
        final dh = (height - ref.height).abs() / ref.height;
        score += dw * 0.35 + dh * 0.35;
      }
      if (score < bestScore) {
        bestScore = score;
        best = ref;
      }
    }

    if (best == null) return null;
    final confidence = (1.0 - bestScore.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    return ParcelMatch(
      ponto: best.ponto,
      dateFolder: dateFolder,
      confidence: confidence,
      falkerSpadReference: best.falkerSpad,
      matchMethod: 'fingerprint',
    );
  }

  static ParcelMatch? resolve({
    String? sourceName,
    String? storedFilename,
    required int? vegetationBlocks,
    int? width,
    int? height,
    String defaultDate = defaultDateFolder,
  }) {
    for (final name in [sourceName, storedFilename]) {
      final ponto = parseParcelFromName(name);
      if (ponto != null) {
        final date = parseDateFolderFromName(name) ?? defaultDate;
        final ref = fingerprintsByDate[date]
            ?.where((f) => f.ponto == ponto)
            .firstOrNull;
        return ParcelMatch(
          ponto: ponto,
          dateFolder: date,
          confidence: 1.0,
          falkerSpadReference: ref?.falkerSpad,
          matchMethod: 'filename',
        );
      }
    }

    if (vegetationBlocks != null && vegetationBlocks > 0) {
      final date = parseDateFolderFromName(sourceName) ??
          parseDateFolderFromName(storedFilename) ??
          defaultDate;
      return matchByFingerprint(
        vegetationBlocks: vegetationBlocks,
        width: width,
        height: height,
        dateFolder: date,
      );
    }
    return null;
  }
}

class ParcelFingerprint {
  final int ponto;
  final int vegetationBlocks;
  final int width;
  final int height;
  final double falkerSpad;

  const ParcelFingerprint({
    required this.ponto,
    required this.vegetationBlocks,
    required this.width,
    required this.height,
    required this.falkerSpad,
  });
}

class ParcelMatch {
  final int ponto;
  final String dateFolder;
  final double confidence;
  final double? falkerSpadReference;
  final String matchMethod;

  const ParcelMatch({
    required this.ponto,
    required this.dateFolder,
    required this.confidence,
    this.falkerSpadReference,
    required this.matchMethod,
  });

  String get label => '$dateFolder P${ponto.toString().padLeft(2, '0')}';
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
