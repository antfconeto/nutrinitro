// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_media_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DroneMediaViewModel)
const droneMediaViewModelProvider = DroneMediaViewModelProvider._();

final class DroneMediaViewModelProvider
    extends $NotifierProvider<DroneMediaViewModel, DroneMediaState> {
  const DroneMediaViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneMediaViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneMediaViewModelHash();

  @$internal
  @override
  DroneMediaViewModel create() => DroneMediaViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneMediaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneMediaState>(value),
    );
  }
}

String _$droneMediaViewModelHash() =>
    r'83299f860fd1b5a92b971ab2fb8d2217829a212a';

abstract class _$DroneMediaViewModel extends $Notifier<DroneMediaState> {
  DroneMediaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DroneMediaState, DroneMediaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DroneMediaState, DroneMediaState>,
              DroneMediaState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
