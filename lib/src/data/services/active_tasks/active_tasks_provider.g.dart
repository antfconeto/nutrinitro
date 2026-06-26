// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveTasksNotifier)
const activeTasksProvider = ActiveTasksNotifierProvider._();

final class ActiveTasksNotifierProvider
    extends $NotifierProvider<ActiveTasksNotifier, ActiveTasksState> {
  const ActiveTasksNotifierProvider._()
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
  String debugGetCreateSourceHash() => _$activeTasksNotifierHash();

  @$internal
  @override
  ActiveTasksNotifier create() => ActiveTasksNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveTasksState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveTasksState>(value),
    );
  }
}

String _$activeTasksNotifierHash() =>
    r'71fa29815d04c859b6376bdb5390a88605db2628';

abstract class _$ActiveTasksNotifier extends $Notifier<ActiveTasksState> {
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
