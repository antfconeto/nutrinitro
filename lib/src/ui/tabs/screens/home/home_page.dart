import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/models/crop_model.dart';
import 'package:nutrinitro/src/ui/tabs/screens/home/home_state.dart';
import 'package:nutrinitro/src/ui/tabs/screens/home/home_view_model.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDatetime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => _pickerTheme(context, child),
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => _pickerTheme(context, child),
    );

    if (time == null) return;

    final datetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(homeViewModelProvider.notifier).updateDatetime(datetime);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.green,
          onPrimary: AppColors.white,
          onSurface: AppColors.navy,
        ),
      ),
      child: child!,
    );
  }

  void _showImageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
              const SizedBox(height: 20),
              Text('Adicionar imagem', style: AppText.large.copyWith(color: AppColors.navy)),
              const SizedBox(height: 16),
              _bottomSheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tirar foto',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(homeViewModelProvider.notifier).pickFromCamera();
                },
              ),
              const SizedBox(height: 12),
              _bottomSheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Escolher da galeria',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(homeViewModelProvider.notifier).pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grayLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green, size: 24),
            const SizedBox(width: 16),
            Text(label, style: AppText.medium.copyWith(color: AppColors.navy)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    ref.listen<HomeState>(homeViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        Future.microtask(() {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(message: next.errorMessage!),
          );
          ref.read(homeViewModelProvider.notifier).clearError();
        });
      }

      if (next.successMessage != null) {
        Future.microtask(() {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: next.successMessage!),
          );
          ref.read(homeViewModelProvider.notifier).clearSuccess();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: AppBar(
        title: const Text('Nova Análise'),
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Título *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    onChanged: (v) => ref
                        .read(homeViewModelProvider.notifier)
                        .updateTitle(v),
                    decoration: _inputDecoration(hint: 'Ex: Talhão norte — parcela 3'),
                    style: AppText.medium.copyWith(fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  _sectionLabel('Data e horário *'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _pickDatetime(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE4DD)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: state.datetime != null
                                ? AppColors.green
                                : AppColors.grayMedium,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.datetime != null
                                ? DateFormat('dd/MM/yyyy  HH:mm').format(state.datetime!)
                                : 'Selecione a data e o horário',
                            style: AppText.medium.copyWith(
                              fontSize: 14,
                              color: state.datetime != null
                                  ? AppColors.navy
                                  : AppColors.grayMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionLabel('Tipo de cultura *'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDE4DD)),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: state.selectedCrop?.id,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                      hint: Text('Selecione o tipo de cultura', style: AppText.hint),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grayMedium),
                      style: AppText.medium.copyWith(fontSize: 15, color: AppColors.navy),
                      items: state.crops.map((CropModel crop) {
                        return DropdownMenuItem<int>(
                          value: crop.id,
                          child: Row(
                            children: [
                              Image.asset(
                                crop.icon,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.grass,
                                  size: 24,
                                  color: AppColors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(crop.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (int? id) {
                        if (id == null) return;
                        final crop = state.crops.firstWhere((c) => c.id == id);
                        ref.read(homeViewModelProvider.notifier).selectCrop(crop);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionLabel('Observações'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    onChanged: (v) => ref
                        .read(homeViewModelProvider.notifier)
                        .updateNotes(v.isEmpty ? null : v),
                    maxLines: 3,
                    decoration: _inputDecoration(hint: 'Observações opcionais...'),
                    style: AppText.medium.copyWith(fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('Imagens *'),
                      if (state.images.isNotEmpty)
                        Text(
                          '${state.images.length} selecionada${state.images.length > 1 ? 's' : ''}',
                          style: AppText.small.copyWith(color: AppColors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 8.0;
                      const columns = 3;
                      final itemSize = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                      final allItems = [
                        ...state.images.asMap().entries.map((e) => _imageThumb(e.value, e.key, itemSize)),
                        _addImageButton(context, itemSize),
                      ];

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: allItems,
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => ref.read(homeViewModelProvider.notifier).submit(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        disabledBackgroundColor: AppColors.green.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Criar Análise',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─── Widgets helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppText.body.copyWith(fontSize: 13, color: AppColors.grayMedium),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDE4DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
    );
  }

  Widget _imageThumb(File file, int index, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => ref
                  .read(homeViewModelProvider.notifier)
                  .removeImage(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.tomato,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: AppColors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addImageButton(BuildContext context, double size) {
    return GestureDetector(
      onTap: () => _showImageBottomSheet(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.green.withOpacity(0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.green, size: 28),
            const SizedBox(height: 4),
            Text(
              'Adicionar',
              style: AppText.small.copyWith(color: AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}