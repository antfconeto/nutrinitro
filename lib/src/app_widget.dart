import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/database/database_client.dart';
import 'package:nutrinitro/src/core/themes/app_theme.dart';
import 'package:nutrinitro/src/ui/splash/splash_page.dart';
import 'package:nutrinitro/src/ui/tabs/tabs_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(databaseClientProvider.future);

    return MaterialApp(
      title: 'NutriNitro',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: Env.debug,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/tabs': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialIndex = args is int ? args : 0;

          return TabsPage(initialIndex: initialIndex);
        },
      },
    );
  }
}
