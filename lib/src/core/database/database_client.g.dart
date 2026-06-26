// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(databaseClient)
const databaseClientProvider = DatabaseClientProvider._();

final class DatabaseClientProvider
    extends
        $FunctionalProvider<AsyncValue<Database>, Database, FutureOr<Database>>
    with $FutureModifier<Database>, $FutureProvider<Database> {
  const DatabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseClientHash();

  @$internal
  @override
  $FutureProviderElement<Database> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Database> create(Ref ref) {
    return databaseClient(ref);
  }
}

String _$databaseClientHash() => r'053f7a5cad0b4911e06424b71b1e513941b681d2';
