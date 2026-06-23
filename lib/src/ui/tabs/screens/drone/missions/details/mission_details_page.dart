import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/details/mission_details_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/details/mission_details_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MissionDetailsPage extends ConsumerStatefulWidget {
  final int missionId;

  const MissionDetailsPage({super.key, required this.missionId});

  @override
  ConsumerState<MissionDetailsPage> createState() => _MissionDetailsPageState();
}

class _MissionDetailsPageState extends ConsumerState<MissionDetailsPage> {
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(missionDetailsViewModelProvider.notifier)
          .load(widget.missionId),
    );
  }

  Future<void> _confirmStart(BuildContext context) async {
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
                color: AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flight_takeoff_outlined,
                color: AppColors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Iniciar missão?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'O drone irá decolar e executar a rota planejada automaticamente.',
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
              backgroundColor: AppColors.green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Iniciar',
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
        .read(missionDetailsViewModelProvider.notifier)
        .startMission();

    if (!context.mounted) return;

    if (success) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: 'Missão iniciada!'),
      );
      // Redireciona para o painel com a missão ativa
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/tabs',
        (route) => false,
        arguments: 2, // tab Drone
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionDetailsViewModelProvider);

    ref.listen<MissionDetailsState>(missionDetailsViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(missionDetailsViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: Text(state.mission?.title ?? 'Detalhes da Missão'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : state.mission == null
          ? _buildError()
          : _buildContent(context, state.mission!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        'Missão não encontrada.',
        style: AppText.body.copyWith(color: AppColors.grayMedium),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MissionModel mission) {
    final points = mission.waypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    final canStart =
        mission.status == MissionStatus.planned ||
        mission.status == MissionStatus.aborted;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info ──────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE4DD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: AppText.large.copyWith(
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          _statusBadge(mission.status),
                        ],
                      ),
                      if (mission.notes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          mission.notes!,
                          style: AppText.body.copyWith(
                            color: AppColors.grayMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoItem(
                            Icons.place_outlined,
                            '${mission.waypoints.length} waypoints',
                          ),
                          const SizedBox(width: 20),
                          _infoItem(
                            Icons.calendar_today_outlined,
                            DateFormat('dd/MM/yyyy').format(mission.createdAt),
                          ),
                          if (mission.startedAt != null) ...[
                            const SizedBox(width: 20),
                            _infoItem(
                              Icons.play_arrow_outlined,
                              DateFormat('HH:mm').format(mission.startedAt!),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Mapa ──────────────────────────────────────────────────────
                _sectionLabel('Rota planejada'),
                const SizedBox(height: 8),

                if (points.isNotEmpty)
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDE4DD)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: points.first,
                              initialZoom: 15,
                              initialCameraFit: points.length > 1
                                  ? CameraFit.bounds(
                                      bounds: LatLngBounds.fromPoints(points),
                                      padding: const EdgeInsets.all(36),
                                    )
                                  : null,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: _isSatellite
                                    ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'nutrinitro.com.nutrinitro',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: points,
                                    strokeWidth: 2.5,
                                    color:
                                        AppColors.green.withValues(alpha: 0.9),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers:
                                    mission.waypoints.asMap().entries.map((e) {
                                  final index = e.key;
                                  final wp = e.value;
                                  return Marker(
                                    point: LatLng(wp.latitude, wp.longitude),
                                    width: 30,
                                    height: 30,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.25),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'mission_details_satellite',
                              onPressed: () =>
                                  setState(() => _isSatellite = !_isSatellite),
                              backgroundColor: AppColors.white,
                              foregroundColor: _isSatellite
                                  ? AppColors.green
                                  : AppColors.grayMedium,
                              elevation: 2,
                              child: Icon(
                                _isSatellite
                                    ? Icons.map_outlined
                                    : Icons.satellite_alt_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Lista waypoints ───────────────────────────────────────────
                _sectionLabel('Waypoints'),
                const SizedBox(height: 8),
                ...mission.waypoints.asMap().entries.map((e) {
                  final index = e.key;
                  final wp = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE4DD)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${wp.latitude.toStringAsFixed(5)}, ${wp.longitude.toStringAsFixed(5)}',
                                  style: AppText.small.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wp.altitude.toStringAsFixed(0)}m  •  ${wp.speed.toStringAsFixed(1)}m/s  •  ${wp.capturePhoto ? '📷 Foto' : 'Sem foto'}',
                                  style: AppText.small.copyWith(
                                    color: AppColors.grayMedium,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ── Botão iniciar ─────────────────────────────────────────────────────
        if (canStart)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmStart(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.flight_takeoff_outlined,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'Iniciar Missão',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(MissionStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grayMedium),
        const SizedBox(width: 4),
        Text(label, style: AppText.small.copyWith(color: AppColors.grayMedium)),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppText.medium.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _statusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.planned:
        return AppColors.orangeLight;
      case MissionStatus.executing:
        return AppColors.green;
      case MissionStatus.completed:
        return AppColors.greenDark;
      case MissionStatus.aborted:
        return AppColors.tomato;
    }
  }
}
