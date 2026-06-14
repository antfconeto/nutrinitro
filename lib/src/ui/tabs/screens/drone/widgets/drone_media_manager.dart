import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';
import 'package:nutrinitro/src/data/services/drone/drone_service_provider.dart';

class DroneMediaManager extends ConsumerStatefulWidget {
  final bool isConnected;

  const DroneMediaManager({
    super.key,
    required this.isConnected,
  });

  @override
  ConsumerState<DroneMediaManager> createState() => _DroneMediaManagerState();
}

class _DroneMediaManagerState extends ConsumerState<DroneMediaManager> {
  List<DroneMediaFile> _mediaFiles = [];
  bool _isLoading = false;
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    if (widget.isConnected) {
      _loadMedia();
    }
  }

  @override
  void didUpdateWidget(covariant DroneMediaManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !oldWidget.isConnected) {
      _loadMedia();
    } else if (!widget.isConnected) {
      setState(() {
        _mediaFiles = [];
      });
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final files = await ref.read(droneServiceProvider).fetchMediaList();
      setState(() {
        _mediaFiles = files;
      });
    } catch (_) {
      // Falha silenciosa ou mostra lista vazia
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(DroneMediaFile file) async {
    setState(() {
      _downloadProgress[file.id] = 0.1;
    });

    // Simular progresso do download
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _downloadProgress[file.id] = i / 10;
      });
    }

    try {
      await ref.read(droneServiceProvider).downloadMediaFile(file, '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} baixado com sucesso!'),
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
      if (mounted) {
        setState(() {
          _downloadProgress.remove(file.id);
        });
      }
    }
  }

  Future<void> _deleteFile(DroneMediaFile file) async {
    try {
      await ref.read(droneServiceProvider).deleteMediaFile(file);
      setState(() {
        _mediaFiles.removeWhere((item) => item.id == file.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo deletado do SD Card.'),
            backgroundColor: AppColors.navy,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao deletar arquivo.'),
            backgroundColor: AppColors.tomato,
          ),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConnected) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          'Conecte o drone para gerenciar mídias.',
          style: AppText.small.copyWith(color: AppColors.grayMedium),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mídias no SD Card',
                style: AppText.medium.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadMedia,
                icon: const Icon(Icons.refresh, color: AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.green),
              ),
            )
          else if (_mediaFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nenhuma mídia encontrada.',
                  style: AppText.small.copyWith(color: AppColors.grayMedium),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mediaFiles.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.grayLight),
              itemBuilder: (context, index) {
                final file = _mediaFiles[index];
                final isDownloading = _downloadProgress.containsKey(file.id);
                final progress = _downloadProgress[file.id] ?? 0.0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    file.type == DroneMediaType.photo
                        ? Icons.insert_photo_outlined
                        : Icons.play_circle_outline_outlined,
                    color: AppColors.green,
                    size: 28,
                  ),
                  title: Text(
                    file.name,
                    style: AppText.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _formatSize(file.sizeBytes),
                    style: AppText.small.copyWith(fontSize: 11, color: AppColors.grayMedium),
                  ),
                  trailing: isDownloading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            color: AppColors.green,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _downloadFile(file),
                              icon: const Icon(Icons.download_rounded, color: AppColors.green),
                            ),
                            IconButton(
                              onPressed: () => _deleteFile(file),
                              icon: const Icon(Icons.delete_outline_outlined, color: AppColors.tomato),
                            ),
                          ],
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
