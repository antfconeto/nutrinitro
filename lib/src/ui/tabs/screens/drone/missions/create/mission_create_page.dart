import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MissionCreatePage extends ConsumerStatefulWidget {
  final MissionModel? initialMission;

  const MissionCreatePage({super.key, this.initialMission});

  @override
  ConsumerState<MissionCreatePage> createState() => _MissionCreatePageState();
}

class _MissionCreatePageState extends ConsumerState<MissionCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final MapController _mapController = MapController();

  final GlobalKey _mapContainerKey = GlobalKey();

  LatLng? _userLatLng;
  bool _locationIsApprox = false;
  bool _isSatellite = false;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    final mission = widget.initialMission;
    _titleController = TextEditingController(text: mission?.title ?? '');
    _notesController = TextEditingController(text: mission?.notes ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mission != null) {
        ref
            .read(missionCreateViewModelProvider.notifier)
            .initFromMission(mission);
        _fitToWaypoints(mission.waypoints);
      } else {
        _moveToUserLocation();
      }
    });
  }

  void _fitToWaypoints(List<DroneWaypointModel> waypoints) {
    if (waypoints.isEmpty) {
      _moveToUserLocation();
      return;
    }
    final points =
        waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 15);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  Future<void> _moveToUserLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      bool hasLastKnown = false;

      // Instant feedback with cached position
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          final latLng = LatLng(last.latitude, last.longitude);
          setState(() {
            _userLatLng = latLng;
            _locationIsApprox = false;
          });
          _mapController.move(latLng, 15);
          hasLastKnown = true;
        }
      } catch (_) {}

      // Fresh fix in background — updates dot, skips map move if already positioned
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        if (!mounted) return;
        final latLng = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLatLng = latLng;
          _locationIsApprox = false;
        });
        if (!hasLastKnown) _mapController.move(latLng, 15);
        return;
      } catch (_) {}

      if (hasLastKnown) return;
    }

    if (mounted && _userLatLng == null) await _moveToIpLocation();
  }

  Future<void> _moveToIpLocation() async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse('https://ipapi.co/json/'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      if (!mounted || lat == null || lon == null) return;
      final latLng = LatLng(lat, lon);
      setState(() {
        _userLatLng = latLng;
        _locationIsApprox = true;
      });
      _mapController.move(latLng, 12);
    } catch (_) {
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showWaypointSheet(
    BuildContext context,
    int index,
    DroneWaypointModel wp,
  ) {
    final altCtrl = TextEditingController(text: wp.altitude.toStringAsFixed(0));
    final speedCtrl = TextEditingController(text: wp.speed.toStringAsFixed(1));
    bool capturePhoto = wp.capturePhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Waypoint ${index + 1}',
              style: AppText.large.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              '${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)}',
              style: AppText.small.copyWith(color: AppColors.grayMedium),
            ),
            const SizedBox(height: 20),

            // Altitude
            Text(
              'Altitude (m)',
              style: AppText.body.copyWith(
                color: AppColors.grayMedium,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: altCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(hint: 'Ex: 50'),
            ),

            const SizedBox(height: 16),

            // Velocidade
            Text(
              'Velocidade (m/s)',
              style: AppText.body.copyWith(
                color: AppColors.grayMedium,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: speedCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(hint: 'Ex: 5.0'),
            ),

            const SizedBox(height: 16),

            // Capturar foto
            StatefulBuilder(
              builder: (_, setSheetState) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capturar foto',
                          style: AppText.medium.copyWith(color: AppColors.navy),
                        ),
                        Text(
                          'Fotografar ao chegar neste ponto',
                          style: AppText.small.copyWith(
                            color: AppColors.grayMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: capturePhoto,
                    activeThumbColor: AppColors.green,
                    activeTrackColor: AppColors.green.withValues(alpha: 0.4),
                    onChanged: (v) => setSheetState(() => capturePhoto = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // Remover
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(missionCreateViewModelProvider.notifier)
                          .removeWaypoint(index);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tomato,
                      side: const BorderSide(color: AppColors.tomato),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remover'),
                  ),
                ),
                const SizedBox(width: 12),
                // Salvar
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final alt = double.tryParse(altCtrl.text) ?? wp.altitude;
                      final speed = double.tryParse(speedCtrl.text) ?? wp.speed;
                      ref
                          .read(missionCreateViewModelProvider.notifier)
                          .updateWaypoint(
                            index,
                            wp.copyWith(
                              altitude: alt,
                              speed: speed,
                              capturePhoto: capturePhoto,
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionCreateViewModelProvider);

    ref.listen<MissionCreateState>(missionCreateViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(missionCreateViewModelProvider.notifier).clearError();
      }
      if (next.successMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Missão criada com sucesso!'),
        );
        ref.read(missionCreateViewModelProvider.notifier).clearSuccess();
        Navigator.of(context).pop();
      }
    });

    final waypoints = state.waypoints;
    final points = waypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: Text(
          widget.initialMission != null ? 'Editar Missão' : 'Nova Missão',
        ),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ──────────────────────────────────────────────────────
            _sectionLabel('Título', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              onChanged: (v) => ref
                  .read(missionCreateViewModelProvider.notifier)
                  .updateTitle(v),
              decoration: InputDecoration(
                hintText: 'Ex: Talhão norte - voo 1',
                hintStyle: AppText.hint,
                errorText: state.titleError
                    ? 'Informe um título para a missão'
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: state.titleError
                        ? AppColors.tomato
                        : const Color(0xFFDDE4DD),
                    width: state.titleError ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: state.titleError
                        ? AppColors.tomato
                        : AppColors.green,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Observações ──────────────────────────────────────────────────
            _sectionLabel('Observações'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              onChanged: (v) => ref
                  .read(missionCreateViewModelProvider.notifier)
                  .updateNotes(v.isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Observações opcionais...',
                hintStyle: AppText.hint,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.green,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Mapa ─────────────────────────────────────────────────────────
            Row(
              children: [
                _sectionLabel('Rota', required: true),
                const Spacer(),
                Text(
                  '${waypoints.length} ponto${waypoints.length != 1 ? 's' : ''}',
                  style: AppText.small.copyWith(color: AppColors.green),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pressione e segure no mapa para adicionar waypoints',
              style: AppText.small.copyWith(color: AppColors.grayMedium),
            ),
            const SizedBox(height: 8),

            if (state.waypointsError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Adicione pelo menos 2 waypoints para criar uma missão.',
                  style: AppText.small.copyWith(color: AppColors.tomato),
                ),
              ),

            Container(
              key: _mapContainerKey,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: state.waypointsError
                      ? AppColors.tomato
                      : const Color(0xFFDDE4DD),
                  width: state.waypointsError ? 1.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(-7.219120, -44.367890),
                        initialZoom: 15,
                        interactionOptions: InteractionOptions(
                          flags: _draggingIndex != null
                              ? InteractiveFlag.none
                              : InteractiveFlag.drag |
                                  InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom,
                        ),
                        onLongPress: _draggingIndex == null
                            ? (_, point) => ref
                                .read(missionCreateViewModelProvider.notifier)
                                .addWaypoint(point)
                            : null,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _isSatellite
                              ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'nutrinitro.com.nutrinitro',
                        ),
                        if (points.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: points,
                                strokeWidth: 2.5,
                                color: AppColors.green.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        if (_userLatLng != null) ...[
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _userLatLng!,
                                radius: _locationIsApprox ? 3000 : 40,
                                useRadiusInMeter: _locationIsApprox,
                                color: const Color(0xFF1A73E8)
                                    .withValues(alpha: _locationIsApprox ? 0.08 : 0.15),
                                borderColor: const Color(0xFF1A73E8)
                                    .withValues(alpha: _locationIsApprox ? 0.25 : 0.4),
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _userLatLng!,
                                width: 20,
                                height: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _locationIsApprox
                                        ? AppColors.grayMedium
                                        : const Color(0xFF1A73E8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.25),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Midpoint insert dots
                        if (waypoints.length >= 2 &&
                            _draggingIndex == null)
                          MarkerLayer(
                            markers: List.generate(
                              waypoints.length - 1,
                              (i) {
                                final a = waypoints[i];
                                final b = waypoints[i + 1];
                                final mid = LatLng(
                                  (a.latitude + b.latitude) / 2,
                                  (a.longitude + b.longitude) / 2,
                                );
                                return Marker(
                                  point: mid,
                                  width: 22,
                                  height: 22,
                                  child: GestureDetector(
                                    onTap: () => ref
                                        .read(
                                          missionCreateViewModelProvider
                                              .notifier,
                                        )
                                        .insertWaypoint(i, mid),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.green,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 13,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Waypoint markers (drag-aware)
                        MarkerLayer(
                          markers: waypoints.asMap().entries.map((e) {
                            final index = e.key;
                            final wp = e.value;
                            final isDragging = _draggingIndex == index;
                            return Marker(
                              point: LatLng(wp.latitude, wp.longitude),
                              width: isDragging ? 42 : 32,
                              height: isDragging ? 42 : 32,
                              child: GestureDetector(
                                onTap: _draggingIndex == null
                                    ? () => _showWaypointSheet(
                                          context,
                                          index,
                                          wp,
                                        )
                                    : null,
                                onLongPressStart: (_) =>
                                    setState(() => _draggingIndex = index),
                                onLongPressMoveUpdate: (details) {
                                  if (_draggingIndex != index) return;
                                  final box = _mapContainerKey.currentContext
                                      ?.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  final local = box.globalToLocal(
                                    details.globalPosition,
                                  );
                                  final latLng = _mapController.camera
                                      .offsetToCrs(local);
                                  ref
                                      .read(
                                        missionCreateViewModelProvider.notifier,
                                      )
                                      .moveWaypoint(index, latLng);
                                },
                                onLongPressEnd: (_) =>
                                    setState(() => _draggingIndex = null),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDragging
                                        ? AppColors.greenDark
                                        : AppColors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: isDragging ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDragging
                                            ? AppColors.greenDark
                                                .withValues(alpha: 0.45)
                                            : AppColors.navy
                                                .withValues(alpha: 0.2),
                                        blurRadius: isDragging ? 10 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: isDragging ? 13 : 11,
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
                      top: 12,
                      right: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'mission_create_satellite',
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
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'mission_create_location',
                        onPressed: _moveToUserLocation,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.green,
                        elevation: 2,
                        child: const Icon(Icons.my_location, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Lista de waypoints ────────────────────────────────────────────
            if (waypoints.isNotEmpty) ...[
              _sectionLabel('Waypoints'),
              const SizedBox(height: 8),
              ...waypoints.asMap().entries.map((e) {
                final index = e.key;
                final wp = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _showWaypointSheet(context, index, wp),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
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
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.grayMedium,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // ── Botão Criar ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => ref
                          .read(missionCreateViewModelProvider.notifier)
                          .submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor:
                      AppColors.green.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.initialMission != null
                            ? 'Salvar alterações'
                            : 'Criar Missão',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: AppText.body.copyWith(
              fontSize: 13,
              color: AppColors.grayMedium,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: AppText.body.copyWith(
                fontSize: 13,
                color: AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
    );
  }
}
