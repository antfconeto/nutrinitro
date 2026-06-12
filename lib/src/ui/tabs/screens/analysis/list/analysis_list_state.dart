import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';

enum AnalysisSortOrder {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA,
}

extension AnalysisSortOrderLabel on AnalysisSortOrder {
  String get label {
    switch (this) {
      case AnalysisSortOrder.newestFirst:
        return 'Mais recentes';
      case AnalysisSortOrder.oldestFirst:
        return 'Mais antigas';
      case AnalysisSortOrder.titleAZ:
        return 'Título A→Z';
      case AnalysisSortOrder.titleZA:
        return 'Título Z→A';
    }
  }
}

class AnalysesListState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final List<AnalysisModel> analyses;

  // Search / filter / sort
  final String searchQuery;
  final AnalysisStatus? statusFilter;
  final AnalysisSortOrder sortOrder;

  const AnalysesListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.analyses = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.sortOrder = AnalysisSortOrder.newestFirst,
  });

  List<AnalysisModel> get filtered {
    var list = analyses.where((a) {
      final matchesQuery =
          searchQuery.isEmpty ||
          a.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (a.crop?.name.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);

      final matchesStatus = statusFilter == null || a.status == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    switch (sortOrder) {
      case AnalysisSortOrder.newestFirst:
        list.sort((a, b) => b.datetime.compareTo(a.datetime));
      case AnalysisSortOrder.oldestFirst:
        list.sort((a, b) => a.datetime.compareTo(b.datetime));
      case AnalysisSortOrder.titleAZ:
        list.sort((a, b) => a.title.compareTo(b.title));
      case AnalysisSortOrder.titleZA:
        list.sort((a, b) => b.title.compareTo(a.title));
    }

    return list;
  }

  bool get hasActiveFilters => statusFilter != null || searchQuery.isNotEmpty;

  AnalysesListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    List<AnalysisModel>? analyses,
    String? searchQuery,
    AnalysisStatus? statusFilter,
    AnalysisSortOrder? sortOrder,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return AnalysesListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      analyses: analyses ?? this.analyses,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
    analyses,
    searchQuery,
    statusFilter,
    sortOrder,
  ];
}
