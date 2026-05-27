import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/home/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() {
    Future.microtask(() => fetchCrops());

    return const HomeState();
  }

  Future<void> fetchCrops() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    final cropRepository = await ref.read(cropRepositoryProvider.future);
    final result = await cropRepository.all();

    switch (result) {
      case Success(value: final crops):
        state = state.copyWith(
          isLoading: false,
          crops: crops,
          selectedCrop: crops.isNotEmpty ? crops.first : null,
        );
      case Failure(:final error):
        print('Fetch crops error: ${error.toString()}');
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

      state = state.copyWith(
        images: [...state.images, file],
        clearError: true,
      );
    } catch (e) {
      print('Camera pick error: $e');
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
      print('Gallery pick error: $e');
      state = state.copyWith(errorMessage: 'Erro ao selecionar imagens: $e');
    }
  }

  void removeImage(int index) {
    final updated = List<File>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }

  Future<void> submit() async {
    if (!state.isFormValid) {
      print('Form validation failed');
      state = state.copyWith(
        errorMessage:
            'Preencha todos os campos obrigatórios e adicione pelo menos uma imagem.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final exifService = ref.read(exifServiceProvider);
      final imageModels = <ImageModel>[];

      for (int i = 0; i < state.images.length; i++) {
        final file = state.images[i];
        final metadata = await exifService.readMetadata(file.path);

        imageModels.add(
          ImageModel(
            analysisId: 0,
            originalPath: file.path,
            displayOrder: i,
            latitude: metadata.latitude,
            longitude: metadata.longitude,
            datetime: metadata.datetime,
          ),
        );
      }

      final analysisRepository = await ref.read(
        analysisRepositoryProvider.future,
      );
      final result = await analysisRepository.create(
        title: state.title,
        datetime: state.datetime!,
        notes: state.notes,
        cropId: state.selectedCrop!.id!,
        images: imageModels,
      );

      switch (result) {
        case Success():
          state = state.copyWith(
            isSubmitting: false,
            successMessage: 'Análise criada com sucesso!',
            title: '',
            images: const [],
            clearDatetime: true,
            clearNotes: true,
            clearSelectedCrop: true,
          );
        case Failure(:final error):
          print('Create analysis error: ${error.toString()}');
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
          );
      }
    } catch (e) {
      print('Unexpected submit error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}
