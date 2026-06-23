import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/core/const/drone/mission_status.dart';
import 'package:nutrinitro/src/data/models/drone/mission_model.dart';

class DroneMissionsState extends Equatable {
  final bool isLoading;
  final List<MissionModel> allMissions;
  final String searchQuery;
  final List<MissionStatus> statusFilter;
  final String? errorMessage;

  const DroneMissionsState({
    this.isLoading = false,
    this.allMissions = const [],
    this.searchQuery = '',
    this.statusFilter = const [],
    this.errorMessage,
  });

  List<MissionModel> get missions {
    var result = allMissions;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((m) => m.title.toLowerCase().contains(q)).toList();
    }
    if (statusFilter.isNotEmpty) {
      result =
          result.where((m) => statusFilter.contains(m.status)).toList();
    }
    return result;
  }

  bool get hasActiveFilters => statusFilter.isNotEmpty;
  int get activeFilterCount => statusFilter.length;

  DroneMissionsState copyWith({
    bool? isLoading,
    List<MissionModel>? allMissions,
    String? searchQuery,
    List<MissionStatus>? statusFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneMissionsState(
      isLoading: isLoading ?? this.isLoading,
      allMissions: allMissions ?? this.allMissions,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allMissions,
        searchQuery,
        statusFilter,
        errorMessage,
      ];
}
