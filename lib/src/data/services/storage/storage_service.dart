import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _uuid = const Uuid();

  // ─── Analysis ──────────────────────────────────────────────────────────────

  Future<Directory> _analysisDirectory(int analysisId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'analyses', analysisId.toString()));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> saveImage({
    required int analysisId,
    required String sourcePath,
    String? preferredFileName,
    int? displayOrder,
  }) async {
    final dir = await _analysisDirectory(analysisId);
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final String fileName = _resolveFileName(
      preferredFileName: preferredFileName,
      displayOrder: displayOrder,
      extension: ext,
    );
    final destination = File(p.join(dir.path, fileName));
    if (await destination.exists()) {
      final stem = p.basenameWithoutExtension(fileName);
      final uniqueName =
          '${stem}_${displayOrder ?? 0}_${_uuid.v4().substring(0, 6)}$ext';
      final uniqueDest = File(p.join(dir.path, uniqueName));
      await File(sourcePath).copy(uniqueDest.path);
      return uniqueDest.path;
    }
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  Future<void> deleteAnalysisFiles(int analysisId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'analyses', analysisId.toString()));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  // ─── Drone ─────────────────────────────────────────────────────────────────

  Future<Directory> _missionDirectory(int missionId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'missions', missionId.toString()));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> saveDroneImage({
    required int missionId,
    required String sourcePath,
  }) async {
    final dir = await _missionDirectory(missionId);
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final fileName = '${_uuid.v4()}$ext';
    final destination = File(p.join(dir.path, fileName));
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  Future<void> deleteMissionFiles(int missionId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'missions', missionId.toString()));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _resolveFileName({
    String? preferredFileName,
    int? displayOrder,
    required String extension,
  }) {
    if (preferredFileName != null && preferredFileName.isNotEmpty) {
      final sanitized = _sanitizeFileName(preferredFileName);
      if (sanitized != null) return sanitized;
    }
    if (displayOrder != null) {
      return '${displayOrder.toString().padLeft(2, '0')}_${_uuid.v4()}$extension';
    }
    return '${_uuid.v4()}$extension';
  }

  String? _sanitizeFileName(String raw) {
    final base = p.basename(raw).trim();
    if (base.isEmpty) return null;
    final ext = p.extension(base);
    final stem = p.basenameWithoutExtension(base);
    final safeStem = stem.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (safeStem.isEmpty) return null;
    if (RegExp(
          r'^(P\d{1,2}|\d{2}-\d{2})',
          caseSensitive: false,
        ).hasMatch(safeStem) ||
        RegExp(r'P\d{1,2}', caseSensitive: false).hasMatch(safeStem)) {
      return '$safeStem${ext.isNotEmpty ? ext : '.jpg'}';
    }
    return '$safeStem${ext.isNotEmpty ? ext : '.jpg'}';
  }
}
