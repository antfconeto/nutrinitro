import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';

class DroneMediaThumbnail extends StatelessWidget {
  final DroneMediaFile file;
  final bool large;
  final bool fullscreen;

  const DroneMediaThumbnail({
    super.key,
    required this.file,
    this.large = false,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = file.type == DroneMediaType.video;
    final baseColor = file.category == DroneMediaCategory.preFlight
        ? AppColors.green.withValues(alpha: 0.15)
        : AppColors.orange.withValues(alpha: 0.12);

    if (fullscreen) {
      return SizedBox.expand(
        child: ColoredBox(
          color: baseColor,
          child: Center(
            child: Icon(
              isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
              size: 96,
              color: file.category == DroneMediaCategory.preFlight
                  ? AppColors.green
                  : AppColors.orange,
            ),
          ),
        ),
      );
    }

    return Container(
      color: baseColor,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
          size: large ? 48 : 28,
          color: file.category == DroneMediaCategory.preFlight
              ? AppColors.green
              : AppColors.orange,
        ),
      ),
    );
  }
}
