// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repositories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cropRepository)
const cropRepositoryProvider = CropRepositoryProvider._();

final class CropRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CropRepository>,
          CropRepository,
          FutureOr<CropRepository>
        >
    with $FutureModifier<CropRepository>, $FutureProvider<CropRepository> {
  const CropRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cropRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cropRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CropRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CropRepository> create(Ref ref) {
    return cropRepository(ref);
  }
}

String _$cropRepositoryHash() => r'f61c0f0201419875af2ab1ba37e78b6e6574bb20';

@ProviderFor(imageRepository)
const imageRepositoryProvider = ImageRepositoryProvider._();

final class ImageRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImageRepository>,
          ImageRepository,
          FutureOr<ImageRepository>
        >
    with $FutureModifier<ImageRepository>, $FutureProvider<ImageRepository> {
  const ImageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<ImageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImageRepository> create(Ref ref) {
    return imageRepository(ref);
  }
}

String _$imageRepositoryHash() => r'e434baab9551fd6f5340cf7a2f22255815e182ef';

@ProviderFor(analysisRepository)
const analysisRepositoryProvider = AnalysisRepositoryProvider._();

final class AnalysisRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalysisRepository>,
          AnalysisRepository,
          FutureOr<AnalysisRepository>
        >
    with
        $FutureModifier<AnalysisRepository>,
        $FutureProvider<AnalysisRepository> {
  const AnalysisRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<AnalysisRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalysisRepository> create(Ref ref) {
    return analysisRepository(ref);
  }
}

String _$analysisRepositoryHash() =>
    r'1181744cb1b0290294027c3eecd45fc462699b77';
