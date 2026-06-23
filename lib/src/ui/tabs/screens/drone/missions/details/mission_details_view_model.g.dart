// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_details_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MissionDetailsViewModel)
const missionDetailsViewModelProvider = MissionDetailsViewModelProvider._();

final class MissionDetailsViewModelProvider
    extends $NotifierProvider<MissionDetailsViewModel, MissionDetailsState> {
  const MissionDetailsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'missionDetailsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$missionDetailsViewModelHash();

  @$internal
  @override
  MissionDetailsViewModel create() => MissionDetailsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MissionDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MissionDetailsState>(value),
    );
  }
}

String _$missionDetailsViewModelHash() =>
    r'efdcabcd25011d10d8561fcdca44e6c93fe30443';

abstract class _$MissionDetailsViewModel
    extends $Notifier<MissionDetailsState> {
  MissionDetailsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MissionDetailsState, MissionDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MissionDetailsState, MissionDetailsState>,
              MissionDetailsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
