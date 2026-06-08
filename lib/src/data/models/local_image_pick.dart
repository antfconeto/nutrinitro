import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Imagem selecionada na galeria/câmera com nome original quando disponível.
class LocalImagePick {
  final File file;
  final String? sourceName;
  final XFile? xFile;

  const LocalImagePick(this.file, [this.sourceName, this.xFile]);
}
