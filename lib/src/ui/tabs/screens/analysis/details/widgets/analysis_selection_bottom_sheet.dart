import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/crop_analysis_option.dart';
import 'package:nutrinitro/src/data/services/analysis/recipe/catalog/recipe_catalog_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_details_view_model.dart';

class AnalysisSelectionBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required AnalysisModel analysis,
  }) async {
    final cropName = analysis.crop?.name;
    final registeredAnalyses = await ref.read(
      cropRegisteredAnalysesProvider(
        cropId: analysis.cropId,
        cropName: cropName,
      ).future,
    );

    final selectedBaseAnalyses =
        registeredAnalyses.map((a) => a.analysisId).toSet();
    const selectedBlockSize = 10;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.playlist_add_check_outlined,
                        color: AppColors.green,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Configurar Análise',
                        style: AppText.medium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    registeredAnalyses.isEmpty
                        ? 'Nenhuma análise cadastrada para ${cropName ?? "esta cultura"}.'
                        : 'Análises cadastradas para ${cropName ?? "esta cultura"}:',
                    style: AppText.small.copyWith(color: AppColors.grayMedium),
                  ),
                  const SizedBox(height: 20),
                  if (registeredAnalyses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grayLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cadastre uma receita vinculada a esta cultura para habilitar análises offline.',
                        style: AppText.small.copyWith(color: AppColors.grayMedium),
                      ),
                    )
                  else
                    ...registeredAnalyses.map((option) {
                      final isChecked =
                          selectedBaseAnalyses.contains(option.analysisId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: isChecked
                            ? AppColors.green.withOpacity(0.04)
                            : AppColors.grayLight.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isChecked
                                ? AppColors.green.withOpacity(0.3)
                                : AppColors.grayLight,
                            width: isChecked ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isChecked
                                ? AppColors.green.withOpacity(0.12)
                                : AppColors.grayLight,
                            child: Icon(
                              Icons.biotech_outlined,
                              color: isChecked
                                  ? AppColors.green
                                  : AppColors.grayMedium,
                            ),
                          ),
                          title: Text(
                            option.displayName,
                            style: AppText.medium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              option.description,
                              style: AppText.small.copyWith(
                                fontSize: 11,
                                color: AppColors.grayMedium,
                              ),
                            ),
                          ),
                          trailing: SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              activeColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedBaseAnalyses.add(option.analysisId);
                                  } else {
                                    selectedBaseAnalyses.remove(option.analysisId);
                                  }
                                });
                              },
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                selectedBaseAnalyses.remove(option.analysisId);
                              } else {
                                selectedBaseAnalyses.add(option.analysisId);
                              }
                            });
                          },
                        ),
                      );
                    }),
                  if (registeredAnalyses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        _summary(registeredAnalyses, selectedBaseAnalyses),
                        style: AppText.small.copyWith(
                          fontSize: 11,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedBaseAnalyses.isEmpty
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              ref
                                  .read(analysisDetailsViewModelProvider.notifier)
                                  .startAnalysis(
                                    selectedBaseAnalyses.toList(),
                                    blockSize: selectedBlockSize,
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.grayLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        selectedBaseAnalyses.isEmpty
                            ? 'Selecione pelo menos uma análise'
                            : 'Iniciar ${selectedBaseAnalyses.length} Análise${selectedBaseAnalyses.length > 1 ? 's' : ''}',
                        style: AppText.button.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selectedBaseAnalyses.isEmpty
                              ? AppColors.grayMedium
                              : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _summary(
    List<CropAnalysisOption> options,
    Set<String> selectedIds,
  ) {
    final selected = options
        .where((option) => selectedIds.contains(option.analysisId))
        .map((option) => option.description)
        .toList();

    if (selected.isEmpty) {
      return 'Selecione ao menos uma análise para ver o resumo.';
    }
    return selected.join('\n\n');
  }
}
