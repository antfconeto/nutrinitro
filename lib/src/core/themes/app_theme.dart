import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.grayLight,
  primaryColor: AppColors.greenDark,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.greenDark,
    background: AppColors.grayLight,
  ),

  textTheme: const TextTheme(
    displayLarge: AppText.large,
    titleLarge: AppText.large,
    bodyLarge: AppText.medium,
    bodyMedium: AppText.body,
    bodySmall: AppText.small,
    labelSmall: AppText.small,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.greenDark,
      foregroundColor: AppColors.white,
      disabledForegroundColor: AppColors.white.withOpacity(0.6),
      disabledBackgroundColor: AppColors.greenDark.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: AppText.button,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.blue,
      textStyle: AppText.medium,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    hintStyle: AppText.hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.greenDark,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
