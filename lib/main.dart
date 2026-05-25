import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/app_widget.dart';
import 'package:nutrinitro/src/data/services/database/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.init();

  runApp(
    const ProviderScope(
      child: AppWidget(),
    ),
  );
}