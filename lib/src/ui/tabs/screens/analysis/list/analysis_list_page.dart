import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/list/analysis_list_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/list/analysis_list_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class AnalysesListPage extends ConsumerStatefulWidget {
  const AnalysesListPage({super.key});

  @override
  ConsumerState<AnalysesListPage> createState() => _AnalysesListPageState();
}

class _AnalysesListPageState extends ConsumerState<AnalysesListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= max * 0.9) {
      ref.read(analysesListViewModelProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AnalysisModel analysis,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.tomato.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.tomato,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Excluir análise?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        content: Text(
          'A análise "${analysis.title}" e todas as suas imagens serão excluídas permanentemente.',
          style: AppText.body.copyWith(color: AppColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancelar',
              style: AppText.medium.copyWith(color: AppColors.grayMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Excluir',
              style: AppText.medium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(analysesListViewModelProvider.notifier)
        .delete(analysis.id!);

    if (!context.mounted) return;

    showTopSnackBar(
      Overlay.of(context),
      success
          ? CustomSnackBar.success(message: 'Análise excluída com sucesso.')
          : CustomSnackBar.error(message: 'Erro ao excluir análise.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysesListViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Análises'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () => ref
              .read(analysesListViewModelProvider.notifier)
              .fetchAnalyses(refresh: true),
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalysesListState state) {
    if (state.isLoading && state.analyses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (state.analyses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.analyses.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.analyses.length) {
          return _buildLoadingMore();
        }
        return _buildCard(context, state.analyses[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 72,
                color: AppColors.grayMedium.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma análise ainda',
                style: AppText.large.copyWith(color: AppColors.grayMedium),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie sua primeira análise na aba Início.',
                style: AppText.body.copyWith(color: AppColors.grayMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, AnalysisModel analysis) {
    return Dismissible(
      key: ValueKey(analysis.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(context, analysis);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.tomato,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 28,
        ),
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            '/analysis_details',
            arguments: analysis.id,
          ),
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.green.withOpacity(0.06),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildPreview(analysis),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.title,
                        style: AppText.medium.copyWith(
                          fontSize: 15,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.grayMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy  HH:mm').format(analysis.datetime),
                              style: AppText.small.copyWith(
                                color: AppColors.grayMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (analysis.crop != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Image.asset(
                              analysis.crop!.icon,
                              width: 16,
                              height: 16,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.grass,
                                size: 14,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                analysis.crop!.name,
                                style: AppText.small.copyWith(
                                  color: AppColors.grayMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(analysis.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(AnalysisModel analysis) {
    final preview = analysis.previewImage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.grayLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: preview != null
                ? Image.file(
                    File(preview.originalPath),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.photo_outlined,
                        color: AppColors.grayMedium,
                        size: 28,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: AppColors.grayMedium,
                      size: 28,
                    ),
                  ),
          ),
        ),
        if (analysis.crop != null)
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    analysis.crop!.icon,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.grass,
                      size: 14,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(AnalysisStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Carregando mais...',
              style: AppText.small.copyWith(color: AppColors.grayMedium),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.pending:
        return AppColors.orangeLight;
      case AnalysisStatus.processing:
        return AppColors.orange;
      case AnalysisStatus.completed:
        return AppColors.green;
      case AnalysisStatus.error:
        return AppColors.tomato;
    }
  }
}
