import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_details_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_details_view_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_pipeline_viewer.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/widgets/analysis_live_result_summary.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/widgets/analysis_status_badge.dart';

class AnalysisHeaderCard extends ConsumerWidget {
  final AnalysisModel analysis;
  final bool isAnalyzing;
  final VoidCallback onStartAnalysis;

  const AnalysisHeaderCard({
    super.key,
    required this.analysis,
    required this.isAnalyzing,
    required this.onStartAnalysis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisDetailsViewModelProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.title,
                      style: AppText.large.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.grayMedium,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM/yyyy  HH:mm').format(analysis.datetime),
                          style: AppText.small.copyWith(
                            fontSize: 13,
                            color: AppColors.grayMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnalysisStatusBadge(
                status: analysis.status,
                isAnalyzing: isAnalyzing,
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.grayLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (analysis.crop != null)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        analysis.crop!.icon,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.grass,
                          size: 16,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cultura',
                          style: AppText.small.copyWith(
                            fontSize: 10,
                            color: AppColors.grayMedium,
                          ),
                        ),
                        Text(
                          analysis.crop!.name,
                          style: AppText.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Imagens',
                        style: AppText.small.copyWith(
                          fontSize: 10,
                          color: AppColors.grayMedium,
                        ),
                      ),
                      Text(
                        '${analysis.images.length}',
                        style: AppText.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (isAnalyzing && state.totalImagesToAnalyze > 0) ...[
            const SizedBox(height: 16),
            _AnalysisProgressPanel(state: state),
          ],
          if (analysis.isPending || analysis.isProcessing || analysis.isCompleted || isAnalyzing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAnalyzing ? null : onStartAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      analysis.isCompleted ? AppColors.navy : AppColors.green,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Icon(
                        analysis.isCompleted
                            ? Icons.refresh_outlined
                            : Icons.analytics_outlined,
                      ),
                label: Text(
                  isAnalyzing
                      ? 'Analisando...'
                      : analysis.isCompleted
                          ? 'Refazer Análise'
                          : analysis.isProcessing
                              ? 'Processar novamente'
                              : 'Iniciar Análise',
                  style: AppText.button.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisProgressPanel extends StatelessWidget {
  final AnalysisDetailsState state;

  const _AnalysisProgressPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processando Imagens...',
                style: AppText.small.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.currentAnalyzingImageIndex} de ${state.totalImagesToAnalyze}',
                style: AppText.small.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.totalImagesToAnalyze > 0
                  ? state.currentAnalyzingImageIndex / state.totalImagesToAnalyze
                  : 0.0,
              backgroundColor: AppColors.green.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analisando imagem ${state.currentAnalyzingImageIndex} com algoritmos de reflectância...',
            style: const TextStyle(
              color: AppColors.grayMedium,
              fontSize: 11,
            ),
          ),
          if (state.isAnalyzing) ...[
            const SizedBox(height: 12),
            AnalysisPipelineViewer(
              snapshot: state.currentPipelineSnapshot,
              stages: state.recipeStages,
              currentStage: state.currentAnalysisStage,
            ),
            if (state.currentEstimatedResult != null) ...[
              const SizedBox(height: 10),
              AnalysisLiveResultSummary(result: state.currentEstimatedResult!),
            ],
          ],
        ],
      ),
    );
  }
}
