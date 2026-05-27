// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analysisService)
const analysisServiceProvider = AnalysisServiceProvider._();

final class AnalysisServiceProvider
    extends
        $FunctionalProvider<AnalysisService, AnalysisService, AnalysisService>
    with $Provider<AnalysisService> {
  const AnalysisServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisServiceHash();

  @$internal
  @override
  $ProviderElement<AnalysisService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalysisService create(Ref ref) {
    return analysisService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalysisService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalysisService>(value),
    );
  }
}

String _$analysisServiceHash() => r'3f10b61671cdb91b786e1ff0ce77e565e959e796';

@ProviderFor(exifService)
const exifServiceProvider = ExifServiceProvider._();

final class ExifServiceProvider
    extends $FunctionalProvider<ExifService, ExifService, ExifService>
    with $Provider<ExifService> {
  const ExifServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exifServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exifServiceHash();

  @$internal
  @override
  $ProviderElement<ExifService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExifService create(Ref ref) {
    return exifService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExifService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExifService>(value),
    );
  }
}

String _$exifServiceHash() => r'572b1e863beb6e524f29b0f0db1f3560e619da27';

@ProviderFor(cameraService)
const cameraServiceProvider = CameraServiceProvider._();

final class CameraServiceProvider
    extends $FunctionalProvider<CameraService, CameraService, CameraService>
    with $Provider<CameraService> {
  const CameraServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraServiceHash();

  @$internal
  @override
  $ProviderElement<CameraService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraService create(Ref ref) {
    return cameraService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraService>(value),
    );
  }
}

String _$cameraServiceHash() => r'232bf2cb718221e8f2cb30cc97dd61432f1b8080';

@ProviderFor(imageCropperService)
const imageCropperServiceProvider = ImageCropperServiceProvider._();

final class ImageCropperServiceProvider
    extends
        $FunctionalProvider<
          ImageCropperService,
          ImageCropperService,
          ImageCropperService
        >
    with $Provider<ImageCropperService> {
  const ImageCropperServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCropperServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCropperServiceHash();

  @$internal
  @override
  $ProviderElement<ImageCropperService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageCropperService create(Ref ref) {
    return imageCropperService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCropperService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCropperService>(value),
    );
  }
}

String _$imageCropperServiceHash() =>
    r'c31b00fcb7813ca6bb6eb0aa1720f9ffdf03e2e0';

@ProviderFor(storageService)
const storageServiceProvider = StorageServiceProvider._();

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  const StorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'a6d23bc030486b6d1106efa40d3a7733b6bf906f';
