import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';

class DroneImageEntry {
  final DroneImageModel image;
  final String missionTitle;

  const DroneImageEntry({required this.image, required this.missionTitle});
}

class DroneMediaState extends Equatable {
  final bool isLoading;
  final List<DroneImageEntry> allEntries;
  final String searchQuery;
  // null = todas, true = vinculadas, false = não vinculadas
  final bool? linkedFilter;
  final String? errorMessage;

  const DroneMediaState({
    this.isLoading = false,
    this.allEntries = const [],
    this.searchQuery = '',
    this.linkedFilter,
    this.errorMessage,
  });

  List<DroneImageEntry> get entries {
    var result = allEntries;
    if (linkedFilter != null) {
      result = result.where((e) => e.image.isLinked == linkedFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((e) {
        return e.missionTitle.toLowerCase().contains(q) ||
            DateFormat('dd/MM/yyyy').format(e.image.datetime).contains(q);
      }).toList();
    }
    return result;
  }

  bool get hasActiveFilters => linkedFilter != null;
  int get activeFilterCount => linkedFilter != null ? 1 : 0;

  DroneMediaState copyWith({
    bool? isLoading,
    List<DroneImageEntry>? allEntries,
    String? searchQuery,
    Object? linkedFilter = _sentinel,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneMediaState(
      isLoading: isLoading ?? this.isLoading,
      allEntries: allEntries ?? this.allEntries,
      searchQuery: searchQuery ?? this.searchQuery,
      linkedFilter:
          linkedFilter == _sentinel ? this.linkedFilter : linkedFilter as bool?,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, allEntries, searchQuery, linkedFilter, errorMessage];
}

const Object _sentinel = Object();
