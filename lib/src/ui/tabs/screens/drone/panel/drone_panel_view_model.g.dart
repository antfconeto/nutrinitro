// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_panel_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DronePanelViewModel)
const dronePanelViewModelProvider = DronePanelViewModelProvider._();

final class DronePanelViewModelProvider
    extends $NotifierProvider<DronePanelViewModel, DronePanelState> {
  const DronePanelViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dronePanelViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dronePanelViewModelHash();

  @$internal
  @override
  DronePanelViewModel create() => DronePanelViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DronePanelState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DronePanelState>(value),
    );
  }
}

String _$dronePanelViewModelHash() =>
    r'bc4d63bf51bdae5cf56ab7d317ce08808bf0805e';

abstract class _$DronePanelViewModel extends $Notifier<DronePanelState> {
  DronePanelState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DronePanelState, DronePanelState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DronePanelState, DronePanelState>,
              DronePanelState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
