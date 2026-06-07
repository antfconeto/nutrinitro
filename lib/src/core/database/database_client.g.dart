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

String _$databaseClientHash() => r'00528592efab3f4511fc730aa785f58061d454eb';
