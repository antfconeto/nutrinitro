// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_create_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MissionCreateViewModel)
const missionCreateViewModelProvider = MissionCreateViewModelProvider._();

final class MissionCreateViewModelProvider
    extends $NotifierProvider<MissionCreateViewModel, MissionCreateState> {
  const MissionCreateViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missionCreateViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missionCreateViewModelHash();

  @$internal
  @override
  MissionCreateViewModel create() => MissionCreateViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissionCreateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissionCreateState>(value),
    );
  }
}

String _$missionCreateViewModelHash() =>
    r'ce2efd17064cd05cf37204782858c2b9733f246f';

abstract class _$MissionCreateViewModel extends $Notifier<MissionCreateState> {
  MissionCreateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MissionCreateState, MissionCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MissionCreateState, MissionCreateState>,
              MissionCreateState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
