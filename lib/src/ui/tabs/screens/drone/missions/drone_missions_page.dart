import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/drone_missions_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/missions/drone_missions_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class DroneMissionsPage extends ConsumerWidget {
  const DroneMissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(droneMissionsViewModelProvider);

    ref.listen<DroneMissionsState>(droneMissionsViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(droneMissionsViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () =>
            ref.read(droneMissionsViewModelProvider.notifier).fetchMissions(),
        child: _buildBody(context, ref, state),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'drone_missions_fab',
        onPressed: () async {
          await Navigator.of(context).pushNamed('/drone/mission/create');
          ref.read(droneMissionsViewModelProvider.notifier).fetchMissions();
        },
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 3,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DroneMissionsState state,
  ) {
    if (state.isLoading && state.missions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (state.missions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 72,
                  color: AppColors.grayMedium.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma missão ainda',
                  style: AppText.large.copyWith(color: AppColors.grayMedium),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque no + para criar sua primeira missão.',
                  style: AppText.body.copyWith(color: AppColors.grayMedium),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: state.missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildCard(context, ref, state.missions[index]),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, MissionModel mission) {
    return Dismissible(
      key: ValueKey(mission.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(context, ref, mission);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.tomato,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 28,
        ),
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).pushNamed(
              '/drone/mission/details',
              arguments: mission.id,
            );
            ref.read(droneMissionsViewModelProvider.notifier).fetchMissions();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.green.withOpacity(0.06),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
                // Ícone de missão
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor(mission.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    color: _statusColor(mission.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: AppText.medium.copyWith(
                          fontSize: 15,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mission.waypoints.length} waypoint${mission.waypoints.length != 1 ? 's' : ''}',
                            style: AppText.small.copyWith(
                              color: AppColors.grayMedium,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(mission.createdAt),
                            style: AppText.small.copyWith(
                              color: AppColors.grayMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                _buildStatusBadge(mission.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MissionStatus status) {
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MissionModel mission,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                Icons.delete_outline,
                color: AppColors.tomato,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Excluir missão?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'A missão "${mission.title}" e todas as suas imagens serão excluídas permanentemente.',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Excluir',
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
        .read(droneMissionsViewModelProvider.notifier)
        .delete(mission.id!);

    if (!context.mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      success
          ? const CustomSnackBar.success(
              message: 'Missão excluída com sucesso.',
            )
          : const CustomSnackBar.error(message: 'Erro ao excluir missão.'),
    );
  }
}
