import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  const AppText._();

  static const TextStyle large = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.navy,
  );

  static const TextStyle medium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.navy,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grayMedium,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 14,
    color: AppColors.grayMedium,
  );
}
