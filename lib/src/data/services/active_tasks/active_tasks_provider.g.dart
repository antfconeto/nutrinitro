// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveTasks)
const activeTasksProvider = ActiveTasksProvider._();

final class ActiveTasksProvider
    extends $NotifierProvider<ActiveTasks, ActiveTasksState> {
  const ActiveTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTasksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTasksHash();

  @$internal
  @override
  ActiveTasks create() => ActiveTasks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveTasksState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveTasksState>(value),
    );
  }
}

String _$activeTasksHash() => r'40d3e0d973efe18591013d6a07b5093f39ce646d';

abstract class _$ActiveTasks extends $Notifier<ActiveTasksState> {
  ActiveTasksState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ActiveTasksState, ActiveTasksState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveTasksState, ActiveTasksState>,
              ActiveTasksState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
