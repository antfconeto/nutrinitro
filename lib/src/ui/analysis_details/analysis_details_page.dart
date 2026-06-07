import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/core/constants/analysis_status.dart';
import 'package:nutrinitro/src/data/models/analysis_model.dart';
import 'package:nutrinitro/src/data/models/image_model.dart';
import 'package:nutrinitro/src/data/services/analysis/analysis_registry.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_state.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_details_view_model.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_pipeline_viewer.dart';
import 'package:nutrinitro/src/ui/analysis_details/analysis_stage_panel.dart';
import 'package:nutrinitro/src/core/config/env.dart';
import 'package:nutrinitro/src/core/utils/debug_analysis_exporter.dart';
import 'package:nutrinitro/src/core/utils/pdf_exporter.dart';

class AnalysisDetailsPage extends ConsumerStatefulWidget {
  final int analysisId;

  const AnalysisDetailsPage({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisDetailsPage> createState() => _AnalysisDetailsPageState();
}

class _AnalysisDetailsPageState extends ConsumerState<AnalysisDetailsPage> {
  late final PageController _pageController;
  late final MapController _mapController;
  Timer? _activeImageDebounceTimer;
  final Map<String, double?> _imageAngleCache = {};
  bool _isSatelliteMode = false;
  bool _showAnalyzedOverlay = true;

  void _showAnalysisSelectionBottomSheet(BuildContext context, AnalysisModel analysis) {
    final cropName = analysis.crop?.name;
    var compatibleAnalyses = AnalysisRegistry.all.where((a) =>
      cropName != null && a.supportedCropNames.contains(cropName)
    ).toList();

    if (compatibleAnalyses.isEmpty) {
      compatibleAnalyses = AnalysisRegistry.all;
    }

    // Dynamically initialize selection only with analyses compatible with the current crop
    final Set<String> selectedBaseAnalyses = compatibleAnalyses.map((a) => a.id).toSet();
    const int selectedBlockSize = 10;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grayLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.playlist_add_check_outlined, color: AppColors.green, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Configurar Análise',
                        style: AppText.medium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione quais modelos e análises deseja rodar de forma combinada e offline para ${cropName ?? "esta cultura"}:',
                    style: AppText.small.copyWith(color: AppColors.grayMedium),
                  ),
                  const SizedBox(height: 20),
                  
                  ...compatibleAnalyses.map((analisador) {
                    final bool isChecked = selectedBaseAnalyses.contains(analisador.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: isChecked 
                          ? AppColors.green.withOpacity(0.04) 
                          : AppColors.grayLight.withOpacity(0.3),   
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isChecked ? AppColors.green.withOpacity(0.3) : AppColors.grayLight,
                          width: isChecked ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isChecked 
                                  ? AppColors.green.withOpacity(0.12)
                                  : AppColors.grayLight,
                              child: Icon(
                                Icons.biotech_outlined,
                                color: isChecked ? AppColors.green : AppColors.grayMedium,
                              ),
                            ),
                            title: Text(
                              analisador.name,
                              style: AppText.medium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Mede clorofila foliar (SPAD) e teor de nitrogênio (g/kg) via MLP rgb28.',
                                style: AppText.small.copyWith(fontSize: 11, color: AppColors.grayMedium),
                              ),
                            ),
                            trailing: SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                activeColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedBaseAnalyses.add(analisador.id);
                                    } else {
                                      selectedBaseAnalyses.remove(analisador.id);
                                    }
                                  });
                                },
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  selectedBaseAnalyses.remove(analisador.id);
                                } else {
                                  selectedBaseAnalyses.add(analisador.id);
                                }
                              });
                            },
                          ),

                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.green.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Predição por parcela com modelo definitivo (bilateral, ExG>0.15, grade 10×10, R²≈0.75).',
                      style: AppText.small.copyWith(fontSize: 11, color: AppColors.navy),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedBaseAnalyses.isEmpty
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              ref.read(analysisDetailsViewModelProvider.notifier).startAnalysis(
                                selectedBaseAnalyses.toList(),
                                blockSize: selectedBlockSize,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.grayLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        selectedBaseAnalyses.isEmpty 
                            ? 'Selecione pelo menos uma análise'
                            : 'Iniciar ${selectedBaseAnalyses.length} Análise${selectedBaseAnalyses.length > 1 ? 's' : ''}',
                        style: AppText.button.copyWith(
                          fontWeight: FontWeight.bold,
                          color: selectedBaseAnalyses.isEmpty ? AppColors.grayMedium : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMethodSelector(BuildContext context, RegisteredAnalysis analysis) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.biotech, color: AppColors.green, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Selecione o Modelo de Predição',
                    style: AppText.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha qual modelo calibrado deseja utilizar para esta análise (${analysis.name}):',
                style: AppText.small.copyWith(color: AppColors.grayMedium),
              ),
              const SizedBox(height: 20),
              
              ...analysis.methods.map((method) {
                IconData icon;
                switch (method.iconName) {
                  case 'trending_up':
                    icon = Icons.trending_up;
                    break;
                  case 'waves':
                    icon = Icons.waves;
                    break;
                  case 'psychology':
                    icon = Icons.psychology;
                    break;
                  default:
                    icon = Icons.insights;
                }

                return _buildMethodCard(
                  context: sheetContext,
                  title: method.name,
                  subtitle: method.description,
                  icon: icon,
                  methodId: method.id,
                );
              }).toList(),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String methodId,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.grayLight.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.green.withOpacity(0.1),
          child: Icon(icon, color: AppColors.green),
        ),
        title: Text(
          title,
          style: AppText.medium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppText.small.copyWith(fontSize: 12, color: AppColors.grayMedium),
        ),
        trailing: const Icon(Icons.play_arrow_outlined, color: AppColors.green),
        onTap: () {
          Navigator.pop(context);
          ref.read(analysisDetailsViewModelProvider.notifier).startAnalysis([methodId]);
        },
      ),
    );
  }

  double? _extractImageAngle(String path) {
    if (_imageAngleCache.containsKey(path)) {
      return _imageAngleCache[path];
    }
    try {
      final file = File(path);
      if (!file.existsSync()) {
        _imageAngleCache[path] = null;
        return null;
      }

      // Read first 256KB of the file synchronously (extremely fast on-device)
      final accessor = file.openSync();
      final bytes = accessor.readSync(256 * 1024);
      accessor.closeSync();

      final content = latin1.decode(bytes, allowInvalid: true);

      // Regex for DJI XMP properties
      final gimbalYawReg = RegExp(r'GimbalYawDegree="?([^"\s>]+)"?');
      final flightYawReg = RegExp(r'FlightYawDegree="?([^"\s>]+)"?');
      final gimbalYawTagReg = RegExp(
        r'<[^:>]+:GimbalYawDegree>([^<]+)</[^:>]+:GimbalYawDegree>',
      );
      final flightYawTagReg = RegExp(
        r'<[^:>]+:FlightYawDegree>([^<]+)</[^:>]+:FlightYawDegree>',
      );

      String? gimbalYawStr;
      var match = gimbalYawReg.firstMatch(content);
      if (match != null) {
        gimbalYawStr = match.group(1);
      } else {
        match = gimbalYawTagReg.firstMatch(content);
        if (match != null) gimbalYawStr = match.group(1);
      }

      String? flightYawStr;
      match = flightYawReg.firstMatch(content);
      if (match != null) {
        flightYawStr = match.group(1);
      } else {
        match = flightYawTagReg.firstMatch(content);
        if (match != null) flightYawStr = match.group(1);
      }

      final yawStr = gimbalYawStr ?? flightYawStr;
      if (yawStr != null) {
        final parsed = double.tryParse(yawStr);
        _imageAngleCache[path] = parsed;
        return parsed;
      }
    } catch (e) {
      print('Error extracting image angle: $e');
    }
    _imageAngleCache[path] = null;
    return null;
  }

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
        _mapController.move(LatLng(image.latitude!, image.longitude!), currentZoom);
      }
    });
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
        final bool shouldCancel = await _showCancelConfirmationDialog(context) ?? false;
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
          actions: [
            if (state.analysis != null && !state.analysis!.isProcessing) ...[
              if ((kDebugMode || Env.debug) && state.analysis!.images.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.bug_report_outlined),
                  tooltip: 'Exportar JSON (debug)',
                  onPressed: () {
                    DebugAnalysisExporter.showExportSheet(context, state.analysis!);
                  },
                ),
              if (state.analysis!.isCompleted)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Exportar PDF',
                  onPressed: () async {
                    try {
                      await PdfExporter.exportAnalysis(state.analysis!, context);
                    } catch (e) {
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
                onPressed: () => _confirmDelete(context, state.analysis!.id!),
              ),
            ],
          ],
        ),
        body: _buildBody(context, state),
      ),
    );
  }

  Future<bool?> _showCancelConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar Análise?'),
        content: const Text('A análise está em andamento. Se você sair agora, a operação será cancelada e o progresso atual será perdido.'),
        actions: [
          TextButton(
            child: const Text('Continuar Análise', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar e Sair'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockSizeOption({
    required StateSetter setModalState,
    required int size,
    required String label,
    required String subtitle,
    required int currentSelected,
    required VoidCallback onTap,
  }) {
    final bool isSelected = currentSelected == size;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green.withOpacity(0.08) : AppColors.grayLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.grayLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                size == 10 
                    ? Icons.grid_view_outlined 
                    : size == 5 
                        ? Icons.grid_on_outlined 
                        : Icons.grid_3x3_outlined,
                color: isSelected ? AppColors.green : AppColors.grayMedium,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppText.medium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.small.copyWith(
                  color: isSelected ? AppColors.green : AppColors.grayMedium,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveEstimatedTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.grayLight, fontSize: 10),
              ),
              Text(
                value,
                style: AppText.medium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveResultSummary(Map<String, dynamic> result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Estimativa da parcela',
                style: AppText.small.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (result['chlorophyll_spad'] != null)
            Text(
              'Clorofila: ${result['chlorophyll_spad']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
          if (result['nitrogen_content'] != null)
            Text(
              'Nitrogênio: ${result['nitrogen_content']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
          if (result['estimated_biomass'] != null)
            Text(
              'Biomassa: ${result['estimated_biomass']}',
              style: AppText.small.copyWith(color: AppColors.navy),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int analysisId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Análise?'),
        content: const Text('Esta ação não pode ser desfeita. Todas as imagens e resultados associados serão removidos permanentemente.'),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: AppColors.grayMedium)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tomato,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Deletar', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(ctx).pop(); // pop dialog
              final success = await ref.read(analysisDetailsViewModelProvider.notifier).deleteAnalysis();
              if (success && context.mounted) {
                Navigator.of(context).pop(); // pop details page back to home!
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalysisDetailsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    final analysis = state.analysis;
    if (analysis == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                state.errorMessage ?? 'Ocorreu um erro desconhecido.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.grayMedium),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(analysisDetailsViewModelProvider.notifier)
                    .init(widget.analysisId),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(context, analysis, state.isAnalyzing),
          if (analysis.notes != null && analysis.notes!.trim().isNotEmpty)
            _buildNotesCard(analysis.notes!),
          _buildMapCard(analysis, state.activeImageIndex),
          _buildImageGallerySection(analysis, state.activeImageIndex),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, AnalysisModel analysis, bool isAnalyzing) {
    final state = ref.watch(analysisDetailsViewModelProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.title,
                      style: AppText.large.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.grayMedium,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM/yyyy  HH:mm').format(analysis.datetime),
                          style: AppText.small.copyWith(
                            fontSize: 13,
                            color: AppColors.grayMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(analysis.status, isAnalyzing),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.grayLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (analysis.crop != null)
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        analysis.crop!.icon,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.grass,
                          size: 16,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cultura',
                          style: AppText.small.copyWith(fontSize: 10, color: AppColors.grayMedium),
                        ),
                        Text(
                          analysis.crop!.name,
                          style: AppText.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Imagens',
                        style: AppText.small.copyWith(fontSize: 10, color: AppColors.grayMedium),
                      ),
                      Text(
                        '${analysis.images.length}',
                        style: AppText.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (isAnalyzing && state.totalImagesToAnalyze > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Processando Imagens...',
                        style: AppText.small.copyWith(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${state.currentAnalyzingImageIndex} de ${state.totalImagesToAnalyze}',
                        style: AppText.small.copyWith(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.totalImagesToAnalyze > 0
                          ? state.currentAnalyzingImageIndex / state.totalImagesToAnalyze
                          : 0.0,
                      backgroundColor: AppColors.green.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analisando imagem ${state.currentAnalyzingImageIndex} com algoritmos de reflectância...',
                    style: const TextStyle(
                      color: AppColors.grayMedium,
                      fontSize: 11,
                    ),
                  ),
                  if (state.isAnalyzing) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final stages = stagesForAnalysisType(state.currentAnalyzingType);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnalysisPipelineViewer(
                              snapshot: state.currentPipelineSnapshot,
                              stages: stages,
                              currentStage: state.currentAnalysisStage,
                            ),
                            if (state.currentEstimatedResult != null) ...[
                              const SizedBox(height: 10),
                              _buildLiveResultSummary(state.currentEstimatedResult!),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (analysis.isPending || analysis.isCompleted || isAnalyzing) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAnalyzing
                    ? null
                    : () => _showAnalysisSelectionBottomSheet(context, analysis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: analysis.isCompleted ? AppColors.navy : AppColors.green,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Icon(analysis.isCompleted ? Icons.refresh_outlined : Icons.analytics_outlined),
                label: Text(
                  isAnalyzing
                      ? 'Analisando...'
                      : (analysis.isCompleted ? 'Refazer Análise' : 'Iniciar Análise'),
                  style: AppText.button.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AnalysisStatus status, bool isAnalyzing) {
    Color color = AppColors.green;
    String label = status.label;

    if (isAnalyzing || status == AnalysisStatus.processing) {
      color = AppColors.orange;
      label = 'Analisando';
    } else {
      switch (status) {
        case AnalysisStatus.pending:
          color = AppColors.orangeLight;
        case AnalysisStatus.processing:
          color = AppColors.orange;
        case AnalysisStatus.completed:
          color = AppColors.green;
        case AnalysisStatus.error:
          color = AppColors.tomato;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnalyzing || status == AnalysisStatus.processing) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 20,
                color: AppColors.greenDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Observações',
                style: AppText.medium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: AppText.body.copyWith(
              color: AppColors.gray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(AnalysisModel analysis, int activeIndex) {
    final imagesWithLocation = analysis.imagesWithLocation;

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
      final imgIndex = analysis.images.indexOf(image);
      final angle = _extractImageAngle(image.originalPath);

      // Rotate by the parsed angle (degrees to radians)
      final double radians = angle != null ? (angle * math.pi / 180) : 0.0;
      final bool isActive = imgIndex == activeIndex;

      return Marker(
        point: LatLng(image.latitude!, image.longitude!),
        width: 66,
        height: 66,
        child: GestureDetector(
          onTap: () {
            if (imgIndex != -1) {
              ref.read(analysisDetailsViewModelProvider.notifier).updateActiveImage(imgIndex);
              _pageController.animateToPage(
                imgIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Directional arrow pointer around the thumbnail circle
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
              // Circular Image thumbnail itself
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
              // Small number index badge in the corner
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
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(averageLat, averageLng),
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 22.0, // Enlarged max zoom for detailed inspects
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _isSatelliteMode
                            ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nutrinitro.app',
                      ),
                      MarkerLayer(
                        markers: markers,
                      ),
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
                            setState(() {
                              _isSatelliteMode = !_isSatelliteMode;
                            });
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
                            _mapController.move(LatLng(averageLat, averageLng), 15.0);
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

  Widget _buildImageGallerySection(AnalysisModel analysis, int activeIndex) {
    if (analysis.images.isEmpty) {
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

    final activeImage = analysis.images[activeIndex];

    // Parse mock result JSON safely
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
        // Big active image preview
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
                        controller: _pageController,
                        itemCount: analysis.images.length,
                        onPageChanged: (index) => _onImageChanged(index, analysis.images),
                        itemBuilder: (context, index) {
                          final img = analysis.images[index];
                          final bool isAnalyzedAvailable = img.wasAnalyzed && img.analyzedPath != img.originalPath;
                          final String displayPath = ((isAnalyzedAvailable && _showAnalyzedOverlay)
                              ? img.analyzedPath
                              : img.originalPath) ?? img.originalPath;

                          String backgroundPath = img.originalPath;
                          if (img.wasAnalyzed && img.result != null) {
                            try {
                              final data = json.decode(img.result!);
                              if (data is Map) {
                                backgroundPath = (data['processed_image_path']
                                        ?? data['cropped_original_path'])
                                    as String? ?? backgroundPath;
                              }
                            } catch (_) {}
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImagePage(
                                    images: analysis.images,
                                    initialIndex: index,
                                    showOverlay: _showAnalyzedOverlay,
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
                                if (isAnalyzedAvailable && _showAnalyzedOverlay && img.analyzedPath != null)
                                  Image.file(
                                    File(img.analyzedPath!),
                                    fit: BoxFit.cover,
                                    cacheWidth: 800,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Glassmorphic navigation overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Imagem ${activeIndex + 1} de ${analysis.images.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (activeImage.wasAnalyzed && activeImage.analyzedPath != activeImage.originalPath)
                      Positioned(
                        top: 12,
                        right: activeImage.hasLocation ? 48 : 12,
                        child: Builder(
                          builder: (context) {
                            bool hasHeatmap = false;
                            if (activeImage.result != null) {
                              try {
                                final data = jsonDecode(activeImage.result!) as Map<String, dynamic>;
                                hasHeatmap = data['heatmap_path'] != null;
                              } catch (_) {}
                            }
                            final String overlayOffLabel = hasHeatmap ? 'Ver Heatmap' : 'Ver Processada';
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showAnalyzedOverlay = !_showAnalyzedOverlay;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showAnalyzedOverlay ? AppColors.green : AppColors.navy.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.white.withOpacity(0.4), width: 1),
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
                                      _showAnalyzedOverlay ? Icons.visibility : Icons.map_outlined,
                                      color: AppColors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _showAnalyzedOverlay ? 'Ver Original' : overlayOffLabel,
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
                          },
                        ),
                      ),
                    if (activeImage.hasLocation)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
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
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Metadados da Imagem',
                          style: AppText.medium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        if (activeImage.wasAnalyzed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ANALISADA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AGUARDANDO ANÁLISE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMetadataRow(
                      Icons.calendar_month,
                      'Data Original',
                      activeImage.datetime != null
                          ? DateFormat('dd/MM/yyyy HH:mm:ss').format(activeImage.datetime!)
                          : 'Não disponível no EXIF',
                    ),
                    _buildMetadataRow(
                      Icons.location_on_outlined,
                      'Coordenadas',
                      activeImage.hasLocation
                          ? '${activeImage.latitude!.toStringAsFixed(6)}, ${activeImage.longitude!.toStringAsFixed(6)}'
                          : 'Sem geolocalização',
                    ),
                    const Divider(height: 24, thickness: 1, color: AppColors.grayLight),
                    Text(
                      'Resultado Agronômico',
                      style: AppText.medium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (activeImage.wasAnalyzed) ...[
                      if (resultJson.containsKey('chlorophyll_spad')) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                Icons.biotech_outlined,
                                'Clorofila',
                                resultJson['chlorophyll_spad'] ?? '45.2 SPAD',
                                AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (resultJson.containsKey('estimated_biomass')) ...[
                              Expanded(
                                child: _buildMetricTile(
                                  Icons.scale_outlined,
                                  'Biomassa',
                                  resultJson['estimated_biomass'] ?? 'N/A',
                                  AppColors.greenDark,
                                ),
                              ),
                            ] else if (resultJson.containsKey('nitrogen_content')) ...[
                              Expanded(
                                child: _buildMetricTile(
                                  Icons.grass_outlined,
                                  'Nitrogênio',
                                  resultJson['nitrogen_content'] ?? 'N/A',
                                  AppColors.greenDark,
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: _buildMetricTile(
                                  Icons.psychology_outlined,
                                  'Modelo',
                                  resultJson['prediction_method'] ?? 'SI',
                                  AppColors.navy,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (resultJson.containsKey('nitrogen_content') && resultJson.containsKey('estimated_biomass')) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  Icons.grass_outlined,
                                  'Nitrogênio',
                                  resultJson['nitrogen_content'] ?? 'N/A',
                                  AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (resultJson.containsKey('estimated_biomass') || resultJson.containsKey('nitrogen_content')) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  Icons.psychology_outlined,
                                  'Modelo de Predição',
                                  resultJson['prediction_method'] ?? 'SI',
                                  AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                Icons.opacity,
                                'Umidade',
                                resultJson['moisture'] ?? '13.5%',
                                AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                Icons.grass_outlined,
                                'Proteína',
                                resultJson['protein'] ?? '8.2%',
                                AppColors.greenDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                Icons.verified_user_outlined,
                                'Qualidade',
                                resultJson['quality'] ?? 'Boa',
                                AppColors.orangeLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                Icons.info_outline,
                                'Status Técnico',
                                'Detectado',
                                AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (resultJson['notes'] != null && resultJson['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grayLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grayLight, width: 1),
                          ),
                          child: Text(
                            resultJson['notes'],
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              color: AppColors.gray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grayLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.navy.withOpacity(0.08),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 32,
                              color: AppColors.grayMedium.withOpacity(0.7),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Esta imagem ainda não foi processada.',
                              style: AppText.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Utilize o botão "Iniciar Análise" no topo para rodar o modelo agronômico.',
                              textAlign: TextAlign.center,
                              style: AppText.small.copyWith(
                                color: AppColors.grayMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mini thumbnails list
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: analysis.images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final img = analysis.images[index];
              final isSelected = index == activeIndex;

              return GestureDetector(
                onTap: () {
                  _onImageChanged(index, analysis.images);
                  _pageController.animateToPage(
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
                        child: Icon(Icons.photo, size: 20, color: AppColors.grayMedium),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grayMedium.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppText.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.grayMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.small.copyWith(color: AppColors.gray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grayLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.small.copyWith(fontSize: 10, color: AppColors.grayMedium),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final img = widget.images[index];
          final bool isAnalyzedAvailable = img.wasAnalyzed && img.analyzedPath != img.originalPath;
          final bool activeOverlay = isAnalyzedAvailable && widget.showOverlay;

          String backgroundPath = img.originalPath;
          if (img.wasAnalyzed && img.result != null) {
            try {
              final data = json.decode(img.result!);
              if (data is Map) {
                backgroundPath = (data['processed_image_path']
                        ?? data['cropped_original_path'])
                    as String? ?? backgroundPath;
              }
            } catch (_) {}
          }

          final String? overlayPath = activeOverlay ? img.analyzedPath : null;

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

class _ScanningLineWidget extends StatefulWidget {
  const _ScanningLineWidget();

  @override
  State<_ScanningLineWidget> createState() => _ScanningLineWidgetState();
}

class _ScanningLineWidgetState extends State<_ScanningLineWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _controller.value * 160,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange.withOpacity(0.0),
                      AppColors.orange,
                      AppColors.orange.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
