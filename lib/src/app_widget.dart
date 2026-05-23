import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/themes/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriNitro',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: Env.debug,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const Scaffold(
              body: Center(
                child: Text('Home Page'),
              ),
            ),
      },
    );
  }
}
