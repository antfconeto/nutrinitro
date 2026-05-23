part of 'image_selection_bloc.dart';

@immutable
sealed class ImageSelectionState {
  final String? imagePath;
  final Uint8List? imageBytes;
  const ImageSelectionState(this.imagePath, this.imageBytes);
}

final class ImageSelectionInitial extends ImageSelectionState {
  const ImageSelectionInitial() : super(null, null);
}

final class ImageSelectionLoading extends ImageSelectionState {
  const ImageSelectionLoading(super.imagePath, super.imageBytes);
}

final class ImageSelectionSuccess extends ImageSelectionState {
  const ImageSelectionSuccess({required String imagePath, required Uint8List imageBytes})
      : super(imagePath, imageBytes);
}

final class ImageSelectionFailure extends ImageSelectionState {
  final String errorMessage;
  const ImageSelectionFailure({
    required String? imagePath,
    required Uint8List? imageBytes,
    required this.errorMessage,
  }) : super(imagePath, imageBytes);
}
