import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/analysis/analysis_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/analysis/details/utils/image_angle_extractor.dart';

class AnalysisMapCard extends StatefulWidget {
  final AnalysisModel analysis;
  final int activeIndex;
  final MapController mapController;
  final PageController pageController;
  final ImageAngleExtractor angleExtractor;
  final ValueChanged<int> onMarkerTap;

  const AnalysisMapCard({
    super.key,
    required this.analysis,
    required this.activeIndex,
    required this.mapController,
    required this.pageController,
    required this.angleExtractor,
    required this.onMarkerTap,
  });

  @override
  State<AnalysisMapCard> createState() => _AnalysisMapCardState();
}

class _AnalysisMapCardState extends State<AnalysisMapCard> {
  bool _isSatelliteMode = false;

  @override
  Widget build(BuildContext context) {
    final imagesWithLocation = widget.analysis.imagesWithLocation;
    if (imagesWithLocation.isEmpty) {
      return const SizedBox.shrink();
    }

    double averageLat = 0;
    double averageLng = 0;
    for (final img in imagesWithLocation) {
      averageLat += img.latitude!;
      averageLng += img.longitude!;
    }
    averageLat /= imagesWithLocation.length;
    averageLng /= imagesWithLocation.length;

    final markers = imagesWithLocation.map((image) {
      final imgIndex = widget.analysis.images.indexOf(image);
      final angle = widget.angleExtractor.extract(image.originalPath);
      final radians = angle != null ? (angle * math.pi / 180) : 0.0;
      final isActive = imgIndex == widget.activeIndex;

      return Marker(
        point: LatLng(image.latitude!, image.longitude!),
        width: 66,
        height: 66,
        child: GestureDetector(
          onTap: () {
            if (imgIndex != -1) {
              widget.onMarkerTap(imgIndex);
              widget.pageController.animateToPage(
                imgIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (angle != null)
                Transform.rotate(
                  angle: radians,
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.navigation,
                      color: isActive ? AppColors.green : AppColors.tomato,
                      size: 20,
                    ),
                  ),
                ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? AppColors.green : AppColors.white,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.file(
                    File(image.originalPath),
                    fit: BoxFit.cover,
                    cacheWidth: 150,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image,
                      size: 16,
                      color: AppColors.grayMedium,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.green : AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${imgIndex + 1}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 20,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mapa de Coleta',
                      style: AppText.medium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${imagesWithLocation.length} fotos georeferenciadas',
                  style: AppText.small.copyWith(
                    color: AppColors.grayMedium,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: widget.mapController,
                    options: MapOptions(
                      initialCenter: LatLng(averageLat, averageLng),
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 22.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _isSatelliteMode
                            ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nutrinitro.app',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'toggle_map_mode',
                          onPressed: () {
                            setState(() => _isSatelliteMode = !_isSatelliteMode);
                          },
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.green,
                          child: Icon(
                            _isSatelliteMode
                                ? Icons.map_outlined
                                : Icons.satellite_alt_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter_map',
                          onPressed: () {
                            widget.mapController.move(
                              LatLng(averageLat, averageLng),
                              15.0,
                            );
                          },
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.green,
                          child: const Icon(Icons.my_location),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
