import 'package:flutter/material.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class AnalysisStagePanel extends StatelessWidget {
  final List<AnalysisStageUpdate> stages;
  final AnalysisStageUpdate? currentStage;

  const AnalysisStagePanel({
    super.key,
    required this.stages,
    this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    final int activeStep = currentStage?.step ?? 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapas da análise',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          ...stages.map((stage) {
            final bool done = stage.step < activeStep;
            final bool active = stage.step == activeStep;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: done
                        ? const Icon(Icons.check_circle, color: AppColors.green, size: 20)
                        : active
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.green,
                                ),
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                color: AppColors.grayMedium.withOpacity(0.5),
                                size: 20,
                              ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stage.label,
                      style: AppText.small.copyWith(
                        color: active
                            ? AppColors.navy
                            : done
                                ? AppColors.grayMedium
                                : AppColors.grayMedium.withOpacity(0.7),
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
