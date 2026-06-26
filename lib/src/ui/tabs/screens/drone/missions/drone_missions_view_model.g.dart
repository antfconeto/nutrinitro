// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_missions_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DroneMissionsViewModel)
const droneMissionsViewModelProvider = DroneMissionsViewModelProvider._();

final class DroneMissionsViewModelProvider
    extends $NotifierProvider<DroneMissionsViewModel, DroneMissionsState> {
  const DroneMissionsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneMissionsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneMissionsViewModelHash();

  @$internal
  @override
  DroneMissionsViewModel create() => DroneMissionsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneMissionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneMissionsState>(value),
    );
  }
}

String _$droneMissionsViewModelHash() =>
    r'f9bbe6da30b83beddf56cdb1dedd6eedb87a656f';

abstract class _$DroneMissionsViewModel extends $Notifier<DroneMissionsState> {
  DroneMissionsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DroneMissionsState, DroneMissionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DroneMissionsState, DroneMissionsState>,
              DroneMissionsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
