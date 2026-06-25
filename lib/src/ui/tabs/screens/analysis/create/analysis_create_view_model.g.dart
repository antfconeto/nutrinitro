// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_create_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysisCreateViewModel)
const analysisCreateViewModelProvider = AnalysisCreateViewModelProvider._();

final class AnalysisCreateViewModelProvider
    extends $NotifierProvider<AnalysisCreateViewModel, AnalysisCreateState> {
  const AnalysisCreateViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisCreateViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisCreateViewModelHash();

  @$internal
  @override
  AnalysisCreateViewModel create() => AnalysisCreateViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisCreateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisCreateState>(value),
    );
  }
}

String _$analysisCreateViewModelHash() =>
    r'd02a74f5bf25f89eb67e681375de37f5c20e3f45';

abstract class _$AnalysisCreateViewModel
    extends $Notifier<AnalysisCreateState> {
  AnalysisCreateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AnalysisCreateState, AnalysisCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalysisCreateState, AnalysisCreateState>,
              AnalysisCreateState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
