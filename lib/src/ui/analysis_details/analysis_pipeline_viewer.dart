import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_progress.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_stage_panel.dart';

class AnalysisPipelineViewer extends StatefulWidget {
  final AnalysisPipelineSnapshot? snapshot;
  final List<AnalysisStageUpdate> stages;
  final AnalysisStageUpdate? currentStage;

  const AnalysisPipelineViewer({
    super.key,
    required this.snapshot,
    required this.stages,
    this.currentStage,
  });

  @override
  State<AnalysisPipelineViewer> createState() => _AnalysisPipelineViewerState();
}

class _AnalysisPipelineViewerState extends State<AnalysisPipelineViewer>
    with TickerProviderStateMixin {
  Uint8List? _cachedImageBytes;
  int _cachedImageWidth = 1;
  int _cachedImageHeight = 1;
  late final AnimationController _fadeController;
  late final AnimationController _overlayController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _overlayAnimation = CurvedAnimation(parent: _overlayController, curve: Curves.easeOutCubic);
    _applySnapshot(widget.snapshot, animate: false);
  }

  @override
  void didUpdateWidget(AnalysisPipelineViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot != oldWidget.snapshot) {
      _applySnapshot(widget.snapshot, animate: true);
    }
  }

  void _applySnapshot(AnalysisPipelineSnapshot? snapshot, {required bool animate}) {
    if (snapshot == null) return;

    final bool imageChanged =
        snapshot.imageJpeg != null && snapshot.imageJpeg != _cachedImageBytes;
    if (snapshot.imageJpeg != null) {
      _cachedImageBytes = snapshot.imageJpeg;
    }
    if (snapshot.imageWidth > 0 && snapshot.imageHeight > 0) {
      _cachedImageWidth = snapshot.imageWidth;
      _cachedImageHeight = snapshot.imageHeight;
    }

    if (animate) {
      if (imageChanged) {
        _fadeController.forward(from: 0);
      }
      _overlayController.forward(from: 0);
    } else {
      _fadeController.value = 1;
      _overlayController.value = 1;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  String _stageLabel(String stageId) {
    return switch (stageId) {
      'original' => 'Imagem original',
      'bilateral' => 'Filtro bilateral (d=9)',
      'gamma' => 'Correção gamma (0.8)',
      'grid' => 'Grade de blocos 10×10',
      'exg' => 'Extração de verde (ExG > 0.15)',
      'features' => 'Estatísticas rgb28',
      'predict' => 'Predição MLP',
      'heatmap' => 'Mapa de clorofila (heatmap)',
      _ => stageId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final imageBytes = _cachedImageBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.green.withOpacity(0.25)),
            color: AppColors.navy.withOpacity(0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageBytes != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.green,
                      ),
                    ),
                  if (snapshot != null && imageBytes != null)
                    AnimatedBuilder(
                      animation: _overlayAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _PipelineOverlayPainter(
                            snapshot: snapshot,
                            imageWidth: _cachedImageWidth,
                            imageHeight: _cachedImageHeight,
                            progress: _overlayAnimation.value,
                          ),
                        );
                      },
                    ),
                  if (snapshot != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      right: 8,
                      child: _StageBadge(
                        label: _stageLabel(snapshot.stageId),
                        progress: snapshot.stageProgress,
                        blockCount: snapshot.vegetationBlockCount,
                      ),
                    ),
                  if (snapshot?.spadPrediction != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _SpadBadge(spad: snapshot!.spadPrediction!),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (snapshot?.rgb28Features != null) ...[
          const SizedBox(height: 10),
          _Rgb28FeaturePanel(
            features: snapshot!.rgb28Features!,
            animation: _overlayAnimation,
          ),
        ],
        const SizedBox(height: 10),
        AnalysisStagePanel(
          stages: widget.stages,
          currentStage: widget.currentStage,
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  final double progress;
  final int blockCount;

  const _StageBadge({
    required this.label,
    required this.progress,
    required this.blockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          if (blockCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$blockCount blocos vegetados selecionados',
              style: AppText.small.copyWith(color: Colors.white70, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpadBadge extends StatelessWidget {
  final double spad;

  const _SpadBadge({required this.spad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${spad.toStringAsFixed(1)} SPAD',
        style: AppText.small.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Rgb28FeaturePanel extends StatelessWidget {
  final List<double> features;
  final Animation<double> animation;

  const _Rgb28FeaturePanel({
    required this.features,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final labels = AnalysisPipelineSnapshot.rgb28Labels;
    final int count = features.length.clamp(0, labels.length);
    final double maxVal = features.isEmpty
        ? 1.0
        : features.reduce((a, b) => a > b ? a : b).clamp(0.01, 1.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features rgb28 → rede neural',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(count, (i) {
                    final double target = features[i] / maxVal;
                    final double heightFactor = (target * animation.value).clamp(0.0, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 52 * heightFactor,
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.35 + 0.45 * heightFactor),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'P50 · média · P75 · P90 para R, G, B, RG, RB, GB, RGB',
            style: AppText.small.copyWith(
              color: AppColors.grayMedium,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineOverlayPainter extends CustomPainter {
  final AnalysisPipelineSnapshot snapshot;
  final int imageWidth;
  final int imageHeight;
  final double progress;

  const _PipelineOverlayPainter({
    required this.snapshot,
    required this.imageWidth,
    required this.imageHeight,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshot.gridRows <= 0 || snapshot.gridCols <= 0) return;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final double blockW = snapshot.blockWidth * scaleX;
    final double blockH = snapshot.blockHeight * scaleY;

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final int maxGridRow = (snapshot.revealedGridRows * progress).ceil().clamp(0, snapshot.gridRows);

    for (int r = 0; r <= maxGridRow; r++) {
      final double y = r * blockH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int c = 0; c <= snapshot.gridCols; c++) {
      final double x = c * blockW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (snapshot.vegetationBlocks == null) return;

    final int maxExgRow =
        (snapshot.revealedVegetationRows * progress).ceil().clamp(0, snapshot.gridRows);
    final Paint vegPaint = Paint()..style = PaintingStyle.fill;
    final Paint selectedPaint = Paint()
      ..color = AppColors.green.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int r = 0; r < maxExgRow; r++) {
      for (int c = 0; c < snapshot.gridCols; c++) {
        final int idx = r * snapshot.gridCols + c;
        if (idx >= snapshot.vegetationBlocks!.length) continue;

        final bool isVeg = snapshot.vegetationBlocks![idx];
        final Rect rect = Rect.fromLTWH(c * blockW, r * blockH, blockW, blockH);

        if (snapshot.stageId == 'exg' || snapshot.stageId == 'features' || snapshot.stageId == 'predict') {
          if (isVeg) {
            vegPaint.color = AppColors.green.withOpacity(0.28 * progress);
            canvas.drawRect(rect, vegPaint);
            canvas.drawRect(rect, selectedPaint);
          } else {
            vegPaint.color = Colors.red.withOpacity(0.12 * progress);
            canvas.drawRect(rect, vegPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PipelineOverlayPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.progress != progress ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
