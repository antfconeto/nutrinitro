import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/drone/drone_connection_state.dart';
import 'package:nutrinitro/src/data/models/drone/drone_media_file.dart';
import 'package:nutrinitro/src/ui/tabs/screens/drone/drone_view_model.dart';

import 'drone_floating_fpv_window.dart';
import 'drone_media_thumbnail.dart';

class DroneMediaFullscreenPage extends ConsumerWidget {
  final DroneMediaFile file;
  final VoidCallback onDownload;
  final bool isDownloading;

  const DroneMediaFullscreenPage({
    super.key,
    required this.file,
    required this.onDownload,
    this.isDownloading = false,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(droneViewModelProvider);
    final isConnected =
        state.connectionState == DroneConnectionState.connected;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final mediaWidth =
                constraints.maxWidth - (isConnected ? 188.0 : 0.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: mediaWidth,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: DroneMediaThumbnail(
                        file: file,
                        large: true,
                        fullscreen: true,
                      ),
                    ),
                  ),
                ),

            Positioned(
              top: 0,
              left: 0,
              right: isConnected ? 188 : 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.white),
                      ),
                      Expanded(
                        child: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.medium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isDownloading)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: onDownload,
                          icon: const Icon(
                            Icons.download_rounded,
                            color: AppColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: isConnected ? 188 : 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${file.category.label} · ${_formatSize(file.sizeBytes)} · '
                    '${DateFormat('dd/MM/yyyy HH:mm').format(file.createdTime)}',
                    style: AppText.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),

              if (isConnected)
                Positioned(
                  right: 16,
                  top: 48,
                  child: DroneFloatingFpvWindow(
                    isConnected: isConnected,
                    isRecording: state.isRecordingVideo,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
