import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/core/constants/repository_includes.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/data/repositories/crop/crop_repository.dart';
import 'package:nutrinitro/src/data/repositories/image/image_repository.dart';
import 'package:sqflite/sqflite.dart';

class AnalysisRepository {
  final Database _db;
  final ImageRepository _imageRepository;
  final CropRepository _cropRepository;

  AnalysisRepository(this._db, this._imageRepository, this._cropRepository);

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<Result<List<AnalysisModel>>> all({
    Set<AnalysisInclude> include = const {},
  }) async {
    try {
      final rows = await _db.query('analyses', orderBy: 'id DESC');
      final analyses = <AnalysisModel>[];
      for (final row in rows) {
        analyses.add(await _buildAnalysis(row, include: include));
      }
      return Success(analyses);
    } catch (e) {
      return Failure(Exception('Error fetching analyses: $e'));
    }
  }

  /// Paginated fetch with optional filters applied at the database level.
  ///
  /// [statusFilter] — filters by one or more statuses (OR logic)
  /// [cropFilter]   — filters by one or more crop ids (OR logic)
  /// [searchQuery]  — searches title and crop name (LIKE, case-insensitive)
  /// [sortOrder]    — 'datetime DESC' | 'datetime ASC' | 'title ASC' | 'title DESC'
  Future<Result<List<AnalysisModel>>> allPaginated({
    required int offset,
    required int limit,
    Set<AnalysisInclude> include = const {},
    Set<AnalysisStatus> statusFilter = const {},
    Set<int> cropFilter = const {},
    String searchQuery = '',
    String sortOrder = 'datetime DESC',
  }) async {
    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Status filter
      if (statusFilter.isNotEmpty) {
        final placeholders = statusFilter.map((_) => '?').join(', ');
        whereClauses.add('a.status IN ($placeholders)');
        whereArgs.addAll(statusFilter.map((s) => s.name));
      }

      // Crop filter
      if (cropFilter.isNotEmpty) {
        final placeholders = cropFilter.map((_) => '?').join(', ');
        whereClauses.add('a.crop_id IN ($placeholders)');
        whereArgs.addAll(cropFilter);
      }

      // Search — title OR crop name
      if (searchQuery.isNotEmpty) {
        whereClauses.add('(a.title LIKE ? OR c.name LIKE ?)');
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }

      final whereString = whereClauses.isNotEmpty
          ? 'WHERE ${whereClauses.join(' AND ')}'
          : '';

      final sql =
          '''
        SELECT a.*
        FROM analyses a
        LEFT JOIN crops c ON a.crop_id = c.id
        $whereString
        ORDER BY a.$sortOrder
        LIMIT ? OFFSET ?
      ''';

      whereArgs.addAll([limit, offset]);

      final rows = await _db.rawQuery(sql, whereArgs);

      final analyses = <AnalysisModel>[];
      for (final row in rows) {
        analyses.add(await _buildAnalysis(row, include: include));
      }

      return Success(analyses);
    } catch (e) {
      return Failure(Exception('Error fetching analyses: $e'));
    }
  }

  Future<Result<AnalysisModel>> find(
    int id, {
    Set<AnalysisInclude> include = const {},
  }) async {
    try {
      final rows = await _db.query(
        'analyses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rows.isEmpty) return Failure(Exception('Analysis not found'));
      return Success(await _buildAnalysis(rows.first, include: include));
    } catch (e) {
      return Failure(Exception('Error fetching analysis: $e'));
    }
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  Future<Result<AnalysisModel>> create({
    required String title,
    required DateTime datetime,
    required int cropId,
    required String analysisType,
    required List<ImageModel> images,
    String? notes,
  }) async {
    try {
      final analysisId = await _db.insert('analyses', {
        'title': title,
        'datetime': datetime.toIso8601String(),
        'notes': notes,
        'crop_id': cropId,
        'analysis_type': analysisType,
        'status': AnalysisStatus.pending.name,
      });

      for (final image in images) {
        await _db.insert(
          'images',
          image.copyWith(analysisId: analysisId).toMap()..remove('id'),
        );
      }

      return find(
        analysisId,
        include: {AnalysisInclude.crop, AnalysisInclude.images},
      );
    } catch (e) {
      return Failure(Exception('Error creating analysis: $e'));
    }
  }

  // ─── Update ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> update(
    int analysisId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _db.update(
        'analyses',
        fields,
        where: 'id = ?',
        whereArgs: [analysisId],
      );
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error updating analysis: $e'));
    }
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<Result<Nil>> delete(int analysisId) async {
    try {
      await _imageRepository.deleteBy('analysis_id', analysisId);
      await _db.delete('analyses', where: 'id = ?', whereArgs: [analysisId]);
      return successOfNil();
    } catch (e) {
      return Failure(Exception('Error deleting analysis: $e'));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<AnalysisModel> _buildAnalysis(
    Map<String, dynamic> row, {
    Set<AnalysisInclude> include = const {},
  }) async {
    CropModel? crop;
    List<ImageModel> images = [];

    if (include.contains(AnalysisInclude.crop)) {
      final result = await _cropRepository.find(row['crop_id'] as int);
      if (result case Success(:final value)) crop = value;
    }

    if (include.contains(AnalysisInclude.images)) {
      final result = await _imageRepository.findBy('analysis_id', row['id']);
      if (result case Success(:final value)) images = value;
    }

    return AnalysisModel.fromMap(row, crop: crop, images: images);
  }
}
