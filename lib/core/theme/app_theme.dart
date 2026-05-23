import "package:flutter/material.dart";
import "package:nutrinitro/core/theme/app_colors.dart";


final ThemeData appThemeData = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBeige,
    colorScheme:ColorScheme.fromSeed(
        seedColor: AppColors.darkGreen,
        brightness: Brightness.dark,
    )
);