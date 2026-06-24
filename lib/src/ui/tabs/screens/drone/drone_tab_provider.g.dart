// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_tab_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls which sub-tab of DronePage is shown (0=Painel, 1=Missões, 2=Mídia).
/// Set before navigating to /tabs with arg 2 to open a specific drone sub-tab.

@ProviderFor(DroneTabIndex)
const droneTabIndexProvider = DroneTabIndexProvider._();

/// Controls which sub-tab of DronePage is shown (0=Painel, 1=Missões, 2=Mídia).
/// Set before navigating to /tabs with arg 2 to open a specific drone sub-tab.
final class DroneTabIndexProvider
    extends $NotifierProvider<DroneTabIndex, int> {
  /// Controls which sub-tab of DronePage is shown (0=Painel, 1=Missões, 2=Mídia).
  /// Set before navigating to /tabs with arg 2 to open a specific drone sub-tab.
  const DroneTabIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneTabIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneTabIndexHash();

  @$internal
  @override
  DroneTabIndex create() => DroneTabIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$droneTabIndexHash() => r'a4ef39b1c98223a082041f95ca8b3467b0a05259';

/// Controls which sub-tab of DronePage is shown (0=Painel, 1=Missões, 2=Mídia).
/// Set before navigating to /tabs with arg 2 to open a specific drone sub-tab.

abstract class _$DroneTabIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
