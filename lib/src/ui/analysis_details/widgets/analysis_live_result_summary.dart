import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class AnalysisLiveResultSummary extends StatelessWidget {
  final Map<String, dynamic> result;

  const AnalysisLiveResultSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Estimativa da parcela',
                style: AppText.small.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (result['chlorophyll_spad'] != null)
            Text(
              'Clorofila: ${result['chlorophyll_spad']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
          if (result['nitrogen_content'] != null)
            Text(
              'Nitrogênio: ${result['nitrogen_content']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
          if (result['estimated_biomass'] != null)
            Text(
              'Biomassa: ${result['estimated_biomass']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
        ],
      ),
    );
  }
}
