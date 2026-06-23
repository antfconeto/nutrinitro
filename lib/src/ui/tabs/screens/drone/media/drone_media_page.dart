import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_view_model.dart';

class DroneMediaPage extends ConsumerStatefulWidget {
  const DroneMediaPage({super.key});

  @override
  ConsumerState<DroneMediaPage> createState() => _DroneMediaPageState();
}

class _DroneMediaPageState extends ConsumerState<DroneMediaPage> {
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
      builder: (_) => const _MediaFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(droneMediaViewModelProvider);
    final entries = state.entries;

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Busca + filtro ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => ref
                          .read(droneMediaViewModelProvider.notifier)
                          .updateSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Buscar por missão ou data...',
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
                                      .read(droneMediaViewModelProvider.notifier)
                                      .clearSearch();
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
                child: Row(
                  children: [
                    if (state.linkedFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ActiveChip(
                          label: state.linkedFilter!
                              ? 'Vinculadas'
                              : 'Não vinculadas',
                          onRemove: () => ref
                              .read(droneMediaViewModelProvider.notifier)
                              .setLinkedFilter(null),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(droneMediaViewModelProvider.notifier)
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

            const SizedBox(height: 8),

            // ── Grid ──────────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: () =>
                    ref.read(droneMediaViewModelProvider.notifier).fetch(),
                child: _buildBody(state, entries),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DroneMediaState state, List<DroneImageEntry> entries) {
    if (state.isLoading && state.allEntries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (state.allEntries.isEmpty) {
      return _buildEmptyState(hasSearch: false);
    }

    if (entries.isEmpty) {
      return _buildEmptyState(hasSearch: true);
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildTile(entries[index]),
    );
  }

  Widget _buildTile(DroneImageEntry entry) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(entry.image.localPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.white,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.grayMedium,
                size: 32,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              color: Colors.black.withValues(alpha: 0.55),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.missionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(entry.image.datetime),
                    style: const TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
          if (entry.image.isLinked)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 10),
              ),
            ),
        ],
      ),
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
                    : Icons.photo_library_outlined,
                size: 72,
                color: AppColors.grayMedium.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch ? 'Nenhum resultado' : 'Nenhuma imagem ainda',
                style: AppText.large.copyWith(color: AppColors.grayMedium),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'Tente ajustar os filtros ou a busca.'
                    : 'Imagens capturadas pelo drone aparecerão aqui.',
                style: AppText.body.copyWith(color: AppColors.grayMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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

class _MediaFilterSheet extends ConsumerWidget {
  const _MediaFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(droneMediaViewModelProvider);
    final vm = ref.read(droneMediaViewModelProvider.notifier);

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
                  'Filtrar mídia',
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
            'Vínculo com análise',
            style: AppText.body.copyWith(
              color: AppColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Todas',
                selected: state.linkedFilter == null,
                onTap: () => vm.setLinkedFilter(null),
              ),
              _FilterChip(
                label: 'Vinculadas',
                selected: state.linkedFilter == true,
                onTap: () => vm.setLinkedFilter(true),
              ),
              _FilterChip(
                label: 'Não vinculadas',
                selected: state.linkedFilter == false,
                onTap: () => vm.setLinkedFilter(false),
              ),
            ],
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withValues(alpha: 0.12)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFFDDE4DD),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.green : AppColors.grayMedium,
          ),
        ),
      ),
    );
  }
}
