import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/data/models/analysis/image_model.dart';
import 'package:nutrinitro/src/data/models/local_image_pick.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/create/analysis_create_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_create_view_model.g.dart';

@Riverpod(keepAlive: true)
class AnalysisCreateViewModel extends _$AnalysisCreateViewModel {
  @override
  AnalysisCreateState build() {
    Future.microtask(() => fetchCrops());
    return const AnalysisCreateState();
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> fetchCrops() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cropRepository = await ref.read(cropRepositoryProvider.future);
    final result = await cropRepository.all();

    switch (result) {
      case Success(value: final crops):
        state = state.copyWith(
          isLoading: false,
          crops: crops,
          selectedCrop: null,
        );
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  // ─── Form ──────────────────────────────────────────────────────────────────

  void updateTitle(String value) =>
      state = state.copyWith(title: value, clearError: true);

  void updateDatetime(DateTime value) =>
      state = state.copyWith(datetime: value, clearError: true);

  void updateNotes(String? value) =>
      state = state.copyWith(notes: value, clearError: true);

  void selectCrop(CropModel crop) =>
      state = state.copyWith(selectedCrop: crop, clearError: true);

  Future<void> initFromPreset(DroneAnalysisPreset preset) async {
    state = state.copyWith(
      title: preset.title,
      datetime: preset.datetime,
      notes: preset.notes,
      images: const [],
      imageSourceNames: const [],
      submitted: false,
      clearError: true,
    );
    if (preset.images.isNotEmpty) {
      final picks = preset.images.asMap().entries.map((e) {
        final name = e.key < preset.sourceNames.length
            ? preset.sourceNames[e.key]
            : null;
        return LocalImagePick(e.value, name);
      }).toList();
      await _appendImages(picks);
    }
  }

  // ─── Images ────────────────────────────────────────────────────────────────

  Future<void> _appendImages(List<LocalImagePick> picks) async {
    if (picks.isEmpty) return;

    final stagingDir = Directory(
      p.join((await getTemporaryDirectory()).path, 'analysis_picks'),
    );
    if (!await stagingDir.exists()) await stagingDir.create(recursive: true);

    final stagedFiles = <File>[];
    final stagedNames = <String?>[];
    final baseIndex = state.images.length;

    for (int i = 0; i < picks.length; i++) {
      final pick = picks[i];
      final ext = p.extension(pick.file.path).isNotEmpty
          ? p.extension(pick.file.path)
          : '.jpg';
      final name = _safePickName(pick.sourceName, baseIndex + i, ext);
      final dest = File(p.join(stagingDir.path, name));

      try {
        if (await pick.file.exists()) {
          await pick.file.copy(dest.path);
        } else if (pick.xFile != null) {
          await dest.writeAsBytes(await pick.xFile!.readAsBytes());
        } else {
          continue;
        }
      } catch (_) {
        continue;
      }

      stagedFiles.add(dest);
      stagedNames.add(pick.sourceName);
    }

    if (!ref.mounted || stagedFiles.isEmpty) return;

    state = state.copyWith(
      images: [...state.images, ...stagedFiles],
      imageSourceNames: [...state.imageSourceNames, ...stagedNames],
      clearError: true,
    );
  }

  String _safePickName(String? sourceName, int index, String ext) {
    if (sourceName != null && sourceName.isNotEmpty) {
      final base = p.basename(sourceName).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      if (base.isNotEmpty) return '${DateTime.now().millisecondsSinceEpoch}_$base';
    }
    return '${DateTime.now().millisecondsSinceEpoch}_pick_$index$ext';
  }

  Future<void> pickFromCamera() async {
    try {
      if (Platform.isAndroid) await Permission.accessMediaLocation.request();

      final file = await ref.read(cameraServiceProvider).pickFromCamera();
      if (file == null) return;

      final cropped = await ref
          .read(imageCropperServiceProvider)
          .crop(file.path);
      await _appendImages([LocalImagePick(cropped ?? file)]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao capturar imagem: $e');
    }
  }

  Future<void> pickFromGallery() async {
    try {
      if (Platform.isAndroid) await Permission.accessMediaLocation.request();

      final picks = await ref
          .read(cameraServiceProvider)
          .pickMultipleFromGallery();
      if (picks.isEmpty) return;

      await _appendImages(picks);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao selecionar imagens: $e');
    }
  }

  Future<void> cropImage(int index) async {
    try {
      final file = state.images[index];
      final cropped = await ref
          .read(imageCropperServiceProvider)
          .crop(file.path);
      if (cropped == null) return;

      final updatedImages = List<File>.from(state.images)..[index] = cropped;
      state = state.copyWith(images: updatedImages);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao recortar imagem: $e');
    }
  }

  void removeImage(int index) {
    final updatedImages = List<File>.from(state.images)..removeAt(index);
    final updatedNames = List<String?>.from(state.imageSourceNames);
    if (index < updatedNames.length) updatedNames.removeAt(index);
    state = state.copyWith(
      images: updatedImages,
      imageSourceNames: updatedNames,
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    state = state.copyWith(submitted: true);
    if (!state.isFormValid) return;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final exifService = ref.read(exifServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final analysisRepo = await ref.read(analysisRepositoryProvider.future);
      final imageRepo = await ref.read(imageRepositoryProvider.future);

      final createResult = await analysisRepo.create(
        title: state.title,
        datetime: state.datetime!,
        notes: state.notes,
        cropId: state.selectedCrop!.id!,
        analysisType: 'agronomic',
        images: const [],
      );

      switch (createResult) {
        case Failure(:final error):
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
          );
          return;

        case Success(value: final analysis):
          final analysisId = analysis.id!;

          for (int i = 0; i < state.images.length; i++) {
            final file = state.images[i];
            final metadata = await exifService.readMetadata(file.path);
            final permanentPath = await storageService.saveImage(
              analysisId: analysisId,
              sourcePath: file.path,
              preferredFileName: state.sourceNameAt(i),
              displayOrder: i,
            );

            await imageRepo.create(
              ImageModel(
                analysisId: analysisId,
                originalPath: permanentPath,
                displayOrder: i,
                latitude: metadata.latitude,
                longitude: metadata.longitude,
                datetime: metadata.datetime,
              ),
            );
          }

          state = state.copyWith(
            isSubmitting: false,
            successMessage: 'Análise criada com sucesso!',
            submitted: false,
            title: '',
            images: const [],
            imageSourceNames: const [],
            clearDatetime: true,
            clearNotes: true,
            clearSelectedCrop: true,
          );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}
