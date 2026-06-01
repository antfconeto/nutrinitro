import 'dart:io';
import 'package:exif/exif.dart';
import 'package:nutrinitro/src/data/models/exif_metadata.dart';

class ExifService {
  Future<ExifMetadata> readMetadata(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('ExifService: File does not exist at $imagePath');
        return ExifMetadata();
      }

      final size = await file.length();
      final data = await readExifFromFile(file);

      print('=== EXIF METADATA DEBBUGGER ===');
      print('Image Path: $imagePath');
      print('File Size: $size bytes');
      print('Total EXIF Keys Found: ${data.length}');
      print('All Keys: ${data.keys.toList()}');
      
      final latTag = data['GPS GPSLatitude'];
      final latRefTag = data['GPS GPSLatitudeRef'];
      final lngTag = data['GPS GPSLongitude'];
      final lngRefTag = data['GPS GPSLongitudeRef'];
      
      print('GPSLatitude Tag: $latTag');
      print('GPSLatitudeRef Tag: $latRefTag');
      print('GPSLongitude Tag: $lngTag');
      print('GPSLongitudeRef Tag: $lngRefTag');
      print('================================');

      if (data.isEmpty) return ExifMetadata();

      final latitude = _parseLatLng(latTag, latRefTag);
      final longitude = _parseLatLng(lngTag, lngRefTag);
      final datetime = _parseDatetime(
        data['EXIF DateTimeOriginal'] ?? data['Image DateTime'],
      );

      print('ExifService Parsed: Latitude=$latitude, Longitude=$longitude, Datetime=$datetime');

      return ExifMetadata(
        latitude: latitude,
        longitude: longitude,
        datetime: datetime,
      );
    } catch (e) {
      print('Error in readMetadata: $e');
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
      List<Ratio>? ratios;
      final values = coordTag.values;
      if (values is IfdRatios) {
        ratios = values.ratios;
      }

      if (ratios != null && ratios.length >= 3) {
        final degrees = ratios[0].numerator / ratios[0].denominator;
        final minutes = ratios[1].numerator / ratios[1].denominator;
        final seconds = ratios[2].numerator / ratios[2].denominator;

        double decimal = degrees + (minutes / 60) + (seconds / 3600);

        final ref = (refTag?.printable ?? '').toUpperCase().trim();
        if (ref.startsWith('S') || ref.startsWith('W')) decimal = -decimal;

        return decimal;
      }

      // Fallback: parse printable string e.g. "[7, 2, 51851/10000]"
      final clean = coordTag.printable.replaceAll('[', '').replaceAll(']', '');
      final parts = clean.split(',');
      if (parts.length >= 3) {
        double parsePart(String p) {
          final trimmed = p.trim();
          if (trimmed.contains('/')) {
            final subParts = trimmed.split('/');
            final numVal = double.tryParse(subParts[0]) ?? 0.0;
            final denVal = double.tryParse(subParts[1]) ?? 1.0;
            return numVal / denVal;
          }
          return double.tryParse(trimmed) ?? 0.0;
        }
        final degrees = parsePart(parts[0]);
        final minutes = parsePart(parts[1]);
        final seconds = parsePart(parts[2]);
        
        double decimal = degrees + (minutes / 60) + (seconds / 3600);
        
        final ref = (refTag?.printable ?? '').toUpperCase().trim();
        if (ref.startsWith('S') || ref.startsWith('W')) decimal = -decimal;
        
        return decimal;
      }

      return null;
    } catch (e) {
      print('Error parsing LatLng: $e');
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
