import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _uuid = const Uuid();

  Future<Directory> _analysisDirectory(int analysisId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'analyses', analysisId.toString()));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> saveImage({
    required int analysisId,
    required String sourcePath,
  }) async {
    final dir = await _analysisDirectory(analysisId);
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final fileName = '${_uuid.v4()}$ext';
    final destination = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  Future<void> deleteAnalysisFiles(int analysisId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'analyses', analysisId.toString()));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}