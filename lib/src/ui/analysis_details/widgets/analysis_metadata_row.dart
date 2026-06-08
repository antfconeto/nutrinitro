import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class AnalysisMetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AnalysisMetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grayMedium.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.grayMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.small.copyWith(color: AppColors.gray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
