import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

part 'image_selection_event.dart';
part 'image_selection_state.dart';

class ImageSelectionBloc extends Bloc<ImageSelectionEvent, ImageSelectionState> {
  final ImagePicker _imagePicker;

  ImageSelectionBloc({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker(),
        super(const ImageSelectionInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<ClearImageEvent>(_onClearImage);
  }

  Future<void> _onPickImage(
    PickImageEvent event,
    Emitter<ImageSelectionState> emit,
  ) async {
    emit(ImageSelectionLoading(state.imagePath, state.imageBytes));
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: event.source,
        imageQuality: 85, 
      );
      if (pickedFile != null) {
        final Uint8List bytes = await pickedFile.readAsBytes();
        emit(ImageSelectionSuccess(
          imagePath: pickedFile.path,
          imageBytes: bytes,
        ));
      } else {
        // If selection was cancelled, keep current image but stop loading
        if (state.imagePath != null && state.imageBytes != null) {
          emit(ImageSelectionSuccess(
            imagePath: state.imagePath!,
            imageBytes: state.imageBytes!,
          ));
        } else {
          emit(const ImageSelectionInitial());
        }
      }
    } catch (e) {
      emit(ImageSelectionFailure(
        imagePath: state.imagePath,
        imageBytes: state.imageBytes,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearImage(
    ClearImageEvent event,
    Emitter<ImageSelectionState> emit,
  ) {
    emit(const ImageSelectionInitial());
  }
}
