import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_telemetry.dart';

class DroneTelemetryHud extends StatelessWidget {
  final DroneTelemetry telemetry;
  final DroneConnectionState connectionState;
  final ConnectionHealth connectionHealth;
  final bool isSimulatorMode;
  final ValueChanged<bool> onSimulationModeChanged;

  const DroneTelemetryHud({
    super.key,
    required this.telemetry,
    required this.connectionState,
    required this.connectionHealth,
    required this.isSimulatorMode,
    required this.onSimulationModeChanged,
  });

  Color _getBatteryColor(int battery) {
    if (battery >= 50) return AppColors.green;
    if (battery >= 20) return AppColors.orange;
    return AppColors.tomato;
  }

  IconData _getConnectionHealthIcon(ConnectionHealth health) {
    switch (health) {
      case ConnectionHealth.excellent:
      case ConnectionHealth.good:
        return Icons.signal_cellular_4_bar;
      case ConnectionHealth.poor:
        return Icons.signal_cellular_connected_no_internet_4_bar;
      case ConnectionHealth.none:
        return Icons.signal_cellular_null;
    }
  }

  Color _getConnectionHealthColor(ConnectionHealth health) {
    switch (health) {
      case ConnectionHealth.excellent:
        return AppColors.green;
      case ConnectionHealth.good:
        return AppColors.greenLight;
      case ConnectionHealth.poor:
        return AppColors.orange;
      case ConnectionHealth.none:
        return AppColors.grayMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionState == DroneConnectionState.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Connection and Simulation Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getConnectionHealthIcon(connectionHealth),
                    color: _getConnectionHealthColor(connectionHealth),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Drone Conectado' : 'Sem Conexão',
                    style: AppText.medium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Simulador',
                    style: AppText.small.copyWith(color: AppColors.greenLight),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: isSimulatorMode,
                    onChanged: onSimulationModeChanged,
                    activeColor: AppColors.green,
                    activeTrackColor: AppColors.greenLight.withOpacity(0.5),
                    inactiveThumbColor: AppColors.grayLight,
                    inactiveTrackColor: AppColors.grayMedium,
                  ),
                ],
              ),
            ],
          ),
          if (isConnected) ...[
            const Divider(color: AppColors.grayMedium, height: 16),
            // Row 2: Live Stats HUD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatTile(
                  icon: Icons.battery_charging_full,
                  value: '${telemetry.batteryPercentage}%',
                  label: 'Bateria',
                  color: _getBatteryColor(telemetry.batteryPercentage),
                ),
                _buildStatTile(
                  icon: Icons.height,
                  value: '${telemetry.altitude.toStringAsFixed(1)}m',
                  label: 'Altitude',
                  color: AppColors.white,
                ),
                _buildStatTile(
                  icon: Icons.speed,
                  value: '${telemetry.speedHorizontal.toStringAsFixed(1)} m/s',
                  label: 'Velocidade',
                  color: AppColors.white,
                ),
                _buildStatTile(
                  icon: Icons.satellite_alt,
                  value: '${telemetry.satelliteCount}',
                  label: 'Satélites',
                  color: AppColors.white,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.medium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.small.copyWith(
            color: AppColors.grayLight.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
