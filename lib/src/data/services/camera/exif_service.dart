import 'dart:io';
import 'package:exif/exif.dart';
import 'package:nutrinitro/src/data/models/exif_metadata.dart';

class ExifService {
  Future<ExifMetadata> readMetadata(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) return ExifMetadata();

      final latitude = _parseLatLng(
        data['GPS GPSLatitude'],
        data['GPS GPSLatitudeRef'],
      );
      final longitude = _parseLatLng(
        data['GPS GPSLongitude'],
        data['GPS GPSLongitudeRef'],
        isLongitude: true,
      );
      final datetime = _parseDatetime(
        data['EXIF DateTimeOriginal'] ?? data['Image DateTime'],
      );

      return ExifMetadata(
        latitude: latitude,
        longitude: longitude,
        datetime: datetime,
      );
    } catch (_) {
      return ExifMetadata();
    }
  }

  double? _parseLatLng(
    IfdTag? coordTag,
    IfdTag? refTag, {
    bool isLongitude = false,
  }) {
    if (coordTag == null) return null;

    try {
      final values = coordTag.values as IfdRatios;
      final ratios = values.ratios;

      if (ratios.length < 3) return null;

      final degrees = ratios[0].numerator / ratios[0].denominator;
      final minutes = ratios[1].numerator / ratios[1].denominator;
      final seconds = ratios[2].numerator / ratios[2].denominator;

      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      // South and West are negative
      final ref = refTag?.printable ?? '';
      if (ref == 'S' || ref == 'W') decimal = -decimal;

      return decimal;
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDatetime(IfdTag? tag) {
    if (tag == null) return null;

    try {
      // EXIF datetime format: "YYYY:MM:DD HH:MM:SS"
      final raw = tag.printable.replaceFirst(':', '-').replaceFirst(':', '-');
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
