import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/core/utils/validation_parcel_matcher.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/data/models/analysis/image_model.dart';
import 'package:path_provider/path_provider.dart';

/// Exporta resultados da análise em JSON para validação de acurácia (modo debug).
class DebugAnalysisExporter {
  static bool get isEnabled => kDebugMode || Env.debug;

  static Map<String, dynamic> buildExportPayload(
    AnalysisModel analysis, {
    String defaultDateFolder = ValidationParcelMatcher.defaultDateFolder,
  }) {
    final List<Map<String, dynamic>> imageExports = [];
    final List<Map<String, dynamic>> matchedRows = [];

    for (final ImageModel img in analysis.images) {
      Map<String, dynamic> resultParsed = {};
      if (img.result != null) {
        try {
          final decoded = json.decode(img.result!);
          if (decoded is Map<String, dynamic>) {
            resultParsed = decoded;
          } else if (decoded is Map) {
            resultParsed = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          resultParsed = {'_parse_error': true, '_raw': img.result};
        }
      }

      final String basename = _basename(img.originalPath);
      final int? vegBlocks = resultParsed['vegetation_blocks'] as int?;
      final int? procW = resultParsed['processed_width'] as int?;
      final int? procH = resultParsed['processed_height'] as int?;
      final double? spad = _parseSpad(resultParsed['chlorophyll_spad']);

      final ParcelMatch? match = ValidationParcelMatcher.resolve(
        sourceName: basename,
        storedFilename: basename,
        vegetationBlocks: vegBlocks,
        width: procW,
        height: procH,
        defaultDate: defaultDateFolder,
      );

      final Map<String, dynamic>? parcelMatch = match == null
          ? null
          : {
              'ponto': match.ponto,
              'date_folder': match.dateFolder,
              'label': match.label,
              'confidence': double.parse(match.confidence.toStringAsFixed(3)),
              'match_method': match.matchMethod,
              'falker_spad_reference': match.falkerSpadReference,
              'error_vs_falker': (spad != null && match.falkerSpadReference != null)
                  ? double.parse(
                      (spad - match.falkerSpadReference!).toStringAsFixed(2),
                    )
                  : null,
            };

      if (match != null) {
        matchedRows.add({
          'display_order': img.displayOrder,
          'matched_parcel': match.label,
          'confidence': match.confidence,
          'spad_predicted': spad,
          'falker_reference': match.falkerSpadReference,
        });
      }

      imageExports.add({
        'display_order': img.displayOrder,
        'filename': basename,
        'source_name_hint': basename,
        'was_analyzed': img.wasAnalyzed,
        'latitude': img.latitude,
        'longitude': img.longitude,
        'datetime_exif': img.datetime?.toIso8601String(),
        'chlorophyll_spad': resultParsed['chlorophyll_spad'],
        'chlorophyll_spad_numeric': spad,
        'nitrogen_content': resultParsed['nitrogen_content'],
        'estimated_biomass': resultParsed['estimated_biomass'],
        'prediction_method': resultParsed['prediction_method'],
        'vegetation_blocks': vegBlocks,
        'processed_width': procW,
        'processed_height': procH,
        'parcel_match': parcelMatch,
        'result': resultParsed,
      });
    }

    final matched = imageExports
        .where((e) => e['parcel_match'] != null && e['was_analyzed'] == true)
        .toList();

    double? meanError;
    if (matched.isNotEmpty) {
      final errors = matched
          .map((e) => (e['parcel_match'] as Map)['error_vs_falker'] as double?)
          .whereType<double>()
          .toList();
      if (errors.isNotEmpty) {
        meanError = errors.reduce((a, b) => a + b) / errors.length;
      }
    }

    return {
      'export_type': 'nutrinitro_accuracy_debug',
      'export_version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'analysis': {
        'id': analysis.id,
        'title': analysis.title,
        'datetime': analysis.datetime.toIso8601String(),
        'status': analysis.status.name,
        'analysis_type': analysis.analysisType,
        'crop_name': analysis.crop?.name,
        'notes': analysis.notes,
      },
      'validation': {
        'default_date_folder': defaultDateFolder,
        'matched_count': matched.length,
        'mean_error_vs_falker': meanError != null
            ? double.parse(meanError.toStringAsFixed(2))
            : null,
        'matched_parcels': matchedRows,
      },
      'images': imageExports,
      'instructions': {
        'purpose': 'Enviar este JSON para avaliação de acurácia vs Falker SPAD',
        'parcel_matching': 'parcel_match identifica P01–P12 mesmo se a galeria embaralhar',
        'reference_manifest': 'tcc/data/export_app_validation/manifest.json',
      },
    };
  }

  static String buildExportJson(AnalysisModel analysis, {bool pretty = true}) {
    final payload = buildExportPayload(analysis);
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(payload);
    }
    return json.encode(payload);
  }

  static Future<void> showExportSheet(
    BuildContext context,
    AnalysisModel analysis,
  ) async {
    final payload = buildExportPayload(analysis);
    final String jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    final matched = (payload['validation'] as Map)['matched_parcels'] as List;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grayMedium.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Export Debug JSON',
                    style: AppText.large.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Identificação automática de parcelas (P01–P12)',
                    style: AppText.small.copyWith(color: AppColors.grayMedium),
                  ),
                  if (matched.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MatchedParcelsCard(matched: matched),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(context, jsonText),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copiar JSON'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveToFile(context, analysis, jsonText),
                          icon: const Icon(Icons.save_alt, size: 18),
                          label: const Text('Salvar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.grayLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.green.withOpacity(0.2)),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          jsonText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _copyToClipboard(BuildContext context, String jsonText) async {
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON copiado — parcelas identificadas em parcel_match'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> _saveToFile(
    BuildContext context,
    AnalysisModel analysis,
    String jsonText,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final String name =
          'nutrinitro_debug_${analysis.id ?? 'local'}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$name');
      await file.writeAsString(jsonText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salvo em: ${file.path}'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.tomato,
          ),
        );
      }
    }
  }

  static String _basename(String path) {
    final idx = path.lastIndexOf('/');
    return idx >= 0 ? path.substring(idx + 1) : path;
  }

  static double? _parseSpad(dynamic value) {
    if (value == null) return null;
    final String s = value.toString().replaceAll('SPAD', '').trim();
    return double.tryParse(s);
  }
}

class _MatchedParcelsCard extends StatelessWidget {
  final List matched;

  const _MatchedParcelsCard({required this.matched});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcelas identificadas',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          ...matched.take(12).map((row) {
            final m = row as Map;
            final conf = ((m['confidence'] as num?) ?? 0) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${m['matched_parcel']} → ${m['spad_predicted']?.toStringAsFixed(1) ?? '?'} SPAD '
                '(Falker ${m['falker_reference']?.toStringAsFixed(1) ?? '?'}) '
                '[${conf.toStringAsFixed(0)}%]',
                style: AppText.small.copyWith(fontSize: 10, color: AppColors.navy),
              ),
            );
          }),
        ],
      ),
    );
  }
}
