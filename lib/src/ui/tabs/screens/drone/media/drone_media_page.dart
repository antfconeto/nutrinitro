import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class DroneMediaPage extends ConsumerWidget {
  const DroneMediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.grayMedium.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Mídia',
            style: AppText.large.copyWith(color: AppColors.grayMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Imagens capturadas pelo drone.',
            style: AppText.body.copyWith(color: AppColors.grayMedium),
          ),
        ],
      ),
    );
  }
}
