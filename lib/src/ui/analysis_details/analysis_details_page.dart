import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class AnalysisDetailsPage extends StatelessWidget {
  final int analysisId;

  const AnalysisDetailsPage({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Detalhes da Análise'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Analysis ID: $analysisId',
          style: AppText.large.copyWith(color: AppColors.navy),
        ),
      ),
    );
  }
}
