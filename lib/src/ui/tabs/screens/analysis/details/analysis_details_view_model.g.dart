// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_details_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysisDetailsViewModel)
const analysisDetailsViewModelProvider = AnalysisDetailsViewModelProvider._();

final class AnalysisDetailsViewModelProvider
    extends $NotifierProvider<AnalysisDetailsViewModel, AnalysisDetailsState> {
  const AnalysisDetailsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisDetailsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisDetailsViewModelHash();

  @$internal
  @override
  AnalysisDetailsViewModel create() => AnalysisDetailsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisDetailsState>(value),
    );
  }
}

String _$analysisDetailsViewModelHash() =>
    r'd222bd4539e59bfa160bb7223d1164518deff0ed';

abstract class _$AnalysisDetailsViewModel
    extends $Notifier<AnalysisDetailsState> {
  AnalysisDetailsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AnalysisDetailsState, AnalysisDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalysisDetailsState, AnalysisDetailsState>,
              AnalysisDetailsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
