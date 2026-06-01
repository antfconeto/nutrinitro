import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';

class AnalysisDetailsState extends Equatable {
  final bool isLoading;
  final bool isAnalyzing;
  final String? errorMessage;
  final String? successMessage;
  final AnalysisModel? analysis;
  final int activeImageIndex;
  final int currentAnalyzingImageIndex;
  final int totalImagesToAnalyze;
  final List<List<double>>? liveScanningMatrix;

  const AnalysisDetailsState({
    this.isLoading = false,
    this.isAnalyzing = false,
    this.errorMessage,
    this.successMessage,
    this.analysis,
    this.activeImageIndex = 0,
    this.currentAnalyzingImageIndex = 0,
    this.totalImagesToAnalyze = 0,
    this.liveScanningMatrix,
  });

  AnalysisDetailsState copyWith({
    bool? isLoading,
    bool? isAnalyzing,
    String? errorMessage,
    String? successMessage,
    AnalysisModel? analysis,
    int? activeImageIndex,
    int? currentAnalyzingImageIndex,
    int? totalImagesToAnalyze,
    List<List<double>>? liveScanningMatrix,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearLiveMatrix = false,
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
      liveScanningMatrix: clearLiveMatrix ? null : (liveScanningMatrix ?? this.liveScanningMatrix),
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
        liveScanningMatrix,
      ];
}
