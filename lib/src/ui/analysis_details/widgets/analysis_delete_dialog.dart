import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';

class AnalysisDeleteDialog {
  static Future<void> show({
    required BuildContext context,
    required Future<bool> Function() onDelete,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Análise?'),
        content: const Text(
          'Esta ação não pode ser desfeita. Todas as imagens e resultados associados serão removidos permanentemente.',
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.grayMedium),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              foregroundColor: AppColors.white,
            ),
            child: const Text(
              'Deletar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await onDelete();
              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
