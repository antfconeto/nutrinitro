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

class MediaMissionOption {
  final int id;
  final String title;

  const MediaMissionOption({required this.id, required this.title});
}

class DroneImageEntry {
  final DroneImageModel image;
  final String missionTitle;

  const DroneImageEntry({required this.image, required this.missionTitle});
}

class DroneMediaState extends Equatable {
  final bool isLoading;
  final List<DroneImageEntry> allEntries;
  final List<MediaMissionOption> availableMissions;
  final String searchQuery;
  final int? missionIdFilter;
  // null = todas, true = vinculadas, false = não vinculadas
  final bool? linkedFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final MediaSortOrder sortOrder;
  final String? errorMessage;

  const DroneMediaState({
    this.isLoading = false,
    this.allEntries = const [],
    this.availableMissions = const [],
    this.searchQuery = '',
    this.missionIdFilter,
    this.linkedFilter,
    this.dateFrom,
    this.dateTo,
    this.sortOrder = MediaSortOrder.newestFirst,
    this.errorMessage,
  });

  List<DroneImageEntry> get entries {
    var result = allEntries;

    if (missionIdFilter != null) {
      result =
          result.where((e) => e.image.missionId == missionIdFilter).toList();
    }
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

  /// Entries grouped by mission, in order of most recent image per group.
  List<({int missionId, String missionTitle, List<DroneImageEntry> images})>
  get missionGroups {
    final filtered = entries;
    final groupMap = <int, List<DroneImageEntry>>{};
    final order = <int>[];
    for (final e in filtered) {
      if (!groupMap.containsKey(e.image.missionId)) {
        groupMap[e.image.missionId] = [];
        order.add(e.image.missionId);
      }
      groupMap[e.image.missionId]!.add(e);
    }
    return order
        .map((id) => (
              missionId: id,
              missionTitle: groupMap[id]!.first.missionTitle,
              images: groupMap[id]!,
            ))
        .toList();
  }

  bool get hasActiveFilters =>
      missionIdFilter != null ||
      linkedFilter != null ||
      dateFrom != null ||
      dateTo != null ||
      sortOrder != MediaSortOrder.newestFirst;

  int get activeFilterCount =>
      (missionIdFilter != null ? 1 : 0) +
      (linkedFilter != null ? 1 : 0) +
      (dateFrom != null ? 1 : 0) +
      (dateTo != null ? 1 : 0) +
      (sortOrder != MediaSortOrder.newestFirst ? 1 : 0);

  String? get missionFilterLabel =>
      missionIdFilter == null
          ? null
          : availableMissions
                .where((m) => m.id == missionIdFilter)
                .map((m) => m.title)
                .firstOrNull;

  DroneMediaState copyWith({
    bool? isLoading,
    List<DroneImageEntry>? allEntries,
    List<MediaMissionOption>? availableMissions,
    String? searchQuery,
    Object? missionIdFilter = _sentinel,
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
      availableMissions: availableMissions ?? this.availableMissions,
      searchQuery: searchQuery ?? this.searchQuery,
      missionIdFilter: missionIdFilter == _sentinel
          ? this.missionIdFilter
          : missionIdFilter as int?,
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
        availableMissions,
        searchQuery,
        missionIdFilter,
        linkedFilter,
        dateFrom,
        dateTo,
        sortOrder,
        errorMessage,
      ];
}

const Object _sentinel = Object();
