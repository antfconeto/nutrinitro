import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/database/database_client.dart';
import 'package:nutrinitro/src/core/themes/app_theme.dart';
import 'package:nutrinitro/src/ui/splash/splash_page.dart';
import 'package:nutrinitro/src/ui/tabs/tabs_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_details_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/create/analysis_create_page.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/details/mission_details_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/monitor/mission_monitor_page.dart';

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

        // Main
        '/tabs': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialIndex = args is int ? args : 0;
          return TabsPage(initialIndex: initialIndex);
        },

        // Analysis
        '/analysis/create': (context) => const AnalysisCreatePage(),
        '/analysis/details': (context) {
          final analysisId = ModalRoute.of(context)!.settings.arguments as int;
          return AnalysisDetailsPage(analysisId: analysisId);
        },

        // Drone — Missions
        '/drone/mission/create': (context) {
          final mission =
              ModalRoute.of(context)?.settings.arguments as MissionModel?;
          return MissionCreatePage(initialMission: mission);
        },
        '/drone/mission/details': (context) {
          final missionId = ModalRoute.of(context)!.settings.arguments as int;
          return MissionDetailsPage(missionId: missionId);
        },
        '/drone/mission/monitor': (context) {
          final missionId = ModalRoute.of(context)!.settings.arguments as int;
          return MissionMonitorPage(missionId: missionId);
        },
      },
    );
  }
}
