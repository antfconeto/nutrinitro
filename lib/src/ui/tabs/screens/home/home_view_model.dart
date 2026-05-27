import 'dart:io';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/home/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() {
    Future.microtask(() => fetchCrops());
    return const HomeState();
  }

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
        print('Error fetching crops: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  void updateTitle(String value) {
    state = state.copyWith(title: value, clearError: true);
  }

  void updateDatetime(DateTime value) {
    state = state.copyWith(datetime: value, clearError: true);
  }

  void updateNotes(String? value) {
    state = state.copyWith(notes: value, clearError: true);
  }

  void selectCrop(CropModel crop) {
    state = state.copyWith(selectedCrop: crop, clearError: true);
  }

  Future<void> pickFromCamera() async {
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final file = await cameraService.pickFromCamera();
      if (file == null) return;

      final cropped = await ref
          .read(imageCropperServiceProvider)
          .crop(file.path);
      state = state.copyWith(
        images: [...state.images, cropped ?? file],
        clearError: true,
      );
    } catch (e) {
      print('Error picking image from camera: $e');
      state = state.copyWith(errorMessage: 'Erro ao capturar imagem: $e');
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final files = await cameraService.pickMultipleFromGallery();
      if (files.isEmpty) return;

      state = state.copyWith(
        images: [...state.images, ...files],
        clearError: true,
      );
    } catch (e) {
      print('Error picking images from gallery: $e');
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

      final updated = List<File>.from(state.images)..[index] = cropped;
      state = state.copyWith(images: updated);
    } catch (e) {
      print('Error cropping image: $e');
      state = state.copyWith(errorMessage: 'Erro ao recortar imagem: $e');
    }
  }

  void removeImage(int index) {
    final updated = List<File>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }

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
        images: const [],
      );

      switch (createResult) {
        case Failure(:final error):
          print('Error submitting analysis: $error');
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
            clearDatetime: true,
            clearNotes: true,
            clearSelectedCrop: true,
          );
      }
    } catch (e) {
      print('Error submitting analysis: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}
