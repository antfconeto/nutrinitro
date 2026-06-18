import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class DroneMissionsPage extends ConsumerWidget {
  const DroneMissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route_outlined,
            size: 64,
            color: AppColors.grayMedium.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Missões',
            style: AppText.large.copyWith(color: AppColors.grayMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Planeje e execute missões de waypoints.',
            style: AppText.body.copyWith(color: AppColors.grayMedium),
          ),
        ],
      ),
    );
  }
}
