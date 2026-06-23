// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_monitor_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MissionMonitorViewModel)
const missionMonitorViewModelProvider = MissionMonitorViewModelProvider._();

final class MissionMonitorViewModelProvider
    extends $NotifierProvider<MissionMonitorViewModel, MissionMonitorState> {
  const MissionMonitorViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missionMonitorViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missionMonitorViewModelHash();

  @$internal
  @override
  MissionMonitorViewModel create() => MissionMonitorViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissionMonitorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissionMonitorState>(value),
    );
  }
}

String _$missionMonitorViewModelHash() =>
    r'64c03552f26e25dbd83b76d829d42fff11cc0c98';

abstract class _$MissionMonitorViewModel
    extends $Notifier<MissionMonitorState> {
  MissionMonitorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MissionMonitorState, MissionMonitorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MissionMonitorState, MissionMonitorState>,
              MissionMonitorState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
