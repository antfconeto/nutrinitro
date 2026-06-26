import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/core/widgets/app_skeleton.dart';
import 'package:nutrinitro/src/data/services/active_tasks/active_tasks_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/dashboard/widgets/active_tasks_bottom_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia!';
    if (hour < 18) return 'Boa tarde!';
    return 'Boa noite!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeCount = ref.watch(
      activeTasksProvider.select((s) => s.totalCount),
    );

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: AppColors.green,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: AppText.small.copyWith(
                              color: AppColors.greenLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NutriNitro',
                            style: AppText.large.copyWith(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showActiveTasksSheet(context),
                      child: Badge(
                        label: Text('$badgeCount'),
                        isLabelVisible: badgeCount > 0,
                        backgroundColor: AppColors.orange,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Conteúdo ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Cards de resumo ──────────────────────────────────────────
                const _SectionTitle(label: 'Resumo'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _summaryCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _summaryCard()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _summaryCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _summaryCard()),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Gráfico ──────────────────────────────────────────────────
                const _SectionTitle(label: 'Análises por cultura'),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE4DD)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const AppSkeleton(
                          width: double.infinity,
                          height: 200,
                          borderRadius: 12,
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.bar_chart_outlined,
                          size: 48,
                          color: AppColors.grayMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Última análise ───────────────────────────────────────────
                const _SectionTitle(
                  label: 'Última análise',
                  action: 'Ver todas',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE4DD)),
                  ),
                  child: const Row(
                    children: [
                      AppSkeleton(
                        width: 72,
                        height: 72,
                        borderRadius: 10,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSkeletonLine(width: 140, height: 14),
                            SizedBox(height: 8),
                            AppSkeletonLine(width: 100, height: 11),
                            SizedBox(height: 8),
                            AppSkeletonLine(width: 80, height: 11),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      AppSkeleton(width: 64, height: 26, borderRadius: 20),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Missões recentes ─────────────────────────────────────────
                const _SectionTitle(label: 'Missões recentes'),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, __) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE4DD)),
                    ),
                    child: const Row(
                      children: [
                        AppSkeleton(
                          width: 40,
                          height: 40,
                          borderRadius: 10,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSkeletonLine(width: 120, height: 13),
                              SizedBox(height: 6),
                              AppSkeletonLine(width: 80, height: 11),
                            ],
                          ),
                        ),
                        AppSkeleton(width: 56, height: 24, borderRadius: 20),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4DD)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSkeletonLine(width: 80, height: 11),
          SizedBox(height: 10),
          AppSkeletonLine(width: 100, height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final String? action;

  const _SectionTitle({required this.label, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.medium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: AppText.small.copyWith(color: AppColors.green),
          ),
      ],
    );
  }
}
