import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/data/models/drone/drone_image_model.dart';

enum MediaSortOrder {
  newestFirst,
  oldestFirst;

  String get label {
    switch (this) {
      case MediaSortOrder.newestFirst:
        return 'Mais recentes';
      case MediaSortOrder.oldestFirst:
        return 'Mais antigas';
    }
  }
}

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
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final MediaSortOrder sortOrder;
  final String? errorMessage;

  const DroneMediaState({
    this.isLoading = false,
    this.allEntries = const [],
    this.searchQuery = '',
    this.linkedFilter,
    this.dateFrom,
    this.dateTo,
    this.sortOrder = MediaSortOrder.newestFirst,
    this.errorMessage,
  });

  List<DroneImageEntry> get entries {
    var result = allEntries;

    if (linkedFilter != null) {
      result =
          result.where((e) => e.image.isLinked == linkedFilter).toList();
    }
    if (dateFrom != null) {
      final from = DateTime(dateFrom!.year, dateFrom!.month, dateFrom!.day);
      result =
          result.where((e) => !e.image.datetime.isBefore(from)).toList();
    }
    if (dateTo != null) {
      final to =
          DateTime(dateTo!.year, dateTo!.month, dateTo!.day, 23, 59, 59);
      result = result.where((e) => !e.image.datetime.isAfter(to)).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((e) {
        return e.missionTitle.toLowerCase().contains(q) ||
            DateFormat('dd/MM/yyyy').format(e.image.datetime).contains(q);
      }).toList();
    }

    result = List<DroneImageEntry>.from(result)
      ..sort((a, b) => switch (sortOrder) {
            MediaSortOrder.newestFirst =>
              b.image.datetime.compareTo(a.image.datetime),
            MediaSortOrder.oldestFirst =>
              a.image.datetime.compareTo(b.image.datetime),
          });

    return result;
  }

  bool get hasActiveFilters =>
      linkedFilter != null ||
      dateFrom != null ||
      dateTo != null ||
      sortOrder != MediaSortOrder.newestFirst;

  int get activeFilterCount =>
      (linkedFilter != null ? 1 : 0) +
      (dateFrom != null ? 1 : 0) +
      (dateTo != null ? 1 : 0) +
      (sortOrder != MediaSortOrder.newestFirst ? 1 : 0);

  DroneMediaState copyWith({
    bool? isLoading,
    List<DroneImageEntry>? allEntries,
    String? searchQuery,
    Object? linkedFilter = _sentinel,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    MediaSortOrder? sortOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DroneMediaState(
      isLoading: isLoading ?? this.isLoading,
      allEntries: allEntries ?? this.allEntries,
      searchQuery: searchQuery ?? this.searchQuery,
      linkedFilter:
          linkedFilter == _sentinel ? this.linkedFilter : linkedFilter as bool?,
      dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allEntries,
        searchQuery,
        linkedFilter,
        dateFrom,
        dateTo,
        sortOrder,
        errorMessage,
      ];
}

const Object _sentinel = Object();
