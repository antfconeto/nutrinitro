import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/create/analysis_create_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_tab_provider.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(missionDetailsViewModelProvider.notifier)
          .load(widget.missionId),
    );
  }

  Future<void> _navigateToEdit(BuildContext context, MissionModel mission) async {
    await Navigator.of(context).pushNamed(
      '/drone/mission/create',
      arguments: mission,
    );
    if (!mounted) return;
    ref.read(missionDetailsViewModelProvider.notifier).load(widget.missionId);
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
                color: AppColors.green.withValues(alpha: 0.1),
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

    final missionId = await ref
        .read(missionDetailsViewModelProvider.notifier)
        .startMission();

    if (!context.mounted) return;

    if (missionId != null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: 'Missão iniciada!'),
      );
      Navigator.of(context).pushNamed(
        '/drone/mission/monitor',
        arguments: missionId,
      );
    }
  }

  Future<void> _confirmRedo(BuildContext context) async {
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
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.replay, color: AppColors.navy, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Refazer missão?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'Será criada uma nova missão com os mesmos waypoints, pronta para ser iniciada.',
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
              'Refazer',
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

    final newMissionId = await ref
        .read(missionDetailsViewModelProvider.notifier)
        .cloneMission();

    if (!context.mounted) return;

    if (newMissionId != null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: 'Nova missão criada!'),
      );
      Navigator.of(context).pushReplacementNamed(
        '/drone/mission/details',
        arguments: newMissionId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionDetailsViewModelProvider);
    final droneConnectionState = ref.watch(
      droneServiceProvider.select((s) => s.connectionState),
    );
    final isConnected = droneConnectionState == DroneConnectionState.connected;

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
        actions: [
          if (state.mission != null &&
              (state.mission!.status == MissionStatus.planned ||
                  state.mission!.status == MissionStatus.aborted))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar missão',
              onPressed: () => _navigateToEdit(context, state.mission!),
            ),
          if (state.mission != null &&
              state.mission!.status == MissionStatus.completed)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Refazer missão',
              onPressed: state.isStarting
                  ? null
                  : () => _confirmRedo(context),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : state.mission == null
          ? _buildError()
          : _buildContent(context, state, isConnected),
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

  Widget _buildContent(
    BuildContext context,
    MissionDetailsState state,
    bool isConnected,
  ) {
    final mission = state.mission!;
    final canStart =
        mission.status == MissionStatus.planned ||
        mission.status == MissionStatus.aborted;

    return Column(
      children: [
        // ── Drone not connected warning ────────────────────────────────────
        if (canStart && !isConnected)
          Material(
            color: AppColors.orangeLight.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_outlined,
                    size: 16,
                    color: AppColors.orangeLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drone desconectado. Conecte no painel antes de iniciar.',
                      style: AppText.small.copyWith(
                        color: AppColors.orangeLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info ─────────────────────────────────────────────────────
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

                _MissionMapCard(mission: mission),

                // ── Imagens capturadas (missão concluída) ─────────────────
                if (mission.status == MissionStatus.completed &&
                    state.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Imagens capturadas (${state.images.length})'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final img = state.images[i];
                        return GestureDetector(
                          onTap: () => _openImageViewer(context, state.images, i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(img.localPath),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: AppColors.grayLight,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.grayMedium,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Lista waypoints ─────────────────────────────────────────
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
                                  '${wp.altitude.toStringAsFixed(0)}m  •  ${wp.speed.toStringAsFixed(1)}m/s  •  ${wp.capturePhoto ? 'Foto' : 'Sem foto'}',
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

        // ── Botões de ação ─────────────────────────────────────────────────
        if (canStart)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (isConnected && !state.isStarting)
                      ? () => _confirmStart(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    disabledBackgroundColor:
                        AppColors.green.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: state.isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Icon(
                          isConnected
                              ? Icons.flight_takeoff_outlined
                              : Icons.wifi_off_outlined,
                          color: AppColors.white,
                        ),
                  label: Text(
                    state.isStarting
                        ? 'Iniciando...'
                        : isConnected
                        ? 'Iniciar Missão'
                        : 'Conecte o drone primeiro',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (mission.status == MissionStatus.completed && state.images.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAnalysis(context, state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.science_outlined,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Fazer Análise',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadAllImages(context, state.images),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDE4DD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.download_outlined,
                        color: AppColors.navy,
                        size: 18,
                      ),
                      label: Text(
                        'Baixar ${state.images.length} foto${state.images.length != 1 ? 's' : ''}',
                        style: AppText.medium.copyWith(
                          color: AppColors.navy,
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
                        ref
                            .read(droneTabIndexProvider.notifier)
                            .setTab(2);
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
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToAnalysis(BuildContext context, MissionDetailsState state) {
    final mission = state.mission!;
    final preset = DroneAnalysisPreset(
      title: mission.title,
      datetime: mission.completedAt ?? mission.startedAt ?? DateTime.now(),
      notes: mission.notes,
      images: state.images.map((img) => File(img.localPath)).toList(),
      sourceNames: List.generate(state.images.length, (i) => 'Foto ${i + 1}'),
    );
    Navigator.of(context).pushNamed('/analysis/create', arguments: preset);
  }

  Future<void> _downloadAllImages(
    BuildContext context,
    List<DroneImageModel> images,
  ) async {
    try {
      for (final img in images) {
        await Gal.putImage(img.localPath);
      }
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message:
                '${images.length} foto${images.length != 1 ? 's' : ''} salva${images.length != 1 ? 's' : ''} na galeria.',
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Erro ao salvar na galeria.'),
        );
      }
    }
  }

  void _openImageViewer(
    BuildContext context,
    List<DroneImageModel> images,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DroneImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _statusBadge(MissionStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class _MissionMapCard extends StatefulWidget {
  final MissionModel mission;

  const _MissionMapCard({required this.mission});

  @override
  State<_MissionMapCard> createState() => _MissionMapCardState();
}

class _MissionMapCardState extends State<_MissionMapCard> {
  bool _isSatellite = false;
  int? _selectedIndex;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waypoints = widget.mission.waypoints;
    if (waypoints.isEmpty) return const SizedBox.shrink();

    final points =
        waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();

    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final center = LatLng(lat / points.length, lng / points.length);

    final selectedWp =
        _selectedIndex != null ? waypoints[_selectedIndex!] : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.route_outlined,
                      size: 18,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rota planejada',
                      style: AppText.medium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${waypoints.length} waypoints',
                  style: AppText.small.copyWith(
                    color: AppColors.grayMedium,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: points.first,
                      initialZoom: 15,
                      initialCameraFit: points.length > 1
                          ? CameraFit.bounds(
                              bounds: LatLngBounds.fromPoints(points),
                              padding: const EdgeInsets.all(36),
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
                            color: AppColors.green.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: waypoints.asMap().entries.map((e) {
                          final i = e.key;
                          final wp = e.value;
                          final isSelected = _selectedIndex == i;
                          return Marker(
                            point: LatLng(wp.latitude, wp.longitude),
                            width: 32,
                            height: 32,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedIndex =
                                    _selectedIndex == i ? null : i;
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.greenDark
                                      : AppColors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: isSelected ? 3 : 2,
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
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                    bottom: selectedWp != null ? 72 : 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
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
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'mission_details_recenter',
                          onPressed: () {
                            if (points.length > 1) {
                              _mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(points),
                                  padding: const EdgeInsets.all(36),
                                ),
                              );
                            } else {
                              _mapController.move(center, 15);
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
                  if (selectedWp != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.95),
                          border: const Border(
                            top: BorderSide(color: Color(0xFFDDE4DD)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${_selectedIndex! + 1}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  _infoChip(
                                    Icons.height,
                                    '${selectedWp.altitude.toStringAsFixed(0)}m',
                                  ),
                                  const SizedBox(width: 12),
                                  _infoChip(
                                    Icons.speed,
                                    '${selectedWp.speed.toStringAsFixed(1)}m/s',
                                  ),
                                  const SizedBox(width: 12),
                                  _infoChip(
                                    Icons.camera_alt_outlined,
                                    selectedWp.capturePhoto
                                        ? 'Foto'
                                        : 'Sem foto',
                                    color: selectedWp.capturePhoto
                                        ? AppColors.green
                                        : AppColors.grayMedium,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedIndex = null),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.grayMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label, {
    Color color = AppColors.navy,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppText.small.copyWith(color: color, fontSize: 12)),
      ],
    );
  }
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────

class _DroneImageViewerPage extends StatefulWidget {
  final List<DroneImageModel> images;
  final int initialIndex;

  const _DroneImageViewerPage({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_DroneImageViewerPage> createState() => _DroneImageViewerPageState();
}

class _DroneImageViewerPageState extends State<_DroneImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      await Gal.putImage(widget.images[_currentIndex].localPath);
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Foto salva na galeria.'),
        );
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Erro ao salvar na galeria.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined, color: Colors.white),
                  tooltip: 'Baixar foto',
                  onPressed: _downloadCurrent,
                ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) {
          final img = widget.images[i];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(img.localPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
