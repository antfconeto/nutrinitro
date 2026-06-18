import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class DronePanelPage extends ConsumerWidget {
  const DronePanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: AppColors.grayMedium.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Painel do Drone',
            style: AppText.large.copyWith(color: AppColors.grayMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Conexão e telemetria em tempo real.',
            style: AppText.body.copyWith(color: AppColors.grayMedium),
          ),
        ],
      ),
    );
  }
}
