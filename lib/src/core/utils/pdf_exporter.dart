import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/data/models/analysis/image_model.dart';

class PdfExporter {
  static Future<void> exportAnalysis(AnalysisModel analysis, BuildContext context) async {
    // 1. Show the beautiful green progress indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 3.5,
                ),
                const SizedBox(height: 20),
                Text(
                  'Gerando Relatório...',
                  style: AppText.medium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Processando e comprimindo imagens em segundo plano de forma fluida.',
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(
                    color: AppColors.grayMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    final pdf = pw.Document();

    // Curated color palette
    final primaryColor = PdfColor.fromHex('#2E7D32'); // Forest Green
    final darkColor = PdfColor.fromHex('#212121'); // Charcoal
    final lightColor = PdfColor.fromHex('#F5F5F5'); // Light Grey
    final greyColor = PdfColor.fromHex('#757575'); // Mid Grey
    final accentColor = PdfColor.fromHex('#E8F5E9'); // Light Green
    final borderColor = PdfColor.fromHex('#E0E0E0'); // Soft Grey Border

    // Resolve prediction model name
    String modelName = 'Não Especificado';
    if (analysis.images.isNotEmpty) {
      for (final img in analysis.images) {
        if (img.result != null) {
          try {
            final data = json.decode(img.result!);
            if (data is Map) {
              final String predictionMethod = data['prediction_method'] ?? '';
              if (predictionMethod.isNotEmpty) {
                modelName = predictionMethod;
                break;
              }
              final String notesStr = data['notes'] ?? '';
              if (notesStr.contains('SI')) {
                modelName = 'SI (Inclinação Espectral)';
                break;
              } else if (notesStr.contains('b/r')) {
                modelName = 'b/r (Razão Azul/Vermelho)';
                break;
              } else if (notesStr.contains('MLP 2') || notesStr.contains('Rede Neural')) {
                modelName = 'MLP 2 (Rede Neural MLP)';
                break;
              }
            }
          } catch (_) {}
        }
      }
    }

    // Try finding an overall average chlorophyll reading
    String averageSpad = 'N/A';
    double sumSpad = 0.0;
    int spadCount = 0;
    for (final img in analysis.images) {
      if (img.result != null) {
        try {
          final data = json.decode(img.result!);
          if (data is Map && data.containsKey('chlorophyll_spad')) {
            final String spadStr = data['chlorophyll_spad'];
            final numericStr = spadStr.replaceAll(' SPAD', '').trim();
            final val = double.tryParse(numericStr);
            if (val != null) {
              sumSpad += val;
              spadCount++;
            }
          }
        } catch (_) {}
      }
    }
    if (spadCount > 0) {
      averageSpad = '${(sumSpad / spadCount).toStringAsFixed(1)} SPAD';
    }

    // Try finding an overall average nitrogen reading
    String averageNitrogen = 'N/A';
    double sumNitrogen = 0.0;
    int nitrogenCount = 0;
    for (final img in analysis.images) {
      if (img.result != null) {
        try {
          final data = json.decode(img.result!);
          if (data is Map && data.containsKey('nitrogen_content')) {
            final String nStr = data['nitrogen_content'];
            final numericStr = nStr.replaceAll(' g/kg', '').trim();
            final val = double.tryParse(numericStr);
            if (val != null) {
              sumNitrogen += val;
              nitrogenCount++;
            }
          }
        } catch (_) {}
      }
    }
    if (nitrogenCount > 0) {
      averageNitrogen = '${(sumNitrogen / nitrogenCount).toStringAsFixed(2)} g/kg';
    }

    // Try finding an overall average biomass reading
    String averageBiomass = 'N/A';
    double sumBiomass = 0.0;
    int biomassCount = 0;
    for (final img in analysis.images) {
      if (img.result != null) {
        try {
          final data = json.decode(img.result!);
          if (data is Map && data.containsKey('estimated_biomass')) {
            final String bioStr = data['estimated_biomass'];
            final numericStr = bioStr.replaceAll(' t/ha', '').trim();
            final val = double.tryParse(numericStr);
            if (val != null) {
              sumBiomass += val;
              biomassCount++;
            }
          }
        } catch (_) {}
      }
    }
    if (biomassCount > 0) {
      averageBiomass = '${(sumBiomass / biomassCount).toStringAsFixed(2)} t/ha';
    }

    // Gather all paths to process in Isolate
    final List<String> allPaths = [];
    for (final imgModel in analysis.images) {
      if (imgModel.originalPath != null && imgModel.originalPath!.isNotEmpty) {
        allPaths.add(imgModel.originalPath!);
      }
      if (imgModel.analyzedPath != null && imgModel.analyzedPath!.isNotEmpty) {
        allPaths.add(imgModel.analyzedPath!);
      }
    }

    // Run CPU-heavy image resizing in a separate Isolate to keep UI 100% fluent
    Map<String, Uint8List> compressedMap = {};
    try {
      compressedMap = await Isolate.run(() {
        return _resizeImagesInIsolate(_ImageResizePayload(allPaths));
      });
    } catch (e) {
      print('Error running isolate image resizing: $e');
    }

    // Dismiss progress dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    final Map<String, pw.MemoryImage> loadedImages = {};
    compressedMap.forEach((path, bytes) {
      loadedImages[path] = pw.MemoryImage(bytes);
    });

    pw.MemoryImage? tryLoadImage(String? path) {
      if (path == null) return null;
      return loadedImages[path];
    }

    // 2. Build the PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Page Header / Branding
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RELATÓRIO DE ANÁLISE DE NITROGÊNIO',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'NutriNitro Intelligent Field Diagnostics',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: greyColor,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(analysis.datetime),
                  style: pw.TextStyle(fontSize: 11, color: greyColor),
                ),
              ],
            ),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 16),

            // Section 1: General Info Card
            pw.Container(
              decoration: pw.BoxDecoration(
                color: lightColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Informações Gerais da Análise',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Título do Talhão:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                            pw.Text(analysis.title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Cultura Selecionada:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                            pw.Text(analysis.crop?.name ?? 'Não Especificada', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Modelo de Predição:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                            pw.Text(modelName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Clorofila Média Geral:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                            pw.Text(averageSpad, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ),
                      if (averageBiomass != 'N/A')
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Biomassa Média Geral:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                              pw.Text(averageBiomass, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            ],
                          ),
                        ),
                      if (averageNitrogen != 'N/A')
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Nitrogênio Médio:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                              pw.Text(averageNitrogen, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (analysis.notes != null && analysis.notes!.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Text('Observações do Produtor:', style: pw.TextStyle(fontSize: 10, color: greyColor)),
                    pw.Text(analysis.notes!, style: pw.TextStyle(fontSize: 11, color: darkColor)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Section 2: GPS Positions & DBC plots
            pw.Text(
              'Distribuição Espacial das Amostras (GPS)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // # Index
                1: const pw.FlexColumnWidth(1.2), // GPS (Lat/Long)
                2: const pw.FlexColumnWidth(1.0), // DBC Bloco
                3: const pw.FlexColumnWidth(1.0), // DBC Parcela
                4: const pw.FlexColumnWidth(1.0), // Clorofila
                5: const pw.FlexColumnWidth(1.2), // Nitrogênio / Biomassa
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: accentColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Amostra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Coordenadas GPS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Bloco', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Parcela (DBC)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Leitura SPAD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        averageBiomass != 'N/A' && averageNitrogen != 'N/A'
                            ? 'N / Biomassa'
                            : (averageBiomass != 'N/A' ? 'Biomassa' : 'Nitrogênio'),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor),
                      ),
                    ),
                  ],
                ),
                ...analysis.images.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final img = entry.value;

                  String gpsStr = 'Sem sinal GPS';
                  if (img.latitude != null && img.longitude != null) {
                    gpsStr = '${img.latitude!.toStringAsFixed(6)}, ${img.longitude!.toStringAsFixed(6)}';
                  }

                  String bloco = 'N/A';
                  String parcela = 'Ponto $idx';
                  String spadVal = 'Pendente';
                  String nitrogenVal = 'Pendente';

                  if (img.result != null) {
                    try {
                      final data = json.decode(img.result!);
                      spadVal = data['chlorophyll_spad'] ?? 'N/A';
                      final hasBio = data.containsKey('estimated_biomass');
                      final hasN = data.containsKey('nitrogen_content');
                      if (hasBio && hasN) {
                        nitrogenVal = '${data['nitrogen_content']} | ${data['estimated_biomass']}';
                      } else if (hasBio) {
                        nitrogenVal = data['estimated_biomass'] ?? 'N/A';
                      } else {
                        nitrogenVal = data['nitrogen_content'] ?? 'N/A';
                      }
                    } catch (_) {}
                  }

                  // Resolve DBC Map from ponto_to_dbc mapping config
                  final mapDbc = {
                    1:  {"Bloco": "Bloco 1", "Parcela": "Parcela 1"},
                    2:  {"Bloco": "Bloco 1", "Parcela": "Parcela 2"},
                    3:  {"Bloco": "Bloco 1", "Parcela": "Parcela 3"},
                    4:  {"Bloco": "Bloco 1", "Parcela": "Parcela 4"},
                    5:  {"Bloco": "Bloco 2", "Parcela": "Parcela 1"},
                    6:  {"Bloco": "Bloco 2", "Parcela": "Parcela 2"},
                    7:  {"Bloco": "Bloco 2", "Parcela": "Parcela 3"},
                    8:  {"Bloco": "Bloco 2", "Parcela": "Parcela 4"},
                    9:  {"Bloco": "Bloco 3", "Parcela": "Parcela 1"},
                    10: {"Bloco": "Bloco 3", "Parcela": "Parcela 2"},
                    11: {"Bloco": "Bloco 3", "Parcela": "Parcela 3"},
                    12: {"Bloco": "Bloco 3", "Parcela": "Parcela 4"},
                  };

                  if (mapDbc.containsKey(idx)) {
                    bloco = mapDbc[idx]!['Bloco']!;
                    parcela = mapDbc[idx]!['Parcela']!;
                  }

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('#$idx', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(gpsStr, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(bloco, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(parcela, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(spadVal, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(nitrogenVal, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 24),

            // Section 3: Diagnostic comparisons side by side
            pw.Text(
              'Imagens de Diagnóstico e Mapas de Calor (Real vs Heatmap)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 12),

            ...analysis.images.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final img = entry.value;

              final originalImg = tryLoadImage(img.originalPath);
              final analyzedImg = img.analyzedPath == img.originalPath
                  ? null
                  : tryLoadImage(img.analyzedPath);

              String resultText = 'Não analisada';
              if (img.result != null) {
                try {
                  final data = json.decode(img.result!);
                  final String spad = data['chlorophyll_spad'] ?? 'N/A';
                  final hasBio = data.containsKey('estimated_biomass');
                  final hasN = data.containsKey('nitrogen_content');
                  if (hasBio && hasN) {
                    resultText = 'Clorofila: $spad | N: ${data['nitrogen_content']} | Biomassa: ${data['estimated_biomass']}';
                  } else if (hasBio) {
                    resultText = 'Clorofila: $spad | Biomassa: ${data['estimated_biomass']}';
                  } else {
                    resultText = 'Clorofila: $spad | Nitrogênio: ${data['nitrogen_content']}';
                  }
                } catch (_) {}
              }

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Amostra #$idx Parcela $idx',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor),
                        ),
                        pw.Text(
                          resultText,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Original image
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text('Imagem Real', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                              pw.SizedBox(height: 4),
                              originalImg != null
                                  ? pw.Container(
                                      height: 150,
                                      child: pw.Image(originalImg, fit: pw.BoxFit.contain),
                                    )
                                  : pw.Container(
                                      height: 150,
                                      color: lightColor,
                                      alignment: pw.Alignment.center,
                                      child: pw.Text('[Imagem Original Indisponível]', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                                    ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        // Right: Heatmap image
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text('Mapa de Clorofila (Heatmap)', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                              pw.SizedBox(height: 4),
                              analyzedImg != null
                                  ? pw.Container(
                                      height: 150,
                                      child: pw.Image(analyzedImg, fit: pw.BoxFit.contain),
                                    )
                                  : pw.Container(
                                      height: 150,
                                      color: lightColor,
                                      alignment: pw.Alignment.center,
                                      child: pw.Text('[Aguardando Análise]', style: pw.TextStyle(fontSize: 9, color: greyColor)),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Relatório gerado pelo NutriNitro Field Advisor',
                  style: pw.TextStyle(fontSize: 8, color: greyColor),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: greyColor),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 3. Trigger Print Preview & PDF Export Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_${analysis.title.replaceAll(' ', '_')}.pdf',
    );
  }
}

class _ImageResizePayload {
  final List<String> paths;
  _ImageResizePayload(this.paths);
}

Map<String, Uint8List> _resizeImagesInIsolate(_ImageResizePayload payload) {
  final Map<String, Uint8List> compressedImages = {};
  for (final path in payload.paths) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final int targetWidth = decoded.width > 600 ? 600 : decoded.width;
          final resized = img.copyResize(decoded, width: targetWidth);
          final compressed = img.encodeJpg(resized, quality: 75);
          compressedImages[path] = Uint8List.fromList(compressed);
        }
      }
    } catch (_) {}
  }
  return compressedImages;
}
