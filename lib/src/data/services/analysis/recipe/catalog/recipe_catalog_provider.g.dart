// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recipeCatalog)
const recipeCatalogProvider = RecipeCatalogProvider._();

final class RecipeCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeCatalog>,
          RecipeCatalog,
          FutureOr<RecipeCatalog>
        >
    with $FutureModifier<RecipeCatalog>, $FutureProvider<RecipeCatalog> {
  const RecipeCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeCatalogHash();

  @$internal
  @override
  $FutureProviderElement<RecipeCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecipeCatalog> create(Ref ref) {
    return recipeCatalog(ref);
  }
}

String _$recipeCatalogHash() => r'8ebccdd8d9e741a57d358c152d6211e157c37eb4';

@ProviderFor(cropHasRecipe)
const cropHasRecipeProvider = CropHasRecipeFamily._();

final class CropHasRecipeProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const CropHasRecipeProvider._({
    required CropHasRecipeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'cropHasRecipeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cropHasRecipeHash();

  @override
  String toString() {
    return r'cropHasRecipeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as int;
    return cropHasRecipe(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CropHasRecipeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cropHasRecipeHash() => r'bb4765a6fd559c5410bbcc1ad7187ed697c6d27f';

final class CropHasRecipeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, int> {
  const CropHasRecipeFamily._()
    : super(
        retry: null,
        name: r'cropHasRecipeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CropHasRecipeProvider call(int cropId) =>
      CropHasRecipeProvider._(argument: cropId, from: this);

  @override
  String toString() => r'cropHasRecipeProvider';
}

@ProviderFor(cropRegisteredAnalyses)
const cropRegisteredAnalysesProvider = CropRegisteredAnalysesFamily._();

final class CropRegisteredAnalysesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CropAnalysisOption>>,
          List<CropAnalysisOption>,
          FutureOr<List<CropAnalysisOption>>
        >
    with
        $FutureModifier<List<CropAnalysisOption>>,
        $FutureProvider<List<CropAnalysisOption>> {
  const CropRegisteredAnalysesProvider._({
    required CropRegisteredAnalysesFamily super.from,
    required ({int cropId, String? cropName}) super.argument,
  }) : super(
         retry: null,
         name: r'cropRegisteredAnalysesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cropRegisteredAnalysesHash();

  @override
  String toString() {
    return r'cropRegisteredAnalysesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<CropAnalysisOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CropAnalysisOption>> create(Ref ref) {
    final argument = this.argument as ({int cropId, String? cropName});
    return cropRegisteredAnalyses(
      ref,
      cropId: argument.cropId,
      cropName: argument.cropName,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CropRegisteredAnalysesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cropRegisteredAnalysesHash() =>
    r'ff01da392051dcce95a236ffcf2056ef17bc9477';

final class CropRegisteredAnalysesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CropAnalysisOption>>,
          ({int cropId, String? cropName})
        > {
  const CropRegisteredAnalysesFamily._()
    : super(
        retry: null,
        name: r'cropRegisteredAnalysesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CropRegisteredAnalysesProvider call({
    required int cropId,
    String? cropName,
  }) => CropRegisteredAnalysesProvider._(
    argument: (cropId: cropId, cropName: cropName),
    from: this,
  );

  @override
  String toString() => r'cropRegisteredAnalysesProvider';
}
