import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_view_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_state.dart';

import 'widgets/drone_floating_fpv_window.dart';
import 'widgets/drone_gallery_tab.dart';
import 'widgets/drone_live_fpv_feed.dart';
import 'widgets/drone_map_route_builder.dart';

enum _HudTab { flight, gallery }

class DroneFlightHudPage extends ConsumerStatefulWidget {
  const DroneFlightHudPage({super.key});

  @override
  ConsumerState<DroneFlightHudPage> createState() => _DroneFlightHudPageState();
}

class _DroneFlightHudPageState extends ConsumerState<DroneFlightHudPage> {
  bool _isMapPrimary = false;
  bool _isPhotoMode = true;
  bool _isSatelliteMode = false;
  bool _showCameraSettings = false;
  _HudTab _activeTab = _HudTab.flight;
  int _galleryRefreshKey = 0;
  double _gimbalPitch = -90.0;
  String _selectedIso = 'Auto';
  String _selectedShutter = 'Auto';
  int? _whiteBalanceKelvin;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _showTakeoffModal(DroneViewModel viewModel) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _TakeoffHoldDialog(
        onConfirmed: viewModel.takeoff,
      ),
    );
  }

  void _onExitPressed(DroneViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desconectar?',
          style: AppText.medium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'A conexão com o drone será encerrada.',
          style: AppText.body.copyWith(color: AppColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppText.body.copyWith(color: AppColors.grayMedium),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.disconnectDrone();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.tomato,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }

  DroneMapRouteBuilder _buildMap({
    required DroneState state,
    required DroneViewModel viewModel,
    required bool isMiniMode,
  }) {
    return DroneMapRouteBuilder(
      waypoints: state.waypoints,
      telemetry: state.telemetry,
      connectionState: state.connectionState,
      isExecutingMission: state.isExecutingMission,
      activeWaypointIndex: state.activeWaypointIndex,
      onMapTap: viewModel.addWaypoint,
      onRemoveWaypoint: viewModel.removeWaypoint,
      onOptimizeRoute: viewModel.optimizeWaypoints,
      onClearRoute: viewModel.clearWaypoints,
      onStartMission: viewModel.startMission,
      onAbortMission: viewModel.abortMission,
      isMiniMode: isMiniMode,
      hideHeader: true,
      isSatelliteMode: _isSatelliteMode,
      onSatelliteModeChanged: (value) =>
          setState(() => _isSatelliteMode = value),
      mapController: isMiniMode ? null : _mapController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(droneViewModelProvider);
    final viewModel = ref.read(droneViewModelProvider.notifier);

    ref.listen<DroneState>(droneViewModelProvider, (previous, next) {
      if (next.connectionState != DroneConnectionState.connected) {
        Navigator.of(context).pop();
      }
    });

    final isConnected =
        state.connectionState == DroneConnectionState.connected;
    final isFlying = state.telemetry.isFlying;
    final isFlightTab = _activeTab == _HudTab.flight;

    final fpvFeed = DroneLiveFpvFeed(
      isConnected: isConnected,
      isRecording: state.isRecordingVideo,
      isMiniMode: _isMapPrimary,
    );

    final mapBuilder = _buildMap(
      state: state,
      viewModel: viewModel,
      isMiniMode: !_isMapPrimary,
    );

    final pipContent = _isMapPrimary ? fpvFeed : _buildMap(
      state: state,
      viewModel: viewModel,
      isMiniMode: true,
    );

    return Scaffold(
      backgroundColor: isFlightTab ? Colors.black : AppColors.grayLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isFlightTab) ...[
            Positioned.fill(
              child: _isMapPrimary ? mapBuilder : fpvFeed,
            ),

            // Gradiente superior para legibilidade
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Positioned.fill(
              child: DroneGalleryTab(
                key: ValueKey(_galleryRefreshKey),
                contentPadding: const EdgeInsets.only(
                  top: 44,
                  right: 188,
                  bottom: 64,
                ),
              ),
            ),
            if (isConnected)
              Positioned(
                right: 16,
                top: 52,
                child: DroneFloatingFpvWindow(
                  isConnected: isConnected,
                  isRecording: state.isRecordingVideo,
                ),
              ),
          ],

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopStatusBar(
              state: state,
              onExit: () => _onExitPressed(viewModel),
              lightTheme: !isFlightTab,
            ),
          ),

          if (isFlightTab) ...[
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: _FlightControlColumn(
                isFlying: isFlying,
                onTakeoffLand: () {
                  if (isFlying) {
                    viewModel.land();
                  } else {
                    _showTakeoffModal(viewModel);
                  }
                },
                onReturnHome: viewModel.returnToHome,
                onEmergencyStop: viewModel.emergencyStop,
              ),
            ),
          ),

          // Controles de câmera — direita
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_showCameraSettings)
                    _ExposureSettingsPanel(
                      selectedIso: _selectedIso,
                      selectedShutter: _selectedShutter,
                      selectedWbKelvin: _whiteBalanceKelvin,
                      onIsoChanged: (v) => setState(() => _selectedIso = v),
                      onShutterChanged: (v) =>
                          setState(() => _selectedShutter = v),
                      onWbChanged: (v) =>
                          setState(() => _whiteBalanceKelvin = v),
                    ),
                  if (_showCameraSettings) const SizedBox(height: 10),
                  _CameraControlColumn(
                    isPhotoMode: _isPhotoMode,
                    isRecording: state.isRecordingVideo,
                    gimbalPitch: _gimbalPitch,
                    showSettings: _showCameraSettings,
                    onToggleSettings: () => setState(
                      () => _showCameraSettings = !_showCameraSettings,
                    ),
                    onToggleMode: () =>
                        setState(() => _isPhotoMode = !_isPhotoMode),
                    onShutter: () {
                      if (_isPhotoMode) {
                        viewModel.capturePhoto();
                      } else {
                        viewModel.toggleVideoRecording();
                      }
                    },
                    onGimbalChanged: (value) {
                      setState(() => _gimbalPitch = value);
                      viewModel.setGimbalPitch(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          // PiP — canto inferior esquerdo (estilo DJI)
          Positioned(
            left: 16,
            bottom: 72,
            child: GestureDetector(
              onTap: () => setState(() => _isMapPrimary = !_isMapPrimary),
              child: Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      IgnorePointer(child: pipContent),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _isMapPrimary ? 'FPV' : 'Mapa',
                            style: AppText.small.copyWith(
                              color: AppColors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],

          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: _HudTabBar(
                activeTab: _activeTab,
                onChanged: (tab) => setState(() {
                  _activeTab = tab;
                  if (tab == _HudTab.gallery) _galleryRefreshKey++;
                }),
                lightBackground: !isFlightTab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudTabBar extends StatelessWidget {
  final _HudTab activeTab;
  final ValueChanged<_HudTab> onChanged;
  final bool lightBackground;

  const _HudTabBar({
    required this.activeTab,
    required this.onChanged,
    this.lightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: lightBackground
            ? AppColors.white
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: lightBackground
              ? const Color(0xFFDDE4DD)
              : AppColors.white.withValues(alpha: 0.12),
        ),
        boxShadow: lightBackground
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HudTabItem(
            icon: Icons.flight_rounded,
            label: 'Voo',
            selected: activeTab == _HudTab.flight,
            onTap: () => onChanged(_HudTab.flight),
            lightBackground: lightBackground,
          ),
          _HudTabItem(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            selected: activeTab == _HudTab.gallery,
            onTap: () => onChanged(_HudTab.gallery),
            lightBackground: lightBackground,
          ),
        ],
      ),
    );
  }
}

class _HudTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool lightBackground;

  const _HudTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.lightBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.green
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.white
                    : (lightBackground
                        ? AppColors.grayMedium
                        : AppColors.white.withValues(alpha: 0.75)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.small.copyWith(
                  color: selected
                      ? AppColors.white
                      : (lightBackground
                          ? AppColors.navy
                          : AppColors.white.withValues(alpha: 0.75)),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final DroneState state;
  final VoidCallback onExit;
  final bool lightTheme;

  const _TopStatusBar({
    required this.state,
    required this.onExit,
    this.lightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final battery = state.telemetry.batteryPercentage;
    final batteryColor =
        battery < 25 ? AppColors.tomato : AppColors.greenLight;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatusBadge(
                label: state.isSimulatorMode ? 'SIM' : 'GPS',
                color: state.isSimulatorMode ? AppColors.orange : AppColors.green,
              ),
              const SizedBox(width: 12),
              _HudMetric(
                icon: Icons.satellite_alt_outlined,
                value: '${state.telemetry.satelliteCount}',
                lightTheme: lightTheme,
              ),
              const SizedBox(width: 10),
              _HudMetric(
                icon: Icons.battery_std_outlined,
                value: '$battery%',
                color: batteryColor,
                lightTheme: lightTheme,
              ),
              const SizedBox(width: 10),
              _HudMetric(
                icon: Icons.signal_cellular_alt,
                value: '${state.connectionHealth}%',
                lightTheme: lightTheme,
              ),

              const Spacer(),

              _HudTelemetry(
                label: 'H',
                value: '${state.telemetry.altitude.toStringAsFixed(1)}m',
                lightTheme: lightTheme,
              ),
              const SizedBox(width: 12),
              _HudTelemetry(
                label: 'HS',
                value: state.telemetry.speedHorizontal.toStringAsFixed(1),
                lightTheme: lightTheme,
              ),
              const SizedBox(width: 12),
              _HudTelemetry(
                label: 'VS',
                value: state.telemetry.speedVertical.toStringAsFixed(1),
                lightTheme: lightTheme,
              ),
              const SizedBox(width: 12),
              _HudTelemetry(
                label: '°',
                value: state.telemetry.yaw.toStringAsFixed(0),
                lightTheme: lightTheme,
              ),

              const SizedBox(width: 12),

              _HudIconButton(
                icon: Icons.power_settings_new,
                onTap: onExit,
                lightTheme: lightTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppText.small.copyWith(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;
  final bool lightTheme;

  const _HudMetric({
    required this.icon,
    required this.value,
    this.color,
    this.lightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (lightTheme
            ? AppColors.navy
            : AppColors.white.withValues(alpha: 0.85));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(
          value,
          style: AppText.small.copyWith(
            color: c,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HudTelemetry extends StatelessWidget {
  final String label;
  final String value;
  final bool lightTheme;

  const _HudTelemetry({
    required this.label,
    required this.value,
    this.lightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppText.small.copyWith(
              color: lightTheme
                  ? AppColors.grayMedium
                  : AppColors.white.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: AppText.small.copyWith(
              color: lightTheme
                  ? AppColors.navy
                  : AppColors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool lightTheme;

  const _HudIconButton({
    required this.icon,
    required this.onTap,
    this.lightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: lightTheme
              ? AppColors.grayLight
              : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: lightTheme
              ? AppColors.navy
              : AppColors.white.withValues(alpha: 0.8),
          size: 16,
        ),
      ),
    );
  }
}

class _FlightControlColumn extends StatelessWidget {
  final bool isFlying;
  final VoidCallback onTakeoffLand;
  final VoidCallback onReturnHome;
  final VoidCallback onEmergencyStop;

  const _FlightControlColumn({
    required this.isFlying,
    required this.onTakeoffLand,
    required this.onReturnHome,
    required this.onEmergencyStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudRoundButton(
          icon: isFlying ? Icons.flight_land : Icons.flight_takeoff,
          accent: isFlying ? AppColors.navy : AppColors.green,
          onTap: onTakeoffLand,
        ),
        const SizedBox(height: 10),
        _HudRoundButton(
          icon: Icons.home_rounded,
          accent: AppColors.orangeLight,
          onTap: onReturnHome,
          enabled: isFlying,
        ),
        const SizedBox(height: 10),
        _HudRoundButton(
          icon: Icons.stop_rounded,
          accent: AppColors.tomato,
          onTap: onEmergencyStop,
        ),
      ],
    );
  }
}

class _CameraControlColumn extends StatelessWidget {
  final bool isPhotoMode;
  final bool isRecording;
  final double gimbalPitch;
  final bool showSettings;
  final VoidCallback onToggleSettings;
  final VoidCallback onToggleMode;
  final VoidCallback onShutter;
  final ValueChanged<double> onGimbalChanged;

  const _CameraControlColumn({
    required this.isPhotoMode,
    required this.isRecording,
    required this.gimbalPitch,
    required this.showSettings,
    required this.onToggleSettings,
    required this.onToggleMode,
    required this.onShutter,
    required this.onGimbalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: AppColors.greenLight.withValues(alpha: 0.8),
                inactiveTrackColor: AppColors.white.withValues(alpha: 0.12),
                thumbColor: AppColors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: gimbalPitch,
                min: -90,
                max: 30,
                onChanged: onGimbalChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HudRoundButton(
              icon: Icons.tune_rounded,
              accent: showSettings ? AppColors.greenLight : AppColors.white,
              onTap: onToggleSettings,
              size: 36,
            ),
            const SizedBox(height: 10),
            _HudRoundButton(
              icon: isPhotoMode
                  ? Icons.videocam_outlined
                  : Icons.camera_alt_outlined,
              accent: AppColors.white.withValues(alpha: 0.85),
              onTap: onToggleMode,
              size: 36,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onShutter,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.85),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: isPhotoMode ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isPhotoMode ? null : BorderRadius.circular(3),
                    color: isPhotoMode
                        ? AppColors.white
                        : (isRecording ? AppColors.tomato : AppColors.white),
                  ),
                  child: !isPhotoMode && isRecording
                      ? const Icon(Icons.stop, color: AppColors.white, size: 16)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExposureSettingsPanel extends StatelessWidget {
  static const _kelvinOptions = <int?>[
    null,
    2500,
    3000,
    3500,
    4000,
    4500,
    5000,
    5600,
    6000,
    6500,
    7000,
    7500,
    8000,
    9000,
    10000,
  ];

  final String selectedIso;
  final String selectedShutter;
  final int? selectedWbKelvin;
  final ValueChanged<String> onIsoChanged;
  final ValueChanged<String> onShutterChanged;
  final ValueChanged<int?> onWbChanged;

  const _ExposureSettingsPanel({
    required this.selectedIso,
    required this.selectedShutter,
    required this.selectedWbKelvin,
    required this.onIsoChanged,
    required this.onShutterChanged,
    required this.onWbChanged,
  });

  static String _formatKelvin(int? kelvin) =>
      kelvin == null ? 'Auto' : '$kelvin K';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Configurações de Exposição',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HudExposureDropdown(
                  label: 'ISO',
                  value: selectedIso,
                  items: const ['Auto', '100', '200', '400', '800', '1600'],
                  onChanged: onIsoChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HudExposureDropdown(
                  label: 'Shutter',
                  value: selectedShutter,
                  items: const [
                    'Auto',
                    '1/60',
                    '1/120',
                    '1/250',
                    '1/500',
                    '1/1000',
                  ],
                  onChanged: onShutterChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HudWhiteBalanceDropdown(
                  label: 'W.Balance',
                  value: selectedWbKelvin,
                  options: _kelvinOptions,
                  onChanged: onWbChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudWhiteBalanceDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final List<int?> options;
  final ValueChanged<int?> onChanged;

  const _HudWhiteBalanceDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.small.copyWith(
            fontSize: 9,
            color: AppColors.grayMedium,
          ),
        ),
        const SizedBox(height: 2),
        DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: selected,
            isExpanded: true,
            isDense: true,
            style: AppText.small.copyWith(
              color: AppColors.navy,
              fontSize: 10,
            ),
            dropdownColor: AppColors.white,
            items: options
                .map(
                  (kelvin) => DropdownMenuItem<int?>(
                    value: kelvin,
                    child: Text(
                      _ExposureSettingsPanel._formatKelvin(kelvin),
                      style: AppText.small.copyWith(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
        Container(height: 1.5, color: AppColors.green),
      ],
    );
  }
}

class _HudExposureDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _HudExposureDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.small.copyWith(
            fontSize: 9,
            color: AppColors.grayMedium,
          ),
        ),
        const SizedBox(height: 2),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            style: AppText.small.copyWith(
              color: AppColors.navy,
              fontSize: 10,
            ),
            dropdownColor: AppColors.white,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: AppText.small.copyWith(fontSize: 10)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
        Container(height: 1.5, color: AppColors.green),
      ],
    );
  }
}

class _HudRoundButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool enabled;
  final double size;

  const _HudRoundButton({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.enabled = true,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(icon, color: accent, size: size * 0.42),
        ),
      ),
    );
  }
}

class _TakeoffHoldDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _TakeoffHoldDialog({required this.onConfirmed});

  @override
  State<_TakeoffHoldDialog> createState() => _TakeoffHoldDialogState();
}

class _TakeoffHoldDialogState extends State<_TakeoffHoldDialog>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
          widget.onConfirmed();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    setState(() => _isHolding = true);
    _controller.forward(from: _controller.value);
  }

  void _cancelHold() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    _controller.reverse(from: _controller.value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Decolar',
        style: AppText.medium.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verifique a área ao redor do drone antes de decolar.',
              style: AppText.body.copyWith(color: AppColors.grayMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 4,
                          color: AppColors.green,
                          backgroundColor: AppColors.grayLight,
                        ),
                      ),
                      Listener(
                        onPointerDown: (_) => _startHold(),
                        onPointerUp: (_) => _cancelHold(),
                        onPointerCancel: (_) => _cancelHold(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isHolding
                                ? AppColors.green
                                : AppColors.green.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.flight_takeoff_rounded,
                            color: _isHolding
                                ? AppColors.white
                                : AppColors.green,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              _isHolding
                  ? 'Mantenha pressionado…'
                  : 'Pressione e segure para decolar',
              style: AppText.small.copyWith(
                color: _isHolding ? AppColors.green : AppColors.grayMedium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppText.body.copyWith(color: AppColors.grayMedium),
          ),
        ),
      ],
    );
  }
}
