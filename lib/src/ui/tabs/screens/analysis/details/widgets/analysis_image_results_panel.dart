import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis/image_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/widgets/analysis_metadata_row.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/widgets/analysis_metric_tile.dart';

class AnalysisImageResultsPanel extends StatelessWidget {
  final ImageModel image;
  final Map<String, dynamic> resultJson;

  const AnalysisImageResultsPanel({
    super.key,
    required this.image,
    required this.resultJson,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metadados da Imagem',
                style: AppText.medium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              if (image.wasAnalyzed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ANALISADA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AGUARDANDO ANÁLISE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnalysisMetadataRow(
            icon: Icons.calendar_month,
            label: 'Data Original',
            value: image.datetime != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(image.datetime!)
                : 'Não disponível no EXIF',
          ),
          AnalysisMetadataRow(
            icon: Icons.location_on_outlined,
            label: 'Coordenadas',
            value: image.hasLocation
                ? '${image.latitude!.toStringAsFixed(6)}, ${image.longitude!.toStringAsFixed(6)}'
                : 'Sem geolocalização',
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.grayLight),
          Text(
            'Resultado Agronômico',
            style: AppText.medium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          if (image.wasAnalyzed)
            _AnalyzedResults(resultJson: resultJson)
          else
            const _PendingAnalysisPlaceholder(),
        ],
      ),
    );
  }
}

class _AnalyzedResults extends StatelessWidget {
  final Map<String, dynamic> resultJson;

  const _AnalyzedResults({required this.resultJson});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resultJson.containsKey('chlorophyll_spad')) ...[
          Row(
            children: [
              Expanded(
                child: AnalysisMetricTile(
                  icon: Icons.biotech_outlined,
                  label: 'Clorofila',
                  value: resultJson['chlorophyll_spad'] ?? '45.2 SPAD',
                  accentColor: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              if (resultJson.containsKey('estimated_biomass'))
                Expanded(
                  child: AnalysisMetricTile(
                    icon: Icons.scale_outlined,
                    label: 'Biomassa',
                    value: resultJson['estimated_biomass'] ?? 'N/A',
                    accentColor: AppColors.greenDark,
                  ),
                )
              else if (resultJson.containsKey('nitrogen_content'))
                Expanded(
                  child: AnalysisMetricTile(
                    icon: Icons.grass_outlined,
                    label: 'Nitrogênio',
                    value: resultJson['nitrogen_content'] ?? 'N/A',
                    accentColor: AppColors.greenDark,
                  ),
                )
              else
                Expanded(
                  child: AnalysisMetricTile(
                    icon: Icons.psychology_outlined,
                    label: 'Modelo',
                    value: resultJson['prediction_method'] ?? 'SI',
                    accentColor: AppColors.navy,
                  ),
                ),
            ],
          ),
          if (resultJson.containsKey('nitrogen_content') &&
              resultJson.containsKey('estimated_biomass')) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnalysisMetricTile(
                    icon: Icons.grass_outlined,
                    label: 'Nitrogênio',
                    value: resultJson['nitrogen_content'] ?? 'N/A',
                    accentColor: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ],
          if (resultJson.containsKey('estimated_biomass') ||
              resultJson.containsKey('nitrogen_content')) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnalysisMetricTile(
                    icon: Icons.psychology_outlined,
                    label: 'Modelo de Predição',
                    value: resultJson['prediction_method'] ?? 'SI',
                    accentColor: AppColors.navy,
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          Row(
            children: [
              Expanded(
                child: AnalysisMetricTile(
                  icon: Icons.opacity,
                  label: 'Umidade',
                  value: resultJson['moisture'] ?? '13.5%',
                  accentColor: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalysisMetricTile(
                  icon: Icons.grass_outlined,
                  label: 'Proteína',
                  value: resultJson['protein'] ?? '8.2%',
                  accentColor: AppColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnalysisMetricTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Qualidade',
                  value: resultJson['quality'] ?? 'Boa',
                  accentColor: AppColors.orangeLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnalysisMetricTile(
                  icon: Icons.info_outline,
                  label: 'Status Técnico',
                  value: 'Detectado',
                  accentColor: AppColors.navy,
                ),
              ),
            ],
          ),
        ],
        if (resultJson['notes'] != null &&
            resultJson['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grayLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight, width: 1),
            ),
            child: Text(
              resultJson['notes'],
              style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.gray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingAnalysisPlaceholder extends StatelessWidget {
  const _PendingAnalysisPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grayLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.navy.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 32,
            color: AppColors.grayMedium.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta imagem ainda não foi processada.',
            style: AppText.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Utilize o botão "Iniciar Análise" no topo para rodar o modelo agronômico.',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: AppColors.grayMedium),
          ),
        ],
      ),
    );
  }
}
