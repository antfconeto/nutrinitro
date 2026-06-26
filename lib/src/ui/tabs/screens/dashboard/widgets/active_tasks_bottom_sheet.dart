import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';
import 'package:nutrinitro/src/data/services/active_tasks/active_tasks_provider.dart';

void showActiveTasksSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ActiveTasksSheet(),
  );
}

class _ActiveTasksSheet extends ConsumerWidget {
  const _ActiveTasksSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeTasksProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tarefas em andamento',
                style: AppText.medium.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (state.totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.totalCount}',
                    style: AppText.small.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.totalCount == 0) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.green,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma tarefa ativa',
                    style: AppText.medium.copyWith(color: AppColors.grayMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            if (state.executingMissions.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.flight,
                label: 'Missões',
                color: AppColors.navy,
              ),
              const SizedBox(height: 8),
              ...state.executingMissions.map(
                (m) => _MissionTile(mission: m),
              ),
              if (state.interruptedAnalyses.isNotEmpty) const SizedBox(height: 16),
            ],
            if (state.interruptedAnalyses.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.science_outlined,
                label: 'Análises',
                color: AppColors.green,
              ),
              const SizedBox(height: 8),
              ...state.interruptedAnalyses.map(
                (a) => _AnalysisTile(analysis: a),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.small.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MissionTile extends StatelessWidget {
  final MissionModel mission;

  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(
            '/drone/mission/details',
            arguments: mission.id,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grayLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE4DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flight, size: 18, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: AppText.medium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Em execução',
                      style: AppText.small.copyWith(color: AppColors.orange),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grayMedium,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final AnalysisModel analysis;

  const _AnalysisTile({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(
            '/analysis/details',
            arguments: analysis.id,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grayLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE4DD)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.title,
                      style: AppText.medium.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Interrompida',
                      style: AppText.small.copyWith(color: AppColors.orange),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grayMedium,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
