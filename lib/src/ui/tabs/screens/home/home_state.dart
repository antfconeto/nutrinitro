import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  final String title;
  final DateTime? datetime;
  final String? notes;
  final List<CropModel> crops;
  final CropModel? selectedCrop;
  final List<File> images;

  const HomeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.title = '',
    this.datetime,
    this.notes,
    this.crops = const [],
    this.selectedCrop,
    this.images = const [],
  });

  bool get isFormValid =>
      title.isNotEmpty && datetime != null && selectedCrop != null && images.isNotEmpty;

  HomeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    String? title,
    DateTime? datetime,
    String? notes,
    List<CropModel>? crops,
    CropModel? selectedCrop,
    List<File>? images,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearDatetime = false,
    bool clearNotes = false,
    bool clearSelectedCrop = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      title: title ?? this.title,
      datetime: clearDatetime ? null : (datetime ?? this.datetime),
      notes: clearNotes ? null : (notes ?? this.notes),
      crops: crops ?? this.crops,
      selectedCrop: clearSelectedCrop ? null : (selectedCrop ?? this.selectedCrop),
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
        title,
        datetime,
        notes,
        crops,
        selectedCrop,
        images,
      ];
}