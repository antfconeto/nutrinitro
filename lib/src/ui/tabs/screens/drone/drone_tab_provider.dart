import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drone_tab_provider.g.dart';

/// Controls which sub-tab of DronePage is shown (0=Painel, 1=Missões, 2=Mídia).
/// Set before navigating to /tabs with arg 2 to open a specific drone sub-tab.
@Riverpod(keepAlive: true)
class DroneTabIndex extends _$DroneTabIndex {
  @override
  int build() => 0;

  void setTab(int i) => state = i;
}
