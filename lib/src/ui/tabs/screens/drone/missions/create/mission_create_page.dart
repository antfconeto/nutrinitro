import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/create/mission_create_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MissionCreatePage extends ConsumerStatefulWidget {
  const MissionCreatePage({super.key});

  @override
  ConsumerState<MissionCreatePage> createState() => _MissionCreatePageState();
}

class _MissionCreatePageState extends ConsumerState<MissionCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
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
              builder: (context, setSheetState) => Row(
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
                    value: wp.capturePhoto,
                    activeColor: AppColors.green,
                    onChanged: (v) {
                      setSheetState(() {});
                      ref
                          .read(missionCreateViewModelProvider.notifier)
                          .updateWaypoint(index, wp.copyWith(capturePhoto: v));
                    },
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
                            wp.copyWith(altitude: alt, speed: speed),
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
        title: const Text('Nova Missão'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (state.isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () =>
                  ref.read(missionCreateViewModelProvider.notifier).submit(),
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
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
              'Toque no mapa para adicionar waypoints',
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
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-7.219120, -44.367890),
                    initialZoom: 15,
                    onTap: (_, point) => ref
                        .read(missionCreateViewModelProvider.notifier)
                        .addWaypoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'nutrinitro.com.nutrinitro',
                    ),

                    // Linha conectando waypoints
                    if (points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            strokeWidth: 2.5,
                            color: AppColors.green.withOpacity(0.8),
                          ),
                        ],
                      ),

                    // Marcadores dos waypoints
                    MarkerLayer(
                      markers: waypoints.asMap().entries.map((e) {
                        final index = e.key;
                        final wp = e.value;
                        return Marker(
                          point: LatLng(wp.latitude, wp.longitude),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () => _showWaypointSheet(context, index, wp),
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
                                    color: AppColors.navy.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
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

            const SizedBox(height: 40),
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
