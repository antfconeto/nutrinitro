import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/core/constants/repository_includes.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_details_view_model.g.dart';

@riverpod
class AnalysisDetailsViewModel extends _$AnalysisDetailsViewModel {
  int? _analysisId;

  @override
  AnalysisDetailsState build() {
    return const AnalysisDetailsState();
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

  Future<void> startAnalysis(String analysisType) async {
    final currentAnalysis = state.analysis;
    if (currentAnalysis == null || _analysisId == null) return;
    if (currentAnalysis.isProcessing) return;

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
      final analysisService = ref.read(analysisServiceProvider);

      // 1. Update status to processing and set the chosen analysis type
      await analysisRepo.update(_analysisId!, {
        'status': AnalysisStatus.processing.name,
        'analysis_type': analysisType,
      });
      await fetchDetails();

      // 2. Process each image
      final cropDataJson = currentAnalysis.crop?.analysisDataJson ?? '{}';

      for (int i = 0; i < total; i++) {
        final image = images[i];
        if (image.id == null) continue;

        state = state.copyWith(
          currentAnalyzingImageIndex: i + 1,
          totalImagesToAnalyze: total,
          clearLiveMatrix: true,
        );

        final result = await analysisService.analyze(
          imagePath: image.originalPath,
          analysisDataJson: cropDataJson,
          analysisType: analysisType,
          onProgress: (matrix) {
            state = state.copyWith(liveScanningMatrix: matrix);
          },
        );

        await imageRepo.update(image.id!, {
          'analyzed_path': result.analyzedPath,
          'result': result.result,
        });
      }

      // 3. Update status to completed
      await analysisRepo.update(_analysisId!, {'status': AnalysisStatus.completed.name});
      await fetchDetails();

      state = state.copyWith(
        isAnalyzing: false,
        currentAnalyzingImageIndex: total,
        successMessage: 'Análise concluída com sucesso!',
        clearLiveMatrix: true,
      );
    } catch (e) {
      print('Error during analysis: $e');
      final analysisRepo = await ref.read(analysisRepositoryProvider.future);
      await analysisRepo.update(_analysisId!, {'status': AnalysisStatus.error.name});
      await fetchDetails();

      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Erro ao processar análise: $e',
        clearLiveMatrix: true,
      );
    }
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
