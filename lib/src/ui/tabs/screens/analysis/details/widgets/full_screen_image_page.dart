import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nutrinitro/src/data/models/analysis/image_model.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<ImageModel> images;
  final int initialIndex;
  final bool showOverlay;

  const FullScreenImagePage({
    super.key,
    required this.images,
    required this.initialIndex,
    this.showOverlay = false,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Amostra ${_currentIndex + 1} de ${widget.images.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final img = widget.images[index];
          final isAnalyzedAvailable =
              img.wasAnalyzed && img.analyzedPath != img.originalPath;
          final activeOverlay = isAnalyzedAvailable && widget.showOverlay;

          String backgroundPath = img.originalPath;
          if (img.wasAnalyzed && img.result != null) {
            try {
              final data = json.decode(img.result!);
              if (data is Map) {
                backgroundPath = (data['processed_image_path'] ??
                        data['cropped_original_path'])
                    as String? ??
                    backgroundPath;
              }
            } catch (_) {}
          }

          final overlayPath = activeOverlay ? img.analyzedPath : null;

          return Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              maxScale: 5.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.file(
                    File(backgroundPath),
                    fit: BoxFit.contain,
                    cacheWidth: 1600,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (overlayPath != null)
                    Image.file(
                      File(overlayPath),
                      fit: BoxFit.contain,
                      cacheWidth: 1600,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
