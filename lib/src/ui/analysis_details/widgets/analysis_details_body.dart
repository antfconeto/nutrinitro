import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_state.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_view_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/utils/image_angle_extractor.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_header_card.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_image_gallery_section.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_map_card.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_notes_card.dart';

class AnalysisDetailsBody extends ConsumerWidget {
  final AnalysisDetailsState state;
  final int analysisId;
  final PageController pageController;
  final MapController mapController;
  final ImageAngleExtractor angleExtractor;
  final VoidCallback onStartAnalysis;
  final void Function(int index, List<ImageModel> images) onImageChanged;
  final ValueChanged<int> onMarkerTap;

  const AnalysisDetailsBody({
    super.key,
    required this.state,
    required this.analysisId,
    required this.pageController,
    required this.mapController,
    required this.angleExtractor,
    required this.onStartAnalysis,
    required this.onImageChanged,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final analysis = state.analysis;
    if (analysis == null) {
      return _ErrorState(
        errorMessage: state.errorMessage,
        onRetry: () => ref
            .read(analysisDetailsViewModelProvider.notifier)
            .init(analysisId),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalysisHeaderCard(
            analysis: analysis,
            isAnalyzing: state.isAnalyzing,
            onStartAnalysis: onStartAnalysis,
          ),
          if (analysis.notes != null && analysis.notes!.trim().isNotEmpty)
            AnalysisNotesCard(notes: analysis.notes!),
          AnalysisMapCard(
            analysis: analysis,
            activeIndex: state.activeImageIndex,
            mapController: mapController,
            pageController: pageController,
            angleExtractor: angleExtractor,
            onMarkerTap: onMarkerTap,
          ),
          AnalysisImageGallerySection(
            analysis: analysis,
            activeIndex: state.activeImageIndex,
            pageController: pageController,
            onImageChanged: (index) => onImageChanged(index, analysis.images),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.tomato,
            ),
            const SizedBox(height: 16),
            Text(
              'Falha ao carregar detalhes',
              style: AppText.large.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Ocorreu um erro desconhecido.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.grayMedium),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.replay),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
