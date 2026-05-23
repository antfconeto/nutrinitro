import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrinitro/core/theme/app_colors.dart';
import '../bloc/image_selection_bloc.dart';

class ImageSelectionScreen extends StatelessWidget {
  const ImageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'NutriNitro Imagem',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: BlocConsumer<ImageSelectionBloc, ImageSelectionState>(
                      listener: (context, state) {
                        if (state is ImageSelectionFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: ${state.errorMessage}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildImageDisplay(context, state),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay(BuildContext context, ImageSelectionState state) {
    if (state is ImageSelectionLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightGreen),
        ),
      );
    }

    final Uint8List? bytes = state.imageBytes;

    if (bytes == null) {
      return _buildPlaceholder();
    }

    return Container(
      key: ValueKey(bytes.hashCode),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Semi-transparent gradient overlay at the bottom
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Clear / Delete Floating Icon
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    context.read<ImageSelectionBloc>().add(ClearImageEvent());
                  },
                  tooltip: 'Remover Imagem',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      key: const ValueKey('placeholder'),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.darkGreen.withValues(alpha: 0.4),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightBeige,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma imagem selecionada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em um dos botões abaixo para tirar uma foto ou selecionar da sua galeria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context
                  .read<ImageSelectionBloc>()
                  .add(PickImageEvent(ImageSource.gallery));
            },
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            label: const Text(
              'Galeria',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context
                  .read<ImageSelectionBloc>()
                  .add(PickImageEvent(ImageSource.camera));
            },
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            label: const Text(
              'Câmera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}
