import 'package:nutrinitro/src/core/constants/repository_includes.dart';
import 'package:nutrinitro/src/core/interfaces/api_result_interface.dart';
import 'package:nutrinitro/src/data/repositories/repositories_provider.dart';
import 'package:nutrinitro/src/data/services/services_provider.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/list/analysis_list_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_list_view_model.g.dart';

@riverpod
class AnalysesListViewModel extends _$AnalysesListViewModel {
  static const _perPage = 10;
  int _offset = 0;

  @override
  AnalysesListState build() {
    Future.microtask(() => fetchAnalyses(refresh: true));
    return const AnalysesListState();
  }

  Future<void> fetchAnalyses({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      state = state.copyWith(isLoading: true, hasMore: true, analyses: []);
    } else {
      state = state.copyWith(isLoading: true);
    }

    final repo = await ref.read(analysisRepositoryProvider.future);
    final result = await repo.allPaginated(
      offset: _offset,
      limit: _perPage,
      include: {AnalysisInclude.crop, AnalysisInclude.images},
    );

    switch (result) {
      case Success(value: final list):
        state = state.copyWith(
          isLoading: false,
          analyses: refresh ? list : [...state.analyses, ...list],
          hasMore: list.length == _perPage,
        );
      case Failure(:final error):
        print('Error fetching analyses: $error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    _offset += _perPage;

    final repo = await ref.read(analysisRepositoryProvider.future);
    final result = await repo.allPaginated(
      offset: _offset,
      limit: _perPage,
      include: {AnalysisInclude.crop, AnalysisInclude.images},
    );

    switch (result) {
      case Success(value: final list):
        state = state.copyWith(
          isLoadingMore: false,
          analyses: [...state.analyses, ...list],
          hasMore: list.length == _perPage,
        );
      case Failure(:final error):
        print('Error loading more analyses: $error');
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: error.toString(),
        );
    }
  }

  Future<bool> delete(int analysisId) async {
    final analysisRepo = await ref.read(analysisRepositoryProvider.future);
    final storageService = ref.read(storageServiceProvider);

    final result = await analysisRepo.delete(analysisId);

    switch (result) {
      case Success():
        await storageService.deleteAnalysisFiles(analysisId);

        state = state.copyWith(
          analyses: state.analyses.where((a) => a.id != analysisId).toList(),
        );
        return true;

      case Failure(:final error):
        print('Error deleting analysis: $error');
        state = state.copyWith(errorMessage: error.toString());
        return false;
    }
  }
}
