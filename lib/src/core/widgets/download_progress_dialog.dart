import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

Future<void> downloadWithProgress(
  BuildContext context, {
  required List<String> paths,
}) async {
  final progress = ValueNotifier<double>(0);

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DownloadProgressDialog(
        total: paths.length,
        progress: progress,
      ),
    ),
  );

  try {
    for (int i = 0; i < paths.length; i++) {
      await Gal.putImage(paths[i]);
      progress.value = (i + 1) / paths.length;
    }
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message:
              '${paths.length} foto${paths.length != 1 ? 's' : ''} salva${paths.length != 1 ? 's' : ''} na galeria.',
        ),
      );
    }
  } catch (_) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: 'Erro ao salvar na galeria.'),
      );
    }
  } finally {
    progress.dispose();
  }
}

class _DownloadProgressDialog extends StatelessWidget {
  final int total;
  final ValueNotifier<double> progress;

  const _DownloadProgressDialog({
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) {
            final current = (value * total).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download_outlined,
                  color: AppColors.green,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'Salvando na galeria...',
                  style: AppText.medium.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                Text(
                  '$current de $total foto${total != 1 ? 's' : ''}',
                  style: AppText.small.copyWith(color: AppColors.grayMedium),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.grayLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.green,
                    ),
                    minHeight: 8,
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
