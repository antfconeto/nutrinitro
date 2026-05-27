import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';

class ImageCropperService {
  Future<File?> crop(String imagePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagem',
          toolbarColor: AppColors.green,
          toolbarWidgetColor: AppColors.white,
          activeControlsWidgetColor: AppColors.green,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Recortar imagem',
          cancelButtonTitle: 'Cancelar',
          doneButtonTitle: 'Concluir',
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }
}