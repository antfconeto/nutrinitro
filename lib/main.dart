import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrinitro/core/theme/app_theme.dart';
import 'package:nutrinitro/features/image_selection/bloc/image_selection_bloc.dart';
import 'package:nutrinitro/features/image_selection/presentation/image_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImageSelectionBloc(),
      child: MaterialApp(
        title: 'NutriNitro Imagem',
        debugShowCheckedModeBanner: false,
        theme: appThemeData,
        home: const ImageSelectionScreen(),
      ),
    );
  }
}
