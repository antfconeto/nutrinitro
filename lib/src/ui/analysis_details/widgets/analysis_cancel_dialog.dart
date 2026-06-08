import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';

class AnalysisCancelDialog {
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar Análise?'),
        content: const Text(
          'A análise está em andamento. Se você sair agora, a operação será cancelada e o progresso atual será perdido.',
        ),
        actions: [
          TextButton(
            child: const Text(
              'Continuar Análise',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar e Sair'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
