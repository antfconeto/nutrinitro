import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

enum MissionSortOrder {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA;

  String get label {
    switch (this) {
      case MissionSortOrder.newestFirst:
        return 'Mais recentes';
      case MissionSortOrder.oldestFirst:
        return 'Mais antigas';
      case MissionSortOrder.titleAZ:
        return 'Título A→Z';
      case MissionSortOrder.titleZA:
        return 'Título Z→A';
    }
  }
}

class DroneMissionsState extends Equatable {
  final bool isLoading;
  final List<MissionModel> allMissions;
  final String searchQuery;
  final List<MissionStatus> statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final MissionSortOrder sortOrder;
  final String? errorMessage;

  const DroneMissionsState({
    this.isLoading = false,
    this.allMissions = const [],
    this.searchQuery = '',
    this.statusFilter = const [],
    this.dateFrom,
    this.dateTo,
    this.sortOrder = MissionSortOrder.newestFirst,
    this.errorMessage,
  });

  List<MissionModel> get missions {
    var result = allMissions;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((m) => m.title.toLowerCase().contains(q)).toList();
    }
    if (statusFilter.isNotEmpty) {
      result = result.where((m) => statusFilter.contains(m.status)).toList();
    }
    if (dateFrom != null) {
      final from = DateTime(dateFrom!.year, dateFrom!.month, dateFrom!.day);
      result = result.where((m) => !m.createdAt.isBefore(from)).toList();
    }
    if (dateTo != null) {
      final to =
          DateTime(dateTo!.year, dateTo!.month, dateTo!.day, 23, 59, 59);
      result = result.where((m) => !m.createdAt.isAfter(to)).toList();
    }

    result = List<MissionModel>.from(result)
      ..sort((a, b) => switch (sortOrder) {
            MissionSortOrder.newestFirst =>
              b.createdAt.compareTo(a.createdAt),
            MissionSortOrder.oldestFirst =>
              a.createdAt.compareTo(b.createdAt),
            MissionSortOrder.titleAZ => a.title.compareTo(b.title),
            MissionSortOrder.titleZA => b.title.compareTo(a.title),
          });

    return result;
  }

  bool get hasActiveFilters =>
      statusFilter.isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      sortOrder != MissionSortOrder.newestFirst;

  int get activeFilterCount =>
      (statusFilter.isNotEmpty ? 1 : 0) +
      (dateFrom != null ? 1 : 0) +
      (dateTo != null ? 1 : 0) +
      (sortOrder != MissionSortOrder.newestFirst ? 1 : 0);

  DroneMissionsState copyWith({
    bool? isLoading,
    List<MissionModel>? allMissions,
    String? searchQuery,
    List<MissionStatus>? statusFilter,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    MissionSortOrder? sortOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneMissionsState(
      isLoading: isLoading ?? this.isLoading,
      allMissions: allMissions ?? this.allMissions,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allMissions,
        searchQuery,
        statusFilter,
        dateFrom,
        dateTo,
        sortOrder,
        errorMessage,
      ];
}

const Object _sentinel = Object();
