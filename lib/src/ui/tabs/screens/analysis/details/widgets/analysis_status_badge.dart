import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/const/analysis_status.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';

class AnalysisStatusBadge extends StatelessWidget {
  final AnalysisStatus status;
  final bool isAnalyzing;

  const AnalysisStatusBadge({
    super.key,
    required this.status,
    required this.isAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.green;
    String label = status.label;

    if (isAnalyzing || status == AnalysisStatus.processing) {
      color = AppColors.orange;
      label = 'Analisando';
    } else {
      switch (status) {
        case AnalysisStatus.pending:
          color = AppColors.orangeLight;
        case AnalysisStatus.processing:
          color = AppColors.orange;
        case AnalysisStatus.completed:
          color = AppColors.green;
        case AnalysisStatus.error:
          color = AppColors.tomato;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnalyzing || status == AnalysisStatus.processing) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
