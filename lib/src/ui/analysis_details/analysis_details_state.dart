import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/services/analysis/core/analysis_progress.dart';

class AnalysisDetailsState extends Equatable {
  final bool isLoading;
  final bool isAnalyzing;
  final String? errorMessage;
  final String? successMessage;
  final AnalysisModel? analysis;
  final int activeImageIndex;
  final int currentAnalyzingImageIndex;
  final int totalImagesToAnalyze;
  final AnalysisStageUpdate? currentAnalysisStage;
  final AnalysisPipelineSnapshot? currentPipelineSnapshot;
  final String? currentAnalyzingType;
  final Map<String, dynamic>? currentEstimatedResult;
  final List<AnalysisStageUpdate>? _recipeStages;

  List<AnalysisStageUpdate> get recipeStages => _recipeStages ?? const [];

  const AnalysisDetailsState({
    this.isLoading = false,
    this.isAnalyzing = false,
    this.errorMessage,
    this.successMessage,
    this.analysis,
    this.activeImageIndex = 0,
    this.currentAnalyzingImageIndex = 0,
    this.totalImagesToAnalyze = 0,
    this.currentAnalysisStage,
    this.currentPipelineSnapshot,
    this.currentAnalyzingType,
    this.currentEstimatedResult,
    List<AnalysisStageUpdate>? recipeStages,
  }) : _recipeStages = recipeStages;

  AnalysisDetailsState copyWith({
    bool? isLoading,
    bool? isAnalyzing,
    String? errorMessage,
    String? successMessage,
    AnalysisModel? analysis,
    int? activeImageIndex,
    int? currentAnalyzingImageIndex,
    int? totalImagesToAnalyze,
    AnalysisStageUpdate? currentAnalysisStage,
    AnalysisPipelineSnapshot? currentPipelineSnapshot,
    String? currentAnalyzingType,
    Map<String, dynamic>? currentEstimatedResult,
    List<AnalysisStageUpdate>? recipeStages,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAnalysisStage = false,
    bool clearPipelineSnapshot = false,
    bool clearEstimatedResult = false,
  }) {
    return AnalysisDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      analysis: analysis ?? this.analysis,
      activeImageIndex: activeImageIndex ?? this.activeImageIndex,
      currentAnalyzingImageIndex: currentAnalyzingImageIndex ?? this.currentAnalyzingImageIndex,
      totalImagesToAnalyze: totalImagesToAnalyze ?? this.totalImagesToAnalyze,
      currentAnalysisStage: clearAnalysisStage
          ? null
          : (currentAnalysisStage ?? this.currentAnalysisStage),
      currentPipelineSnapshot: clearPipelineSnapshot
          ? null
          : (currentPipelineSnapshot ?? this.currentPipelineSnapshot),
      currentAnalyzingType: currentAnalyzingType ?? this.currentAnalyzingType,
      currentEstimatedResult: clearEstimatedResult ? null : (currentEstimatedResult ?? this.currentEstimatedResult),
      recipeStages: recipeStages ?? _recipeStages,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isAnalyzing,
        errorMessage,
        successMessage,
        analysis,
        activeImageIndex,
        currentAnalyzingImageIndex,
        totalImagesToAnalyze,
        currentAnalysisStage,
        currentPipelineSnapshot,
        currentAnalyzingType,
        currentEstimatedResult,
        _recipeStages,
      ];
}
