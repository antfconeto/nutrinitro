import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.grayLight,
  primaryColor: AppColors.green,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.orange,
    background: AppColors.grayLight,
    surface: AppColors.white,
    error: AppColors.tomato,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onBackground: AppColors.navy,
    onSurface: AppColors.navy,
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
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.white,
      disabledForegroundColor: AppColors.white.withOpacity(0.6),
      disabledBackgroundColor: AppColors.green.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: AppText.button,
      minimumSize: const Size(double.infinity, 52),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.orange,
      textStyle: AppText.medium,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.green,
      side: const BorderSide(color: AppColors.green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: AppText.button.copyWith(color: AppColors.green),
      minimumSize: const Size(double.infinity, 52),
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
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.tomato),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.green,
    foregroundColor: AppColors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    ),
  ),

  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFDDE4DD)),
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.greenLight.withOpacity(0.2),
    labelStyle: AppText.small.copyWith(color: AppColors.greenDark),
    side: const BorderSide(color: AppColors.greenLight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
);
