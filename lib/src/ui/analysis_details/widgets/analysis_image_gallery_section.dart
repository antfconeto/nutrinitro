import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/analysis_image_results_panel.dart';
import 'package:nutrinitro/src/ui/analysis_details/widgets/full_screen_image_page.dart';

class AnalysisImageGallerySection extends StatefulWidget {
  final AnalysisModel analysis;
  final int activeIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;

  const AnalysisImageGallerySection({
    super.key,
    required this.analysis,
    required this.activeIndex,
    required this.pageController,
    required this.onImageChanged,
  });

  @override
  State<AnalysisImageGallerySection> createState() =>
      _AnalysisImageGallerySectionState();
}

class _AnalysisImageGallerySectionState extends State<AnalysisImageGallerySection> {
  bool _showAnalyzedOverlay = true;

  @override
  Widget build(BuildContext context) {
    if (widget.analysis.images.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: AppColors.grayMedium.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma imagem vinculada a esta análise.',
                style: AppText.body.copyWith(color: AppColors.grayMedium),
              ),
            ],
          ),
        ),
      );
    }

    final activeImage = widget.analysis.images[widget.activeIndex];
    Map<String, dynamic> resultJson = {};
    if (activeImage.result != null) {
      try {
        resultJson = jsonDecode(activeImage.result!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Imagens e Resultados',
            style: AppText.large.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: widget.pageController,
                        itemCount: widget.analysis.images.length,
                        onPageChanged: (index) =>
                            widget.onImageChanged(index),
                        itemBuilder: (context, index) =>
                            _ImagePageItem(
                          image: widget.analysis.images[index],
                          showOverlay: _showAnalyzedOverlay,
                          allImages: widget.analysis.images,
                          index: index,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Imagem ${widget.activeIndex + 1} de ${widget.analysis.images.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (activeImage.wasAnalyzed &&
                        activeImage.analyzedPath != activeImage.originalPath)
                      Positioned(
                        top: 12,
                        right: activeImage.hasLocation ? 48 : 12,
                        child: _OverlayToggleButton(
                          image: activeImage,
                          showOverlay: _showAnalyzedOverlay,
                          onToggle: () {
                            setState(() {
                              _showAnalyzedOverlay = !_showAnalyzedOverlay;
                            });
                          },
                        ),
                      ),
                    if (activeImage.hasLocation)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: _GpsBadge(),
                      ),
                  ],
                ),
              ),
              AnalysisImageResultsPanel(
                image: activeImage,
                resultJson: resultJson,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ImageThumbnailStrip(
          images: widget.analysis.images,
          activeIndex: widget.activeIndex,
          pageController: widget.pageController,
          onImageChanged: widget.onImageChanged,
        ),
      ],
    );
  }
}

class _ImagePageItem extends StatelessWidget {
  final ImageModel image;
  final bool showOverlay;
  final List<ImageModel> allImages;
  final int index;

  const _ImagePageItem({
    required this.image,
    required this.showOverlay,
    required this.allImages,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isAnalyzedAvailable =
        image.wasAnalyzed && image.analyzedPath != image.originalPath;

    String backgroundPath = image.originalPath;
    if (image.wasAnalyzed && image.result != null) {
      try {
        final data = json.decode(image.result!);
        if (data is Map) {
          backgroundPath = (data['processed_image_path'] ??
                  data['cropped_original_path'])
              as String? ??
              backgroundPath;
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImagePage(
              images: allImages,
              initialIndex: index,
              showOverlay: showOverlay,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(backgroundPath),
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.photo_outlined,
                size: 64,
                color: AppColors.grayMedium,
              ),
            ),
          ),
          if (isAnalyzedAvailable && showOverlay && image.analyzedPath != null)
            Image.file(
              File(image.analyzedPath!),
              fit: BoxFit.cover,
              cacheWidth: 800,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _OverlayToggleButton extends StatelessWidget {
  final ImageModel image;
  final bool showOverlay;
  final VoidCallback onToggle;

  const _OverlayToggleButton({
    required this.image,
    required this.showOverlay,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool hasHeatmap = false;
    if (image.result != null) {
      try {
        final data = jsonDecode(image.result!) as Map<String, dynamic>;
        hasHeatmap = data['heatmap_path'] != null;
      } catch (_) {}
    }
    final overlayOffLabel = hasHeatmap ? 'Ver Heatmap' : 'Ver Processada';

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: showOverlay
              ? AppColors.green
              : AppColors.navy.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showOverlay ? Icons.visibility : Icons.map_outlined,
              color: AppColors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              showOverlay ? 'Ver Original' : overlayOffLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsBadge extends StatelessWidget {
  const _GpsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.gps_fixed,
        size: 16,
        color: AppColors.white,
      ),
    );
  }
}

class _ImageThumbnailStrip extends StatelessWidget {
  final List<ImageModel> images;
  final int activeIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;

  const _ImageThumbnailStrip({
    required this.images,
    required this.activeIndex,
    required this.pageController,
    required this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final img = images[index];
          final isSelected = index == activeIndex;

          return GestureDetector(
            onTap: () {
              onImageChanged(index);
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.green : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(img.originalPath),
                  fit: BoxFit.cover,
                  cacheWidth: 150,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.photo,
                      size: 20,
                      color: AppColors.grayMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
