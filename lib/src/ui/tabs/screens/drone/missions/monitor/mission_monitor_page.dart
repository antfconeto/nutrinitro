import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_tab_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/monitor/mission_monitor_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/monitor/mission_monitor_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MissionMonitorPage extends ConsumerStatefulWidget {
  final int missionId;

  const MissionMonitorPage({super.key, required this.missionId});

  @override
  ConsumerState<MissionMonitorPage> createState() => _MissionMonitorPageState();
}

class _MissionMonitorPageState extends ConsumerState<MissionMonitorPage> {
  late final MapController _mapController;
  bool _isSatellite = true;
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    Future.microtask(
      () => ref
          .read(missionMonitorViewModelProvider.notifier)
          .init(widget.missionId),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionMonitorViewModelProvider);

    ref.listen<MissionMonitorState>(missionMonitorViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(missionMonitorViewModelProvider.notifier).clearError();
      }

      if (next.isMissionComplete && !_completionShown) {
        _completionShown = true;
        _showCompletionSheet(context, next);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (state.isMissionComplete) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }
        final confirmed = await _confirmLeave(context);
        if (confirmed && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.mission?.title ?? 'Missão em execução',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              if (state.hasTelemetry)
                Text(
                  'Bateria ${state.telemetry!.batteryPercent}%  •  ${state.telemetry!.altitude.toStringAsFixed(0)}m',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          actions: [
            if (!state.isMissionComplete)
              TextButton.icon(
                onPressed: state.isAborting
                    ? null
                    : () => _confirmAbort(context),
                icon: state.isAborting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(
                        Icons.stop_circle_outlined,
                        color: AppColors.tomato,
                        size: 20,
                      ),
                label: Text(
                  'Abortar',
                  style: AppText.small.copyWith(
                    color: AppColors.tomato,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : state.mission == null
            ? _buildError()
            : _buildMap(state),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        'Missão não encontrada.',
        style: AppText.body.copyWith(color: AppColors.white),
      ),
    );
  }

  Widget _buildMap(MissionMonitorState state) {
    final waypoints = state.mission!.waypoints;
    final points =
        waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
    final dronePos = state.dronePosition;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: dronePos ?? (points.isNotEmpty ? points.first : const LatLng(0, 0)),
            initialZoom: 16,
            initialCameraFit: points.length > 1
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(60),
                  )
                : null,
            minZoom: 3,
            maxZoom: 22,
          ),
          children: [
            TileLayer(
              urlTemplate: _isSatellite
                  ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'nutrinitro.com.nutrinitro',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 2.5,
                  color: AppColors.green.withValues(alpha: 0.7),
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
            MarkerLayer(
              markers: _buildWaypointMarkers(waypoints, state.currentWaypointIndex),
            ),
            if (dronePos != null)
              MarkerLayer(markers: [_buildDroneMarker(dronePos)]),
          ],
        ),

        // ── Progress overlay (top) ─────────────────────────────────────────
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _ProgressCard(state: state),
        ),

        // ── FABs (satellite + recenter) ────────────────────────────────────
        Positioned(
          bottom: 130,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'monitor_satellite',
                onPressed: () => setState(() => _isSatellite = !_isSatellite),
                backgroundColor: AppColors.white,
                foregroundColor:
                    _isSatellite ? AppColors.green : AppColors.grayMedium,
                elevation: 2,
                child: Icon(
                  _isSatellite
                      ? Icons.map_outlined
                      : Icons.satellite_alt_outlined,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'monitor_recenter',
                onPressed: () {
                  if (dronePos != null) {
                    _mapController.move(dronePos, _mapController.camera.zoom);
                  }
                },
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.green,
                elevation: 2,
                child: const Icon(Icons.my_location, size: 18),
              ),
            ],
          ),
        ),

        // ── Telemetry + controls (bottom) ──────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _TelemetryControls(state: state),
        ),
      ],
    );
  }

  List<Marker> _buildWaypointMarkers(
    List<DroneWaypointModel> waypoints,
    int currentIndex,
  ) {
    return waypoints.asMap().entries.map((e) {
      final i = e.key;
      final wp = e.value;
      final isDone = i < currentIndex;
      final isCurrent = i == currentIndex;

      final color = isDone
          ? const Color(0xFF9E9E9E) // cinza — já visitado
          : isCurrent
          ? AppColors.green
          : AppColors.navy.withValues(alpha: 0.7);

      return Marker(
        point: LatLng(wp.latitude, wp.longitude),
        width: isCurrent ? 32 : 26,
        height: isCurrent ? 32 : 26,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? Colors.white38 : AppColors.white,
              width: isCurrent ? 2.5 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: isDone ? Colors.white70 : AppColors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Marker _buildDroneMarker(LatLng pos) {
    return Marker(
      point: pos,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.flight, color: AppColors.white, size: 18),
        ),
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sair do monitoramento?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        content: Text(
          'A missão continuará em execução. Você pode acompanhar pelo painel do drone.',
          style: AppText.body.copyWith(color: AppColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppText.medium.copyWith(color: AppColors.grayMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sair',
              style: AppText.medium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmAbort(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.tomato.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stop_circle_outlined,
                color: AppColors.tomato,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Abortar missão?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'O drone retornará ao ponto de origem. As fotos já capturadas serão mantidas.',
          style: AppText.body.copyWith(color: AppColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppText.medium.copyWith(color: AppColors.grayMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Abortar',
              style: AppText.medium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(missionMonitorViewModelProvider.notifier)
        .abortMission();

    if (success && context.mounted) {
      Navigator.of(context).popUntil((route) => route.settings.name == '/tabs');
    }
  }

  void _showCompletionSheet(BuildContext context, MissionMonitorState state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompletionSheet(
        missionId: widget.missionId,
        missionTitle: state.mission?.title ?? '',
        waypointCount: state.totalWaypoints,
        photoCount: state.photoCount,
      ),
    );
  }
}

// ─── Progress card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final MissionMonitorState state;

  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final current = state.currentWaypointIndex + 1;
    final total = state.totalWaypoints;
    final progress = total > 0
        ? ((state.currentWaypointIndex + 1) / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.isPaused
                      ? AppColors.orangeLight
                      : AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.isPaused
                      ? 'Pausada'
                      : state.currentWaypointIndex < 0
                      ? 'Iniciando...'
                      : 'Waypoint $current de $total',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.photoCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${state.photoCount}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.greenLight),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Telemetry + controls ─────────────────────────────────────────────────────

class _TelemetryControls extends ConsumerWidget {
  final MissionMonitorState state;

  const _TelemetryControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(missionMonitorViewModelProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.92),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.hasTelemetry) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  icon: Icons.height,
                  label: 'Altitude',
                  value:
                      '${state.telemetry!.altitude.toStringAsFixed(1)}m',
                ),
                _MetricItem(
                  icon: Icons.speed_outlined,
                  label: 'Velocidade',
                  value:
                      '${state.telemetry!.speed.toStringAsFixed(1)}m/s',
                ),
                _MetricItem(
                  icon: Icons.battery_charging_full_outlined,
                  label: 'Bateria',
                  value: '${state.telemetry!.batteryPercent}%',
                  valueColor: state.telemetry!.batteryPercent <= 10
                      ? AppColors.tomato
                      : state.telemetry!.batteryPercent <= 20
                      ? AppColors.orangeLight
                      : AppColors.greenLight,
                ),
                _MetricItem(
                  icon: Icons.gps_fixed_outlined,
                  label: 'GPS',
                  value: state.telemetry!.gpsSignal.label,
                  valueColor: AppColors.greenLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (!state.isMissionComplete)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => vm.togglePause(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isPaused
                      ? AppColors.green
                      : AppColors.orangeLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  state.isPaused
                      ? Icons.play_arrow_outlined
                      : Icons.pause_outlined,
                  color: AppColors.white,
                  size: 22,
                ),
                label: Text(
                  state.isPaused ? 'Retomar' : 'Pausar missão',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Completion sheet ─────────────────────────────────────────────────────────

class _CompletionSheet extends ConsumerWidget {
  final int missionId;
  final String missionTitle;
  final int waypointCount;
  final int photoCount;

  const _CompletionSheet({
    required this.missionId,
    required this.missionTitle,
    required this.waypointCount,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.green,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Missão Concluída!',
            style: AppText.large.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            missionTitle,
            style: AppText.body.copyWith(color: AppColors.grayMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SummaryChip(
                icon: Icons.place_outlined,
                label: '$waypointCount waypoints',
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                icon: Icons.camera_alt_outlined,
                label: '$photoCount foto${photoCount != 1 ? 's' : ''}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  '/drone/mission/details',
                  arguments: missionId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.science_outlined, color: AppColors.white),
              label: const Text(
                'Ver resultados e fazer análise',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(droneTabIndexProvider.notifier).setTab(2);
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/tabs',
                  (route) => false,
                  arguments: 2,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDE4DD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.photo_library_outlined,
                color: AppColors.navy,
                size: 18,
              ),
              label: Text(
                'Ver em Mídia',
                style: AppText.medium.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Fechar',
              style: AppText.medium.copyWith(color: AppColors.grayMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grayMedium),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.small.copyWith(color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
