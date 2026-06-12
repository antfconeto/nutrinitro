import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';

class AnalysesListState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final List<AnalysisModel> analyses;

  const AnalysesListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.analyses = const [],
  });

  AnalysesListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    List<AnalysisModel>? analyses,
    bool clearError = false,
  }) {
    return AnalysesListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      analyses: analyses ?? this.analyses,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
    analyses,
  ];
}
