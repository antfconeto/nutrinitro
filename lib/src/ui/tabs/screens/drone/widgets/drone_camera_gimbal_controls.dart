import 'package:flutter/material.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';

class DroneCameraGimbalControls extends StatefulWidget {
  final bool isConnected;
  final bool isRecording;
  final VoidCallback onCapturePhoto;
  final VoidCallback onToggleVideo;
  final ValueChanged<double> onGimbalPitchChanged;

  const DroneCameraGimbalControls({
    super.key,
    required this.isConnected,
    required this.isRecording,
    required this.onCapturePhoto,
    required this.onToggleVideo,
    required this.onGimbalPitchChanged,
  });

  @override
  State<DroneCameraGimbalControls> createState() => _DroneCameraGimbalControlsState();
}

class _DroneCameraGimbalControlsState extends State<DroneCameraGimbalControls> {
  double _pitch = -90.0;
  String _selectedIso = 'Auto';
  String _selectedShutter = 'Auto';
  int? _whiteBalanceKelvin;

  static const _kelvinOptions = <int?>[
    null,
    2500,
    3000,
    3500,
    4000,
    4500,
    5000,
    5600,
    6000,
    6500,
    7000,
    7500,
    8000,
    9000,
    10000,
  ];

  static String _formatKelvin(int? kelvin) =>
      kelvin == null ? 'Auto' : '$kelvin K';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câmera e Gimbal',
            style: AppText.medium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Row 1: Shutter controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Photo capture
              IconButton.filled(
                onPressed: widget.isConnected ? widget.onCapturePhoto : null,
                icon: const Icon(Icons.camera_alt),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grayLight,
                  disabledForegroundColor: AppColors.grayMedium,
                ),
                iconSize: 28,
              ),
              // Video record
              IconButton.filled(
                onPressed: widget.isConnected ? widget.onToggleVideo : null,
                icon: Icon(widget.isRecording ? Icons.stop : Icons.videocam),
                style: IconButton.styleFrom(
                  backgroundColor: widget.isRecording ? AppColors.tomato : AppColors.navy,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grayLight,
                  disabledForegroundColor: AppColors.grayMedium,
                ),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Gimbal control slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ângulo do Gimbal (Pitch)',
                    style: AppText.small.copyWith(color: AppColors.navy),
                  ),
                  Text(
                    '${_pitch.toInt()}°',
                    style: AppText.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _pitch,
                min: -90.0,
                max: 30.0,
                activeColor: AppColors.green,
                inactiveColor: AppColors.grayLight,
                onChanged: widget.isConnected
                    ? (val) {
                        setState(() {
                          _pitch = val;
                        });
                        widget.onGimbalPitchChanged(val);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Parameter selects
          const Divider(color: AppColors.grayLight),
          const SizedBox(height: 8),
          Text(
            'Configurações de Exposição',
            style: AppText.small.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'ISO',
                  value: _selectedIso,
                  items: const ['Auto', '100', '200', '400', '800', '1600'],
                  onChanged: widget.isConnected
                      ? (val) => setState(() => _selectedIso = val!)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: 'Shutter',
                  value: _selectedShutter,
                  items: const ['Auto', '1/60', '1/120', '1/250', '1/500', '1/1000'],
                  onChanged: widget.isConnected
                      ? (val) => setState(() => _selectedShutter = val!)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKelvinDropdown(
                  label: 'W.Balance',
                  value: _whiteBalanceKelvin,
                  onChanged: widget.isConnected
                      ? (val) => setState(() => _whiteBalanceKelvin = val)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKelvinDropdown({
    required String label,
    required int? value,
    required ValueChanged<int?>? onChanged,
  }) {
    final selected = _kelvinOptions.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.small.copyWith(fontSize: 10, color: AppColors.grayMedium),
        ),
        const SizedBox(height: 4),
        DropdownButton<int?>(
          value: selected,
          onChanged: onChanged,
          isExpanded: true,
          items: _kelvinOptions.map((kelvin) {
            return DropdownMenuItem<int?>(
              value: kelvin,
              child: Text(_formatKelvin(kelvin), style: AppText.small),
            );
          }).toList(),
          underline: Container(
            height: 1.5,
            color: AppColors.green,
          ),
          style: AppText.small.copyWith(color: AppColors.navy),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.small.copyWith(fontSize: 10, color: AppColors.grayMedium),
        ),
        const SizedBox(height: 4),
        DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: AppText.small),
            );
          }).toList(),
          underline: Container(
            height: 1.5,
            color: AppColors.green,
          ),
          style: AppText.small.copyWith(color: AppColors.navy),
        ),
      ],
    );
  }
}
