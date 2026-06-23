import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/core/const/analysis_status.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';

enum AnalysisSortOrder {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA;

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

  String get sqlOrderBy {
    switch (this) {
      case AnalysisSortOrder.newestFirst:
        return 'datetime DESC';
      case AnalysisSortOrder.oldestFirst:
        return 'datetime ASC';
      case AnalysisSortOrder.titleAZ:
        return 'title ASC';
      case AnalysisSortOrder.titleZA:
        return 'title DESC';
    }
  }
}

class AnalysesListState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final List<AnalysisModel> analyses;
  final List<CropModel> availableCrops;

  // Filters
  final String searchQuery;
  final Set<AnalysisStatus> statusFilter;
  final Set<int> cropFilter;
  final AnalysisSortOrder sortOrder;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const AnalysesListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.analyses = const [],
    this.availableCrops = const [],
    this.searchQuery = '',
    this.statusFilter = const {},
    this.cropFilter = const {},
    this.sortOrder = AnalysisSortOrder.newestFirst,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      statusFilter.isNotEmpty ||
      cropFilter.isNotEmpty ||
      sortOrder != AnalysisSortOrder.newestFirst ||
      dateFrom != null ||
      dateTo != null;

  int get activeFilterCount =>
      (statusFilter.isNotEmpty ? 1 : 0) +
      (cropFilter.isNotEmpty ? 1 : 0) +
      (sortOrder != AnalysisSortOrder.newestFirst ? 1 : 0) +
      (dateFrom != null ? 1 : 0) +
      (dateTo != null ? 1 : 0);

  AnalysesListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    List<AnalysisModel>? analyses,
    List<CropModel>? availableCrops,
    String? searchQuery,
    Set<AnalysisStatus>? statusFilter,
    Set<int>? cropFilter,
    AnalysisSortOrder? sortOrder,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    bool clearError = false,
  }) {
    return AnalysesListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      analyses: analyses ?? this.analyses,
      availableCrops: availableCrops ?? this.availableCrops,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      cropFilter: cropFilter ?? this.cropFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
    analyses,
    availableCrops,
    searchQuery,
    statusFilter,
    cropFilter,
    sortOrder,
    dateFrom,
    dateTo,
  ];
}

const Object _sentinel = Object();
