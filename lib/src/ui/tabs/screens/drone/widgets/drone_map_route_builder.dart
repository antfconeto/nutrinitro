import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';
import 'package:nutrinitro/src/data/models/drone/drone_waypoint.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/widgets/drone_map_tiles.dart';

class DroneMapRouteBuilder extends StatefulWidget {
  final List<DroneWaypoint> waypoints;
  final DroneTelemetry telemetry;
  final DroneConnectionState connectionState;
  final bool isExecutingMission;
  final int activeWaypointIndex;
  final ValueChanged<LatLng> onMapTap;
  final ValueChanged<int> onRemoveWaypoint;
  final VoidCallback onOptimizeRoute;
  final VoidCallback onClearRoute;
  final VoidCallback onStartMission;
  final VoidCallback onAbortMission;

  final bool isMiniMode;
  final bool hideHeader;
  final bool isSatelliteMode;
  final ValueChanged<bool>? onSatelliteModeChanged;
  final MapController? mapController;

  const DroneMapRouteBuilder({
    super.key,
    required this.waypoints,
    required this.telemetry,
    required this.connectionState,
    required this.isExecutingMission,
    required this.activeWaypointIndex,
    required this.onMapTap,
    required this.onRemoveWaypoint,
    required this.onOptimizeRoute,
    required this.onClearRoute,
    required this.onStartMission,
    required this.onAbortMission,
    this.isMiniMode = false,
    this.hideHeader = false,
    this.isSatelliteMode = false,
    this.onSatelliteModeChanged,
    this.mapController,
  });

  @override
  State<DroneMapRouteBuilder> createState() => _DroneMapRouteBuilderState();
}

class _DroneMapRouteBuilderState extends State<DroneMapRouteBuilder> {
  late final MapController _ownController;
  late bool _isSatelliteMode;

  MapController get _controller => widget.mapController ?? _ownController;

  @override
  void initState() {
    super.initState();
    _ownController = MapController();
    _isSatelliteMode = widget.isSatelliteMode;
  }

  @override
  void didUpdateWidget(covariant DroneMapRouteBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSatelliteMode != widget.isSatelliteMode) {
      _isSatelliteMode = widget.isSatelliteMode;
    }
  }

  void _toggleSatelliteMode() {
    setState(() => _isSatelliteMode = !_isSatelliteMode);
    widget.onSatelliteModeChanged?.call(_isSatelliteMode);
  }

  void _recenterMap(LatLng center) {
    _controller.move(center, 17.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasWaypoints = widget.waypoints.isNotEmpty;
    final isConnected =
        widget.connectionState == DroneConnectionState.connected;

    final initialCenter = isConnected && widget.telemetry.latitude != 0.0
        ? LatLng(widget.telemetry.latitude, widget.telemetry.longitude)
        : const LatLng(-21.1775, -47.8103);

    final waypointMarkers = widget.waypoints.map((wp) {
      final isCurrentActive = widget.activeWaypointIndex == (wp.id - 1);
      return Marker(
        point: wp.coordinate,
        width: widget.isMiniMode ? 20 : 32,
        height: widget.isMiniMode ? 20 : 32,
        child: GestureDetector(
          onTap: () => widget.onRemoveWaypoint(wp.id),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentActive ? AppColors.orange : AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${wp.id}',
              style: TextStyle(
                fontSize: widget.isMiniMode ? 9 : 11,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();

    Marker? droneMarker;
    if (isConnected && widget.telemetry.latitude != 0.0) {
      final radians = widget.telemetry.yaw * math.pi / 180;
      droneMarker = Marker(
        point: LatLng(widget.telemetry.latitude, widget.telemetry.longitude),
        width: widget.isMiniMode ? 28 : 40,
        height: widget.isMiniMode ? 28 : 40,
        child: Transform.rotate(
          angle: radians,
          child: Icon(
            Icons.navigation_rounded,
            color: AppColors.greenLight,
            size: widget.isMiniMode ? 20 : 28,
          ),
        ),
      );
    }

    final flightPathPoints =
        widget.waypoints.map((wp) => wp.coordinate).toList();

    final mapWidget = Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF1C1C1E),
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 17.0,
                maxZoom: 22.0,
                minZoom: 3.0,
                interactionOptions: InteractionOptions(
                  flags: widget.isMiniMode
                      ? InteractiveFlag.none
                      : InteractiveFlag.all,
                ),
                onTap: (_, latLng) {
                  if (!widget.isExecutingMission && !widget.isMiniMode) {
                    widget.onMapTap(latLng);
                  }
                },
              ),
              children: [
                DroneMapTiles.layer(isSatellite: _isSatelliteMode),
                if (flightPathPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: flightPathPoints,
                        strokeWidth: widget.isMiniMode ? 2 : 3,
                        color: AppColors.greenLight,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ...waypointMarkers,
                    if (droneMarker != null) droneMarker,
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!widget.isMiniMode) ...[
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.hideHeader &&
                    hasWaypoints &&
                    !widget.isExecutingMission) ...[
                  _MapControlButton(
                    icon: Icons.sort_rounded,
                    tooltip: 'Otimizar rota',
                    onPressed: widget.onOptimizeRoute,
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Limpar rota',
                    onPressed: widget.onClearRoute,
                    accent: AppColors.tomato,
                  ),
                  const SizedBox(height: 8),
                ],
                _MapControlButton(
                  icon: _isSatelliteMode
                      ? Icons.map_outlined
                      : Icons.satellite_alt_outlined,
                  tooltip:
                      _isSatelliteMode ? 'Mapa padrão' : 'Satélite',
                  onPressed: _toggleSatelliteMode,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: isConnected ? Icons.gps_fixed : Icons.my_location,
                  tooltip: 'Centralizar',
                  onPressed: () => _recenterMap(initialCenter),
                ),
              ],
            ),
          ),
          if (hasWaypoints && isConnected)
            Positioned(
              bottom: 16,
              left: widget.hideHeader ? 188 : 16,
              child: _MissionBar(
                isExecuting: widget.isExecutingMission,
                onStart: widget.onStartMission,
                onAbort: widget.onAbortMission,
              ),
            ),
        ],
      ],
    );

    if (widget.isMiniMode || widget.hideHeader) {
      return mapWidget;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.route_outlined, color: AppColors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Plano de coleta · ${widget.waypoints.length} pts',
                  style: AppText.medium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: mapWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? accent;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: accent ?? AppColors.white.withValues(alpha: 0.9),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _MissionBar extends StatelessWidget {
  final bool isExecuting;
  final VoidCallback onStart;
  final VoidCallback onAbort;

  const _MissionBar({
    required this.isExecuting,
    required this.onStart,
    required this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExecuting) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Em execução',
              style: AppText.small.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 10),
            _MissionActionButton(
              label: 'Abortar',
              color: AppColors.tomato,
              onPressed: onAbort,
            ),
          ] else ...[
            Text(
              'Rota pronta',
              style: AppText.small.copyWith(
                color: AppColors.greenLight,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 10),
            _MissionActionButton(
              label: 'Iniciar',
              color: AppColors.green,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MissionActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: AppText.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
