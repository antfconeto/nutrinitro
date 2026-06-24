import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_tab_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/drone_missions_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/panel/drone_panel_page.dart';

class DronePage extends ConsumerStatefulWidget {
  const DronePage({super.key});

  @override
  ConsumerState<DronePage> createState() => _DronePageState();
}

class _DronePageState extends ConsumerState<DronePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(droneTabIndexProvider);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    if (initialTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(droneTabIndexProvider.notifier).setTab(0);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Drone'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.6),
          labelStyle: AppText.small.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppText.small.copyWith(
            color: AppColors.white.withOpacity(0.6),
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Painel'),
            Tab(icon: Icon(Icons.route_outlined, size: 20), text: 'Missões'),
            Tab(
              icon: Icon(Icons.photo_library_outlined, size: 20),
              text: 'Mídia',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DronePanelPage(),
          DroneMissionsPage(),
          DroneMediaPage(),
        ],
      ),
    );
  }
}
