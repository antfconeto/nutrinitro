import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class DronePage extends StatelessWidget {
  const DronePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Drone'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flight_outlined,
              size: 72,
              color: AppColors.grayMedium.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Em breve',
              style: AppText.large.copyWith(color: AppColors.grayMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Integração com drones DJI.',
              style: AppText.body.copyWith(color: AppColors.grayMedium),
            ),
          ],
        ),
      ),
    );
  }
}
