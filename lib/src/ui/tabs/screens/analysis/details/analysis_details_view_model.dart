import 'dart:convert';
import 'package:nutrinitro/src/core/const/analysis_status.dart';
import 'package:nutrinitro/src/core/const/repository_includes.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/analysis_details_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_details_view_model.g.dart';

@riverpod
class AnalysisDetailsViewModel extends _$AnalysisDetailsViewModel {
  int? _analysisId;
  bool _isCancelled = false;

  @override
  AnalysisDetailsState build() {
    ref.onDispose(() {
      _isCancelled = true;
    });
    return const AnalysisDetailsState();
  }

  void cancelAnalysis() {
    _isCancelled = true;
  }

  Future<void> init(int analysisId) async {
    _analysisId = analysisId;
    await fetchDetails();
  }

  Future<void> fetchDetails() async {
    if (_analysisId == null) return;
    
    state = state.copyWith(isLoading: state.analysis == null);

    final repo = await ref.read(analysisRepositoryProvider.future);
    final result = await repo.find(
      _analysisId!,
      include: {AnalysisInclude.crop, AnalysisInclude.images},
    );

    switch (result) {
      case Success(value: final analysis):
        state = state.copyWith(
          isLoading: false,
          analysis: analysis,
          clearError: true,
        );
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  void updateActiveImage(int index) {
    state = state.copyWith(activeImageIndex: index);
  }

  Future<void> startAnalysis(List<String> analysisTypes, {int blockSize = 10}) async {
    final currentAnalysis = state.analysis;
    if (currentAnalysis == null || _analysisId == null) return;
    if (currentAnalysis.isProcessing) return;
    if (analysisTypes.isEmpty) return;

    final images = currentAnalysis.images;
    final int total = images.length;

    state = state.copyWith(
      isAnalyzing: true,
      currentAnalyzingImageIndex: 0,
      totalImagesToAnalyze: total,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final analysisRepo = await ref.read(analysisRepositoryProvider.future);
      final imageRepo = await ref.read(imageRepositoryProvider.future);
      final recipeRepo = await ref.read(analysisRecipeRepositoryProvider.future);
      final analysisService = ref.read(analysisServiceProvider);

      // 1. Update status to processing and set the chosen analysis types
      await analysisRepo.update(_analysisId!, {
        'status': AnalysisStatus.processing.name,
        'analysis_type': analysisTypes.join(','),
      });
      await fetchDetails();

      // 2. Process each image
      final cropDataJson = currentAnalysis.crop?.analysisDataJson ?? '{}';
      final cropId = currentAnalysis.cropId;
      String? resolvedRecipeJson;
      String? resolvedRecipeId;
      String? resolvedRecipeVersion;
      List<AnalysisStageUpdate> recipeStages = const [];

      if (analysisTypes.contains('nitrogen')) {
        final recipeResult = await recipeRepo.findDefaultByCropId(cropId);
        switch (recipeResult) {
          case Success(value: final recipe):
            if (recipe == null) {
              throw Exception('Nenhuma receita de análise encontrada para esta cultura.');
            }
            resolvedRecipeJson = recipe.toJsonString();
            resolvedRecipeId = recipe.id;
            resolvedRecipeVersion = recipe.version;
            recipeStages = analysisStagesFromRecipe(recipe);
          case Failure(:final error):
            throw Exception('Erro ao carregar receita: $error');
        }
      }

      state = state.copyWith(recipeStages: recipeStages);

      for (int i = 0; i < total; i++) {
        if (_isCancelled) {
          await _resetStatusToPendingDirectly();
          return;
        }
        final image = images[i];
        if (image.id == null) continue;

        state = state.copyWith(
          currentAnalyzingImageIndex: i + 1,
          totalImagesToAnalyze: total,
          clearAnalysisStage: true,
          clearPipelineSnapshot: true,
          clearEstimatedResult: true,
        );

        // Load existing results from database to preserve previously run analyses
        final Map<String, dynamic> mergedResult = {};
        if (image.result != null) {
          try {
            mergedResult.addAll(json.decode(image.result!) as Map<String, dynamic>);
          } catch (_) {}
        }
        
        String analyzedPath = image.analyzedPath ?? image.originalPath;

        for (final analysisType in analysisTypes) {
          if (_isCancelled) {
            await _resetStatusToPendingDirectly();
            return;
          }
          state = state.copyWith(
            currentAnalyzingType: analysisType,
            clearAnalysisStage: true,
            clearPipelineSnapshot: true,
          );
          final result = await analysisService.analyze(
            imagePath: image.originalPath,
            analysisDataJson: cropDataJson,
            analysisType: analysisType,
            blockSize: blockSize,
            recipeJson: analysisType == 'nitrogen' ? resolvedRecipeJson : null,
            recipeId: analysisType == 'nitrogen' ? resolvedRecipeId : null,
            recipeVersion: analysisType == 'nitrogen' ? resolvedRecipeVersion : null,
            onStage: (stage) {
              state = state.copyWith(currentAnalysisStage: stage);
            },
            onSnapshot: (snapshot) {
              state = state.copyWith(currentPipelineSnapshot: snapshot);
            },
          );

          try {
            final Map<String, dynamic> resultData = json.decode(result.result) as Map<String, dynamic>;
            
            // Do not overwrite previous non-null values with null values (e.g. heatmap paths)
            resultData.removeWhere((key, value) => value == null && mergedResult.containsKey(key));

            // Merge notes beautifully
            if (mergedResult.containsKey('notes') && resultData.containsKey('notes')) {
              final String prevNotes = mergedResult['notes'] as String;
              final String newNotes = resultData['notes'] as String;
              if (prevNotes != newNotes && !prevNotes.contains(newNotes)) {
                resultData['notes'] = '$prevNotes\n\n$newNotes';
              }
            }

            // Merge prediction methods
            if (mergedResult.containsKey('prediction_method') && resultData.containsKey('prediction_method')) {
              final String prevMethod = mergedResult['prediction_method'] as String;
              final String newMethod = resultData['prediction_method'] as String;
              if (prevMethod != newMethod && !prevMethod.contains(newMethod)) {
                resultData['prediction_method'] = '$prevMethod + $newMethod';
              }
            }
            
            mergedResult.addAll(resultData);
            state = state.copyWith(currentEstimatedResult: Map<String, dynamic>.from(mergedResult));
          } catch (e) {
            print('Error parsing result for $analysisType: $e');
          }

          if (result.analyzedPath != image.originalPath && result.analyzedPath.isNotEmpty) {
            analyzedPath = result.analyzedPath;
          }
        }

        if (_isCancelled) {
          await _resetStatusToPendingDirectly();
          return;
        }

        await imageRepo.update(image.id!, {
          'analyzed_path': analyzedPath,
          'result': json.encode(mergedResult),
        });
      }

      if (_isCancelled) {
        await _resetStatusToPendingDirectly();
        return;
      }

      // 3. Update status to completed
      await analysisRepo.update(_analysisId!, {'status': AnalysisStatus.completed.name});
      await fetchDetails();

      state = state.copyWith(
        isAnalyzing: false,
        currentAnalyzingImageIndex: total,
        successMessage: 'Análise concluída com sucesso!',
        clearAnalysisStage: true,
        clearPipelineSnapshot: true,
        currentAnalyzingType: null,
        clearEstimatedResult: true,
      );
    } catch (e) {
      if (_isCancelled) return;
      print('Error during analysis: $e');
      final analysisRepo = await ref.read(analysisRepositoryProvider.future);
      await analysisRepo.update(_analysisId!, {'status': AnalysisStatus.error.name});
      await fetchDetails();

      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Erro ao processar análise: $e',
        clearAnalysisStage: true,
        clearPipelineSnapshot: true,
        currentAnalyzingType: null,
        clearEstimatedResult: true,
      );
    }
  }

  Future<void> _resetStatusToPendingDirectly() async {
    if (_analysisId == null) return;
    try {
      final repo = await ref.read(analysisRepositoryProvider.future);
      await repo.update(_analysisId!, {
        'status': AnalysisStatus.pending.name,
      });
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  Future<bool> deleteAnalysis() async {
    if (_analysisId == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final repo = await ref.read(analysisRepositoryProvider.future);
      final result = await repo.delete(_analysisId!);

      switch (result) {
        case Success():
          state = state.copyWith(isLoading: false);
          return true;
        case Failure(:final error):
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Erro ao deletar análise: $error',
          );
          return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao deletar análise: $e',
      );
      return false;
    }
  }
}
