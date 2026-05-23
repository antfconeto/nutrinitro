import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Color color;
  final double size;
  const AppLoading({
    super.key,
    this.color = AppColors.yellow,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.fourRotatingDots(
        color: color,
        size: size,
      ),
    );
  }
}
