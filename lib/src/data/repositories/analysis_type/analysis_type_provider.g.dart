// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_type_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analysisTypeRepository)
const analysisTypeRepositoryProvider = AnalysisTypeRepositoryProvider._();

final class AnalysisTypeRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalysisTypeRepository>,
          AnalysisTypeRepository,
          FutureOr<AnalysisTypeRepository>
        >
    with
        $FutureModifier<AnalysisTypeRepository>,
        $FutureProvider<AnalysisTypeRepository> {
  const AnalysisTypeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisTypeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisTypeRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<AnalysisTypeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalysisTypeRepository> create(Ref ref) {
    return analysisTypeRepository(ref);
  }
}

String _$analysisTypeRepositoryHash() =>
    r'36113e01d3537d31538085077e1024aa47e62652';

/// Todos os tipos ativos; sincroniza o registry em memória.

@ProviderFor(allAnalysisTypes)
const allAnalysisTypesProvider = AllAnalysisTypesProvider._();

/// Todos os tipos ativos; sincroniza o registry em memória.

final class AllAnalysisTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisTypeModel>>,
          List<AnalysisTypeModel>,
          FutureOr<List<AnalysisTypeModel>>
        >
    with
        $FutureModifier<List<AnalysisTypeModel>>,
        $FutureProvider<List<AnalysisTypeModel>> {
  /// Todos os tipos ativos; sincroniza o registry em memória.
  const AllAnalysisTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAnalysisTypesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAnalysisTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<AnalysisTypeModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisTypeModel>> create(Ref ref) {
    return allAnalysisTypes(ref);
  }
}

String _$allAnalysisTypesHash() => r'4518434d65d4cc3858fe04f1377d10f2042a843b';

/// Tipos compatíveis com uma cultura.

@ProviderFor(analysisTypesForCrop)
const analysisTypesForCropProvider = AnalysisTypesForCropFamily._();

/// Tipos compatíveis com uma cultura.

final class AnalysisTypesForCropProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisTypeModel>>,
          List<AnalysisTypeModel>,
          FutureOr<List<AnalysisTypeModel>>
        >
    with
        $FutureModifier<List<AnalysisTypeModel>>,
        $FutureProvider<List<AnalysisTypeModel>> {
  /// Tipos compatíveis com uma cultura.
  const AnalysisTypesForCropProvider._({
    required AnalysisTypesForCropFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'analysisTypesForCropProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analysisTypesForCropHash();

  @override
  String toString() {
    return r'analysisTypesForCropProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AnalysisTypeModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisTypeModel>> create(Ref ref) {
    final argument = this.argument as int;
    return analysisTypesForCrop(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnalysisTypesForCropProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analysisTypesForCropHash() =>
    r'eb56cfd0c5a501ed56de1c1a496529da245bda9c';

/// Tipos compatíveis com uma cultura.

final class AnalysisTypesForCropFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AnalysisTypeModel>>, int> {
  const AnalysisTypesForCropFamily._()
    : super(
        retry: null,
        name: r'analysisTypesForCropProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tipos compatíveis com uma cultura.

  AnalysisTypesForCropProvider call(int cropId) =>
      AnalysisTypesForCropProvider._(argument: cropId, from: this);

  @override
  String toString() => r'analysisTypesForCropProvider';
}

/// Resolve um tipo por id (com aliases legados).

@ProviderFor(analysisTypeById)
const analysisTypeByIdProvider = AnalysisTypeByIdFamily._();

/// Resolve um tipo por id (com aliases legados).

final class AnalysisTypeByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalysisTypeModel>,
          AnalysisTypeModel,
          FutureOr<AnalysisTypeModel>
        >
    with
        $FutureModifier<AnalysisTypeModel>,
        $FutureProvider<AnalysisTypeModel> {
  /// Resolve um tipo por id (com aliases legados).
  const AnalysisTypeByIdProvider._({
    required AnalysisTypeByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'analysisTypeByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analysisTypeByIdHash();

  @override
  String toString() {
    return r'analysisTypeByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AnalysisTypeModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalysisTypeModel> create(Ref ref) {
    final argument = this.argument as String;
    return analysisTypeById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnalysisTypeByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analysisTypeByIdHash() => r'a023143e2df635d12ea285a7ac704349108963d0';

/// Resolve um tipo por id (com aliases legados).

final class AnalysisTypeByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AnalysisTypeModel>, String> {
  const AnalysisTypeByIdFamily._()
    : super(
        retry: null,
        name: r'analysisTypeByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolve um tipo por id (com aliases legados).

  AnalysisTypeByIdProvider call(String typeId) =>
      AnalysisTypeByIdProvider._(argument: typeId, from: this);

  @override
  String toString() => r'analysisTypeByIdProvider';
}
