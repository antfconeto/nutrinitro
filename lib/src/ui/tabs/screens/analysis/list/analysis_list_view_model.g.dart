// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_list_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysesListViewModel)
const analysesListViewModelProvider = AnalysesListViewModelProvider._();

final class AnalysesListViewModelProvider
    extends $NotifierProvider<AnalysesListViewModel, AnalysesListState> {
  const AnalysesListViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysesListViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysesListViewModelHash();

  @$internal
  @override
  AnalysesListViewModel create() => AnalysesListViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysesListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysesListState>(value),
    );
  }
}

String _$analysesListViewModelHash() =>
    r'cf9be607730dd81d9f81cf58341139a4a7d3f435';

abstract class _$AnalysesListViewModel extends $Notifier<AnalysesListState> {
  AnalysesListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AnalysesListState, AnalysesListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalysesListState, AnalysesListState>,
              AnalysesListState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
