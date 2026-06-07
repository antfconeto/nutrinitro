// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:nutrinitro/src/data/services/analysis/analysis_registry.dart';

/// Valida predição de clorofila (MLP) contra o CSV de referência do TCC.
///
/// Uso:
///   dart run tool/validate_chlorophyll.dart [caminho_tcc]
void main(List<String> args) async {
  final String tccRoot = args.isNotEmpty
      ? args.first
      : '../tcc';
  final String imageRoot = '$tccRoot/data/image';
  final String refCsv =
      '$tccRoot/data/output/images-infos/definitive_model_predictions.csv';

  if (!Directory(imageRoot).existsSync()) {
    stderr.writeln('Pasta de imagens não encontrada: $imageRoot');
    exit(1);
  }
  if (!File(refCsv).existsSync()) {
    stderr.writeln('CSV de referência não encontrado: $refCsv');
    exit(1);
  }

  final Map<String, _RefRow> refByKey = _loadReference(refCsv);
  final NitrogenAnalysis analysis = NitrogenAnalysis();
  final List<_ResultRow> results = [];

  const dates = ['18-05', '21-05', '26-05', '01-06'];

  for (final folder in dates) {
    final dir = Directory('$imageRoot/$folder');
    if (!dir.existsSync()) continue;

    final dateKey = '$folder-2026';
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = f.path.split('/').last.toLowerCase();
          return name.endsWith('.jpg') || name.endsWith('.jpeg');
        })
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final name = file.path.split('/').last;
      final match = RegExp(r'^[Pp](\d+)').firstMatch(name);
      if (match == null) continue;

      final int ponto = int.parse(match.group(1)!);
      final String key = '$dateKey|$ponto';
      final _RefRow? ref = refByKey[key];

      final sw = Stopwatch()..start();
      final Map<String, dynamic> out = await analysis.run(file);
      sw.stop();

      final String spadStr = (out['chlorophyll_spad'] as String?) ?? '0 SPAD';
      final double dartMlp = double.parse(spadStr.replaceAll(' SPAD', ''));

      results.add(_ResultRow(
        date: dateKey,
        ponto: ponto,
        file: name,
        dartMlp: dartMlp,
        refMlp: ref?.predMlp,
        falker: ref?.falker,
        vegBlocks: out['vegetation_blocks'] as int? ?? 0,
        ms: sw.elapsedMilliseconds,
      ));
    }
  }

  _printReport(results);
}

class _RefRow {
  final double falker;
  final double predMlp;
  final double predSi;

  const _RefRow({
    required this.falker,
    required this.predMlp,
    required this.predSi,
  });
}

class _ResultRow {
  final String date;
  final int ponto;
  final String file;
  final double dartMlp;
  final double? refMlp;
  final double? falker;
  final int vegBlocks;
  final int ms;

  const _ResultRow({
    required this.date,
    required this.ponto,
    required this.file,
    required this.dartMlp,
    required this.refMlp,
    required this.falker,
    required this.vegBlocks,
    required this.ms,
  });

  double? get errVsRef =>
      refMlp == null ? null : (dartMlp - refMlp!).abs();

  double? get errVsFalker =>
      falker == null ? null : (dartMlp - falker!).abs();
}

Map<String, _RefRow> _loadReference(String path) {
  final lines = File(path).readAsLinesSync();
  final Map<String, _RefRow> map = {};

  for (int i = 1; i < lines.length; i++) {
    final parts = lines[i].split(',');
    if (parts.length < 7) continue;
    final date = parts[0];
    final ponto = int.parse(parts[1].split('.').first);
    final key = '$date|$ponto';
    map[key] = _RefRow(
      falker: double.parse(parts[4]),
      predMlp: double.parse(parts[5]),
      predSi: double.parse(parts[6]),
    );
  }
  return map;
}

void _printReport(List<_ResultRow> rows) {
  print('\n${'=' * 110}');
  print('VALIDAÇÃO CLOROFILA — Dart (Nutrinitro) vs TCC (Python MLP) vs Falker');
  print('${'=' * 110}');
  print(
    '${'Data'.padRight(12)} ${'P'.padLeft(3)} ${'Arquivo'.padRight(14)} '
    '${'Dart'.padLeft(7)} ${'PyMLP'.padLeft(7)} ${'Falker'.padLeft(7)} '
    '${'ΔPy'.padLeft(6)} ${'ΔFk'.padLeft(6)} ${'Veg'.padLeft(6)} ${'ms'.padLeft(5)}',
  );
  print('${'-' * 110}');

  final withRef = <_ResultRow>[];
  for (final r in rows) {
    if (r.refMlp == null) continue;
    withRef.add(r);
    print(
      '${r.date.padRight(12)} ${r.ponto.toString().padLeft(3)} ${r.file.padRight(14)} '
      '${r.dartMlp.toStringAsFixed(2).padLeft(7)} '
      '${r.refMlp!.toStringAsFixed(2).padLeft(7)} '
      '${(r.falker?.toStringAsFixed(2) ?? '-').padLeft(7)} '
      '${(r.errVsRef?.toStringAsFixed(2) ?? '-').padLeft(6)} '
      '${(r.errVsFalker?.toStringAsFixed(2) ?? '-').padLeft(6)} '
      '${r.vegBlocks.toString().padLeft(6)} '
      '${r.ms.toString().padLeft(5)}',
    );
  }

  if (withRef.isEmpty) {
    print('Nenhuma imagem com referência no CSV.');
    return;
  }

  double maePy = 0, maeFk = 0, rmsePy = 0;
  for (final r in withRef) {
    final ePy = r.errVsRef!;
    final eFk = r.errVsFalker!;
    maePy += ePy;
    maeFk += eFk;
    rmsePy += ePy * ePy;
  }
  final n = withRef.length;
  maePy /= n;
  maeFk /= n;
  rmsePy = math.sqrt(rmsePy / n);

  print('${'-' * 110}');
  print('Amostras com referência: $n / ${rows.length} imagens processadas');
  print('MAE vs Python MLP: ${maePy.toStringAsFixed(3)} SPAD');
  print('RMSE vs Python MLP: ${rmsePy.toStringAsFixed(3)} SPAD');
  print('MAE vs Falker (medição): ${maeFk.toStringAsFixed(3)} SPAD');
  print('${'=' * 110}\n');
}
