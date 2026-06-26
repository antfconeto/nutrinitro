import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/core/widgets/download_progress_dialog.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/media/drone_media_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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

  Future<void> _downloadImages(
    BuildContext context,
    List<DroneImageEntry> images,
  ) => downloadWithProgress(
    context,
    paths: images.map((e) => e.image.localPath).toList(),
  );

  void _openViewer(
    List<DroneImageEntry> entries,
    int initialIndex,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MediaImageViewerPage(
          entries: entries,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(droneMediaViewModelProvider);
    final groups = state.missionGroups;

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Busca + filtro ──────────────────────────────────────────────
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

            // ── Chips ativos ──────────────────────────────────────────────
            if (state.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (state.missionFilterLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveChip(
                            label: state.missionFilterLabel!,
                            onRemove: () => ref
                                .read(droneMediaViewModelProvider.notifier)
                                .setMissionFilter(null),
                          ),
                        ),
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
                      if (state.dateFrom != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveChip(
                            label:
                                'De ${DateFormat('dd/MM/yy').format(state.dateFrom!)}',
                            onRemove: () => ref
                                .read(droneMediaViewModelProvider.notifier)
                                .setDateFrom(null),
                          ),
                        ),
                      if (state.dateTo != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveChip(
                            label:
                                'Até ${DateFormat('dd/MM/yy').format(state.dateTo!)}',
                            onRemove: () => ref
                                .read(droneMediaViewModelProvider.notifier)
                                .setDateTo(null),
                          ),
                        ),
                      if (state.sortOrder != MediaSortOrder.newestFirst)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _ActiveChip(
                            label: state.sortOrder.label,
                            onRemove: () => ref
                                .read(droneMediaViewModelProvider.notifier)
                                .updateSortOrder(MediaSortOrder.newestFirst),
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
              ),

            const SizedBox(height: 8),

            // ── Lista agrupada por missão ──────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: () =>
                    ref.read(droneMediaViewModelProvider.notifier).fetch(),
                child: _buildBody(state, groups),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    DroneMediaState state,
    List<
        ({
          int missionId,
          String missionTitle,
          List<DroneImageEntry> images,
        })>
        groups,
  ) {
    if (state.isLoading && state.allEntries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (state.allEntries.isEmpty) {
      return _buildEmptyState(hasSearch: false);
    }

    if (groups.isEmpty) {
      return _buildEmptyState(hasSearch: true);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      itemCount: groups.length,
      itemBuilder: (context, i) => _buildMissionGroup(context, groups[i]),
    );
  }

  Widget _buildMissionGroup(
    BuildContext context,
    ({int missionId, String missionTitle, List<DroneImageEntry> images}) group,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mission header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flight_outlined,
                    size: 16,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.missionTitle,
                        style: AppText.medium.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${group.images.length} foto${group.images.length != 1 ? 's' : ''}',
                        style: AppText.small.copyWith(
                          color: AppColors.grayMedium,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.grayMedium,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'open') {
                      Navigator.of(context).pushNamed(
                        '/drone/mission/details',
                        arguments: group.missionId,
                      );
                    } else if (value == 'download') {
                      _downloadImages(context, group.images);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_outlined, size: 18, color: AppColors.navy),
                          SizedBox(width: 10),
                          Text('Abrir missão'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download_outlined, size: 18, color: AppColors.navy),
                          SizedBox(width: 10),
                          Text('Baixar fotos da missão'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Horizontal photo strip ────────────────────────────────────
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: group.images.length,
              itemBuilder: (context, i) {
                final entry = group.images[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _openViewer(group.images, i, context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.file(
                            File(entry.image.localPath),
                            width: 110,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 120,
                              color: AppColors.white,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.grayMedium,
                                size: 28,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 4,
                              ),
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Text(
                                DateFormat('dd/MM/yy HH:mm').format(
                                  entry.image.datetime,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
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
                                child: const Icon(
                                  Icons.check,
                                  color: AppColors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

          // ── Missão ────────────────────────────────────────────────────────
          if (state.availableMissions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Missão',
              style: AppText.body.copyWith(
                color: AppColors.grayMedium,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: state.missionIdFilter == null,
                  onTap: () => vm.setMissionFilter(null),
                ),
                ...state.availableMissions.map(
                  (m) => _FilterChip(
                    label: m.title,
                    selected: state.missionIdFilter == m.id,
                    onTap: () => vm.setMissionFilter(m.id),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ── Vínculo ──────────────────────────────────────────────────────
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

          const SizedBox(height: 20),

          // ── Período ───────────────────────────────────────────────────────
          Text(
            'Período',
            style: AppText.body.copyWith(
              color: AppColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  placeholder: 'Início',
                  date: state.dateFrom,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) vm.setDateFrom(picked);
                  },
                  onClear: () => vm.setDateFrom(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateField(
                  placeholder: 'Fim',
                  date: state.dateTo,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) vm.setDateTo(picked);
                  },
                  onClear: () => vm.setDateTo(null),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Ordenar ───────────────────────────────────────────────────────
          Text(
            'Ordenar por',
            style: AppText.body.copyWith(
              color: AppColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: MediaSortOrder.values
                .map(
                  (o) => _FilterChip(
                    label: o.label,
                    selected: state.sortOrder == o,
                    onTap: () => vm.updateSortOrder(o),
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

// ─── Date field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String placeholder;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.placeholder,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.green.withValues(alpha: 0.06)
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate
                ? AppColors.green.withValues(alpha: 0.5)
                : const Color(0xFFDDE4DD),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: hasDate ? AppColors.green : AppColors.grayMedium,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('dd/MM/yyyy').format(date!)
                    : placeholder,
                style: TextStyle(
                  fontSize: 13,
                  color: hasDate ? AppColors.green : AppColors.grayMedium,
                ),
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────

class _MediaImageViewerPage extends StatefulWidget {
  final List<DroneImageEntry> entries;
  final int initialIndex;

  const _MediaImageViewerPage({
    required this.entries,
    required this.initialIndex,
  });

  @override
  State<_MediaImageViewerPage> createState() => _MediaImageViewerPageState();
}

class _MediaImageViewerPageState extends State<_MediaImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final path = widget.entries[_currentIndex].image.localPath;
      await Gal.putImage(path);
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Foto salva na galeria.'),
        );
      }
    } catch (_) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Erro ao salvar na galeria.'),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.entries.length}',
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            Text(
              entry.missionTitle,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined, color: Colors.white),
                  tooltip: 'Baixar foto',
                  onPressed: _downloadCurrent,
                ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.entries.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) {
          final e = widget.entries[i];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(e.image.localPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(entry.image.datetime),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
