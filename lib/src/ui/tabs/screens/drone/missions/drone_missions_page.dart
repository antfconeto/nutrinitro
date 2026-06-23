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

class DroneMissionsPage extends ConsumerStatefulWidget {
  const DroneMissionsPage({super.key});

  @override
  ConsumerState<DroneMissionsPage> createState() => _DroneMissionsPageState();
}

class _DroneMissionsPageState extends ConsumerState<DroneMissionsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _MissionFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Column(
          children: [
            // ── Busca ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => ref
                          .read(droneMissionsViewModelProvider.notifier)
                          .updateSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Buscar por título...',
                        hintStyle: AppText.hint,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.grayMedium,
                          size: 20,
                        ),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  ref
                                      .read(droneMissionsViewModelProvider
                                          .notifier)
                                      .updateSearch('');
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.grayMedium,
                                  size: 18,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFDDE4DD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _showFilterSheet,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: state.hasActiveFilters
                                    ? AppColors.green
                                    : const Color(0xFFDDE4DD),
                                width: state.hasActiveFilters ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_outlined,
                              color: state.hasActiveFilters
                                  ? AppColors.green
                                  : AppColors.grayMedium,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (state.activeFilterCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${state.activeFilterCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Chips ativos ──────────────────────────────────────────────────
            if (state.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...state.statusFilter.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveChip(
                            label: s.label,
                            onRemove: () => ref
                                .read(droneMissionsViewModelProvider.notifier)
                                .toggleStatusFilter(s),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref
                              .read(droneMissionsViewModelProvider.notifier)
                              .clearFilters();
                        },
                        child: Text(
                          'Limpar',
                          style:
                              AppText.small.copyWith(color: AppColors.tomato),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Lista ─────────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: () => ref
                    .read(droneMissionsViewModelProvider.notifier)
                    .fetchMissions(),
                child: _buildBody(context, state),
              ),
            ),
          ],
        ),
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

  Widget _buildBody(BuildContext context, DroneMissionsState state) {
    if (state.isLoading && state.allMissions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final missions = state.missions;

    if (state.allMissions.isEmpty) {
      return _buildEmptyState(hasSearch: false);
    }

    if (missions.isEmpty) {
      return _buildEmptyState(hasSearch: true);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(context, missions[index]),
    );
  }

  Widget _buildEmptyState({required bool hasSearch}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSearch
                    ? Icons.search_off_outlined
                    : Icons.route_outlined,
                size: 72,
                color: AppColors.grayMedium.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch ? 'Nenhum resultado' : 'Nenhuma missão ainda',
                style: AppText.large.copyWith(color: AppColors.grayMedium),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'Tente ajustar os filtros ou a busca.'
                    : 'Toque no + para criar sua primeira missão.',
                style: AppText.body.copyWith(color: AppColors.grayMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, MissionModel mission) {
    return Dismissible(
      key: ValueKey(mission.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(context, mission);
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
          splashColor: AppColors.green.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor(mission.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    color: _statusColor(mission.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
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
                          const Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mission.waypoints.length} waypoint${mission.waypoints.length != 1 ? 's' : ''}',
                            style: AppText.small
                                .copyWith(color: AppColors.grayMedium),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(mission.createdAt),
                            style: AppText.small
                                .copyWith(color: AppColors.grayMedium),
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

  Color _statusColor(MissionStatus status) {
    return switch (status) {
      MissionStatus.planned => AppColors.orangeLight,
      MissionStatus.executing => AppColors.green,
      MissionStatus.completed => AppColors.greenDark,
      MissionStatus.aborted => AppColors.tomato,
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
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
                color: AppColors.tomato.withValues(alpha: 0.1),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// ─── Active chip ──────────────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.small.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _MissionFilterSheet extends ConsumerWidget {
  const _MissionFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(droneMissionsViewModelProvider);
    final vm = ref.read(droneMissionsViewModelProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filtrar missões',
                  style: AppText.large.copyWith(color: AppColors.navy),
                ),
              ),
              if (state.hasActiveFilters)
                GestureDetector(
                  onTap: () => vm.clearFilters(),
                  child: Text(
                    'Limpar tudo',
                    style: AppText.small.copyWith(color: AppColors.tomato),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Status',
            style: AppText.body.copyWith(
              color: AppColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MissionStatus.values
                .map(
                  (s) => _FilterChip(
                    label: s.label,
                    selected: state.statusFilter.contains(s),
                    color: _statusColor(s),
                    onTap: () => vm.toggleStatusFilter(s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(MissionStatus status) {
    return switch (status) {
      MissionStatus.planned => AppColors.orangeLight,
      MissionStatus.executing => AppColors.green,
      MissionStatus.completed => AppColors.greenDark,
      MissionStatus.aborted => AppColors.tomato,
    };
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.green;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFDDE4DD),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? activeColor : AppColors.grayMedium,
          ),
        ),
      ),
    );
  }
}
