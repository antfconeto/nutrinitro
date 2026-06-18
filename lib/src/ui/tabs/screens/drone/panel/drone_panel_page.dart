import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/const/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/core/const/drone/gps_signal_level.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/telemetry_data.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/panel/drone_panel_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/panel/drone_panel_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class DronePanelPage extends ConsumerWidget {
  const DronePanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dronePanelViewModelProvider);

    ref.listen<DronePanelState>(dronePanelViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(dronePanelViewModelProvider.notifier).clearError();
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Conexão ────────────────────────────────────────────────────────
          _ConnectionCard(state: state),

          const SizedBox(height: 16),

          // ── Telemetria ─────────────────────────────────────────────────────
          if (state.isConnected && state.hasTelemetry) ...[
            _TelemetrySection(telemetry: state.telemetry!),
            const SizedBox(height: 16),

            // ── Controles de voo ──────────────────────────────────────────
            _FlightControlsCard(state: state),
          ],

          if (!state.isConnected) _DisconnectedHint(),
        ],
      ),
    );
  }
}

// ─── Connection card ──────────────────────────────────────────────────────────

class _ConnectionCard extends ConsumerWidget {
  final DronePanelState state;

  const _ConnectionCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(dronePanelViewModelProvider.notifier);

    final (color, icon, label) = switch (state.connectionState) {
      DroneConnectionState.connected => (
        AppColors.green,
        Icons.wifi,
        'Conectado',
      ),
      DroneConnectionState.connecting => (
        AppColors.orangeLight,
        Icons.wifi_find_outlined,
        'Conectando...',
      ),
      DroneConnectionState.disconnected => (
        AppColors.grayMedium,
        Icons.wifi_off_outlined,
        'Desconectado',
      ),
      DroneConnectionState.error => (
        AppColors.tomato,
        Icons.error_outline,
        'Erro',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4DD)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status do drone',
                  style: AppText.small.copyWith(color: AppColors.grayMedium),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppText.medium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (state.isConnecting)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orangeLight,
              ),
            )
          else
            ElevatedButton(
              onPressed: state.isConnected ? vm.disconnect : vm.connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isConnected
                    ? AppColors.tomato
                    : AppColors.green,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                state.isConnected ? 'Desconectar' : 'Conectar',
                style: AppText.small.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Telemetry section ────────────────────────────────────────────────────────

class _TelemetrySection extends StatelessWidget {
  final TelemetryData telemetry;

  const _TelemetrySection({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Telemetria',
          style: AppText.medium.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // ── Bateria ──────────────────────────────────────────────────────────
        _BatteryCard(telemetry: telemetry),
        const SizedBox(height: 12),

        // ── GPS ──────────────────────────────────────────────────────────────
        _GpsCard(telemetry: telemetry),
        const SizedBox(height: 12),

        // ── Altitude + Velocidade ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Altitude',
                value: '${telemetry.altitude.toStringAsFixed(1)} m',
                icon: Icons.height,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Velocidade',
                value: '${telemetry.speed.toStringAsFixed(1)} m/s',
                icon: Icons.speed_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Orientação ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Heading',
                value: '${telemetry.heading.toStringAsFixed(0)}°',
                icon: Icons.explore_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Pitch',
                value: '${telemetry.pitch.toStringAsFixed(1)}°',
                icon: Icons.rotate_right_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Roll',
                value: '${telemetry.roll.toStringAsFixed(1)}°',
                icon: Icons.rotate_left_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final TelemetryData telemetry;

  const _BatteryCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final percent = telemetry.batteryPercent;
    final color = percent <= 10
        ? AppColors.tomato
        : percent <= 20
        ? AppColors.orange
        : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_charging_full_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                'Bateria',
                style: AppText.small.copyWith(color: AppColors.grayMedium),
              ),
              const Spacer(),
              Text(
                '$percent%  •  ${telemetry.batteryVoltage.toStringAsFixed(1)}V',
                style: AppText.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.grayLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          if (telemetry.isCriticalBattery) ...[
            const SizedBox(height: 6),
            Text(
              'Bateria crítica! Pouse imediatamente.',
              style: AppText.small.copyWith(color: AppColors.tomato),
            ),
          ] else if (telemetry.isLowBattery) ...[
            const SizedBox(height: 6),
            Text(
              'Bateria baixa. Considere pousar em breve.',
              style: AppText.small.copyWith(color: AppColors.orange),
            ),
          ],
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  final TelemetryData telemetry;

  const _GpsCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final color = switch (telemetry.gpsSignal) {
      GpsSignalLevel.excellent => AppColors.green,
      GpsSignalLevel.good => AppColors.greenMedium,
      GpsSignalLevel.fair => AppColors.orangeLight,
      GpsSignalLevel.poor => AppColors.orange,
      GpsSignalLevel.none => AppColors.tomato,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'GPS',
            style: AppText.small.copyWith(color: AppColors.grayMedium),
          ),
          const Spacer(),
          Text(
            '${telemetry.gpsSatellites} satélites  •  ${telemetry.gpsSignal.label}',
            style: AppText.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.grayMedium),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppText.small.copyWith(
                  color: AppColors.grayMedium,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.medium.copyWith(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Flight controls ──────────────────────────────────────────────────────────

class _FlightControlsCard extends ConsumerWidget {
  final DronePanelState state;

  const _FlightControlsCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(dronePanelViewModelProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controles de voo',
            style: AppText.medium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FlightButton(
                  label: 'Decolar',
                  icon: Icons.flight_takeoff_outlined,
                  color: AppColors.green,
                  onTap: vm.takeoff,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlightButton(
                  label: 'Pousar',
                  icon: Icons.flight_land_outlined,
                  color: AppColors.navy,
                  onTap: vm.land,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FlightButton(
                  label: 'Retornar',
                  icon: Icons.home_outlined,
                  color: AppColors.orange,
                  onTap: vm.returnToHome,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlightButton(
                  label: 'Emergência',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.tomato,
                  onTap: () => _confirmEmergencyStop(context, vm.emergencyStop),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmergencyStop(
    BuildContext context,
    VoidCallback onConfirm,
  ) async {
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
                color: AppColors.tomato.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_outlined,
                color: AppColors.tomato,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Parada de emergência?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'O drone irá parar imediatamente. Isso pode causar queda.',
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
            ),
            child: Text(
              'Parar',
              style: AppText.medium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) onConfirm();
  }
}

class _FlightButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FlightButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Disconnected hint ────────────────────────────────────────────────────────

class _DisconnectedHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flight_outlined,
              size: 64,
              color: AppColors.grayMedium.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Drone desconectado',
              style: AppText.large.copyWith(color: AppColors.grayMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em Conectar para iniciar.',
              style: AppText.body.copyWith(color: AppColors.grayMedium),
            ),
          ],
        ),
      ),
    );
  }
}
