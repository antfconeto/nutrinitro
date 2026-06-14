import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_flight_hud_page.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_view_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_state.dart';

class DronePage extends ConsumerStatefulWidget {
  const DronePage({super.key});

  @override
  ConsumerState<DronePage> createState() => _DronePageState();
}

class _DronePageState extends ConsumerState<DronePage> {
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(droneViewModelProvider);
    final viewModel = ref.read(droneViewModelProvider.notifier);

    final isConnecting =
        state.connectionState == DroneConnectionState.connecting;

    ref.listen<DroneState>(droneViewModelProvider, (previous, next) {
      if (!_navigating &&
          next.connectionState == DroneConnectionState.connected &&
          (previous?.connectionState != DroneConnectionState.connected)) {
        _navigating = true;
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => const DroneFlightHudPage(),
            fullscreenDialog: true,
          ),
        )
            .then((_) {
          _navigating = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Painel do Drone'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.tomato.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.tomato.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.tomato, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style:
                            AppText.small.copyWith(color: AppColors.tomato),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnecting
                          ? AppColors.orange.withValues(alpha: 0.12)
                          : AppColors.green.withValues(alpha: 0.10),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: AppColors.orange,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            Icons.flight_takeoff_rounded,
                            size: 72,
                            color: AppColors.green.withValues(alpha: 0.85),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isConnecting ? 'Conectando...' : 'Pronto para Decolar',
                    style: AppText.large.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isConnecting
                        ? 'Estabelecendo comunicação com o drone. Aguarde...'
                        : 'Conecte ao drone real via DJI SDK ou ative o simulador para testar o sistema de missão.',
                    style: AppText.body.copyWith(color: AppColors.grayMedium),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.computer,
                              color: state.isSimulatorMode
                                  ? AppColors.orange
                                  : AppColors.grayMedium,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modo Simulação',
                                  style: AppText.medium.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Teste sem hardware real',
                                  style: AppText.small.copyWith(
                                    color: AppColors.grayMedium,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: state.isSimulatorMode,
                          onChanged:
                              isConnecting ? null : viewModel.toggleSimulatorMode,
                          activeTrackColor:
                              AppColors.orange.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isConnecting ? null : viewModel.connectDrone,
                      icon: Icon(
                        isConnecting ? Icons.hourglass_empty : Icons.link,
                      ),
                      label: Text(
                          isConnecting ? 'Aguarde...' : 'Conectar Drone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.green.withValues(alpha: 0.5),
                        disabledForegroundColor:
                            AppColors.white.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              icon: Icons.map_outlined,
              title: 'Missão por Waypoints',
              description:
                  'Trace rotas inteligentes sobre a lavoura para coleta automatizada de dados.',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.camera_alt_outlined,
              title: 'FPV e Câmera em Tempo Real',
              description:
                  'Visualize o feed ao vivo e controle o gimbal com precisão.',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.bar_chart_outlined,
              title: 'Telemetria Completa',
              description:
                  'Altitude, velocidade, bateria, GPS e status da conexão disponíveis durante o voo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.medium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.small.copyWith(
                    color: AppColors.grayMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
