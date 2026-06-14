// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DroneServiceMode)
const droneServiceModeProvider = DroneServiceModeProvider._();

final class DroneServiceModeProvider
    extends $NotifierProvider<DroneServiceMode, bool> {
  const DroneServiceModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneServiceModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneServiceModeHash();

  @$internal
  @override
  DroneServiceMode create() => DroneServiceMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$droneServiceModeHash() => r'8d7f50db6598d130af5393d959f5ab0cc3e35a7b';

abstract class _$DroneServiceMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(droneService)
const droneServiceProvider = DroneServiceProvider._();

final class DroneServiceProvider
    extends $FunctionalProvider<DroneService, DroneService, DroneService>
    with $Provider<DroneService> {
  const DroneServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneServiceHash();

  @$internal
  @override
  $ProviderElement<DroneService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DroneService create(Ref ref) {
    return droneService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneService>(value),
    );
  }
}

String _$droneServiceHash() => r'30fe82fc196558d496d832c56a78d1ebc767c974';
