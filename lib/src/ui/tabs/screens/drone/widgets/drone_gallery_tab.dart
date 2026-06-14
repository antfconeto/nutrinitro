import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_view_model.dart';

import 'drone_media_fullscreen_page.dart';
import 'drone_media_thumbnail.dart';

enum DroneMediaSortOption {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  sizeDesc,
}

extension DroneMediaSortOptionLabel on DroneMediaSortOption {
  String get label => switch (this) {
        DroneMediaSortOption.newest => 'Mais recentes',
        DroneMediaSortOption.oldest => 'Mais antigas',
        DroneMediaSortOption.nameAsc => 'Nome (A–Z)',
        DroneMediaSortOption.nameDesc => 'Nome (Z–A)',
        DroneMediaSortOption.sizeDesc => 'Maior tamanho',
      };
}

class DroneGalleryTab extends ConsumerStatefulWidget {
  final EdgeInsets contentPadding;

  const DroneGalleryTab({
    super.key,
    this.contentPadding = EdgeInsets.zero,
  });

  @override
  ConsumerState<DroneGalleryTab> createState() => _DroneGalleryTabState();
}

class _DroneGalleryTabState extends ConsumerState<DroneGalleryTab> {
  List<DroneMediaFile> _allMedia = [];
  bool _isLoading = true;
  DroneMediaCategory? _categoryFilter;
  DroneMediaSortOption _sort = DroneMediaSortOption.newest;
  final Set<String> _downloadingIds = {};
  final Set<String> _downloadedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    try {
      final files = await ref.read(droneViewModelProvider.notifier).fetchMediaList();
      if (mounted) setState(() => _allMedia = files);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DroneMediaFile> get _filteredMedia {
    final filtered = _categoryFilter == null
        ? List<DroneMediaFile>.from(_allMedia)
        : _allMedia.where((f) => f.category == _categoryFilter).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case DroneMediaSortOption.newest:
          return b.createdTime.compareTo(a.createdTime);
        case DroneMediaSortOption.oldest:
          return a.createdTime.compareTo(b.createdTime);
        case DroneMediaSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case DroneMediaSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case DroneMediaSortOption.sizeDesc:
          return b.sizeBytes.compareTo(a.sizeBytes);
      }
    });
    return filtered;
  }

  int _countFor(DroneMediaCategory category) =>
      _allMedia.where((f) => f.category == category).length;

  Future<void> _downloadFile(DroneMediaFile file) async {
    if (_downloadingIds.contains(file.id)) return;
    setState(() => _downloadingIds.add(file.id));
    try {
      final path =
          await ref.read(droneViewModelProvider.notifier).downloadMediaFile(file);
      if (mounted) {
        setState(() => _downloadedIds.add(file.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} salvo em $path'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao baixar arquivo.'),
            backgroundColor: AppColors.tomato,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(file.id));
    }
  }

  Future<void> _downloadAllVisible() async {
    final files = _filteredMedia;
    if (files.isEmpty) return;

    for (final file in files) {
      if (_downloadedIds.contains(file.id)) continue;
      await _downloadFile(file);
    }
  }

  void _openFullscreen(DroneMediaFile file) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, __, ___) => DroneMediaFullscreenPage(
          file: file,
          isDownloading: _downloadingIds.contains(file.id),
          onDownload: () => _downloadFile(file),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredMedia;

    return Padding(
      padding: widget.contentPadding,
      child: ColoredBox(
        color: AppColors.grayLight,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  'Galeria do Drone',
                  style: AppText.medium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<DroneMediaSortOption>(
                  tooltip: 'Ordenar',
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  icon: const Icon(Icons.sort_rounded, color: AppColors.green),
                  itemBuilder: (context) => DroneMediaSortOption.values
                      .map(
                        (option) => PopupMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                ),
                IconButton(
                  tooltip: 'Baixar visíveis',
                  onPressed: visible.isEmpty ? null : _downloadAllVisible,
                  icon: const Icon(Icons.download_for_offline_outlined,
                      color: AppColors.green),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _isLoading ? null : _loadMedia,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: AppColors.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'Todas (${_allMedia.length})',
                    selected: _categoryFilter == null,
                    onTap: () => setState(() => _categoryFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label:
                        '${DroneMediaCategory.preFlight.label} (${_countFor(DroneMediaCategory.preFlight)})',
                    selected: _categoryFilter == DroneMediaCategory.preFlight,
                    onTap: () => setState(
                      () => _categoryFilter = DroneMediaCategory.preFlight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label:
                        '${DroneMediaCategory.inFlight.label} (${_countFor(DroneMediaCategory.inFlight)})',
                    selected: _categoryFilter == DroneMediaCategory.inFlight,
                    onTap: () => setState(
                      () => _categoryFilter = DroneMediaCategory.inFlight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Ordenação: ${_sort.label}',
              style: AppText.small.copyWith(
                color: AppColors.grayMedium,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  )
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mídia nesta categoria.',
                          style: AppText.body.copyWith(
                            color: AppColors.grayMedium,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final file = visible[index];
                          final isDownloading =
                              _downloadingIds.contains(file.id);
                          final isDownloaded = _downloadedIds.contains(file.id);

                          return _GalleryTile(
                            file: file,
                            isDownloading: isDownloading,
                            isDownloaded: isDownloaded,
                            onTap: () => _openFullscreen(file),
                            onDownload: () => _downloadFile(file),
                          );
                        },
                      ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: AppText.small.copyWith(
          color: selected ? AppColors.white : AppColors.navy,
          fontSize: 11,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.green,
      backgroundColor: AppColors.white,
      checkmarkColor: AppColors.white,
      side: BorderSide(
        color: selected ? AppColors.green : const Color(0xFFDDE4DD),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final DroneMediaFile file;
  final bool isDownloading;
  final bool isDownloaded;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _GalleryTile({
    required this.file,
    required this.isDownloading,
    required this.isDownloaded,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DroneMediaThumbnail(file: file),
                  if (isDownloading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  if (isDownloaded && !isDownloading)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: onDownload,
                        icon: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: AppColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(file.createdTime),
                    style: AppText.small.copyWith(
                      color: AppColors.grayMedium,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
