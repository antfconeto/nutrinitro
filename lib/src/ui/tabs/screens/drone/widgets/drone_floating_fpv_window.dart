import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

import 'drone_live_fpv_feed.dart';

class DroneFloatingFpvWindow extends StatelessWidget {
  final bool isConnected;
  final bool isRecording;
  final double width;
  final double height;

  const DroneFloatingFpvWindow({
    super.key,
    required this.isConnected,
    required this.isRecording,
    this.width = 168,
    this.height = 106,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DroneLiveFpvFeed(
              isConnected: isConnected,
              isRecording: isRecording,
              isMiniMode: true,
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'FPV',
                  style: AppText.small.copyWith(
                    color: AppColors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
