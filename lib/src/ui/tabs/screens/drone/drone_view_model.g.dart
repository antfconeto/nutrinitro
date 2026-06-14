// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DroneViewModel)
const droneViewModelProvider = DroneViewModelProvider._();

final class DroneViewModelProvider
    extends $NotifierProvider<DroneViewModel, DroneState> {
  const DroneViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneViewModelHash();

  @$internal
  @override
  DroneViewModel create() => DroneViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneState>(value),
    );
  }
}

String _$droneViewModelHash() => r'578c356653b4ae83d6cd2391aa521c4b7b1898e9';

abstract class _$DroneViewModel extends $Notifier<DroneState> {
  DroneState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DroneState, DroneState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DroneState, DroneState>,
              DroneState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
