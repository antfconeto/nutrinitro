import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/utils/debug_analysis_exporter.dart';
import 'package:nutrinitro/src/core/utils/pdf_exporter.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_state.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_view_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/utils/image_angle_extractor.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_cancel_dialog.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_delete_dialog.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_details_body.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_selection_bottom_sheet.dart';

class AnalysisDetailsPage extends ConsumerStatefulWidget {
  final int analysisId;

  const AnalysisDetailsPage({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailsPage> createState() => _AnalysisDetailsPageState();
}

class _AnalysisDetailsPageState extends ConsumerState<AnalysisDetailsPage> {
  late final PageController _pageController;
  late final MapController _mapController;
  final ImageAngleExtractor _angleExtractor = ImageAngleExtractor();
  Timer? _activeImageDebounceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisDetailsViewModelProvider.notifier).init(widget.analysisId);
    });
  }

  @override
  void dispose() {
    _activeImageDebounceTimer?.cancel();
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onImageChanged(int index, List<ImageModel> images) {
    _activeImageDebounceTimer?.cancel();
    _activeImageDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      ref.read(analysisDetailsViewModelProvider.notifier).updateActiveImage(index);
      final image = images[index];
      if (image.hasLocation) {
        double currentZoom = 15.0;
        try {
          currentZoom = _mapController.camera.zoom;
        } catch (_) {}
        _mapController.move(
          LatLng(image.latitude!, image.longitude!),
          currentZoom,
        );
      }
    });
  }

  void _onMarkerTap(int index) {
    ref.read(analysisDetailsViewModelProvider.notifier).updateActiveImage(index);
  }

  void _showAnalysisSelection(AnalysisModel analysis) {
    AnalysisSelectionBottomSheet.show(
      context: context,
      ref: ref,
      analysis: analysis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisDetailsViewModelProvider);

    ref.listen<AnalysisDetailsState>(analysisDetailsViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: next.errorMessage!),
        );
        ref.read(analysisDetailsViewModelProvider.notifier).clearError();
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: next.successMessage!),
        );
        ref.read(analysisDetailsViewModelProvider.notifier).clearSuccess();
      }
    });

    return PopScope(
      canPop: !state.isAnalyzing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldCancel = await AnalysisCancelDialog.show(context) ?? false;
        if (shouldCancel && context.mounted) {
          ref.read(analysisDetailsViewModelProvider.notifier).cancelAnalysis();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.grayLight,
        appBar: AppBar(
          title: const Text('Detalhes da Análise'),
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          elevation: 0,
          actions: _buildAppBarActions(state),
        ),
        body: AnalysisDetailsBody(
          state: state,
          analysisId: widget.analysisId,
          pageController: _pageController,
          mapController: _mapController,
          angleExtractor: _angleExtractor,
          onStartAnalysis: () {
            final analysis = state.analysis;
            if (analysis != null) {
              _showAnalysisSelection(analysis);
            }
          },
          onImageChanged: _onImageChanged,
          onMarkerTap: _onMarkerTap,
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(AnalysisDetailsState state) {
    if (state.analysis == null || state.analysis!.isProcessing) {
      return const [];
    }

    final analysis = state.analysis!;

    return [
      if ((kDebugMode || Env.debug) && analysis.images.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.bug_report_outlined),
          tooltip: 'Exportar JSON (debug)',
          onPressed: () {
            DebugAnalysisExporter.showExportSheet(context, analysis);
          },
        ),
      if (analysis.isCompleted)
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'Exportar PDF',
          onPressed: () async {
            try {
              await PdfExporter.exportAnalysis(analysis, context);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao exportar PDF: $e'),
                  backgroundColor: AppColors.tomato,
                ),
              );
            }
          },
        ),
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Recarregar',
        onPressed: () =>
            ref.read(analysisDetailsViewModelProvider.notifier).fetchDetails(),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Deletar Análise',
        onPressed: () {
          AnalysisDeleteDialog.show(
            context: context,
            onDelete: () => ref
                .read(analysisDetailsViewModelProvider.notifier)
                .deleteAnalysis(),
          );
        },
      ),
    ];
  }
}
