import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinitro/src/core/themes/app_colors.dart';
import 'package:nutrinitro/src/core/themes/app_text.dart';
import 'package:nutrinitro/src/data/services/drone/drone_service_provider.dart';

class DroneLiveFpvFeed extends ConsumerStatefulWidget {
  final bool isRecording;
  final bool isConnected;
  final bool isMiniMode;

  const DroneLiveFpvFeed({
    super.key,
    required this.isRecording,
    required this.isConnected,
    this.isMiniMode = false,
  });

  @override
  ConsumerState<DroneLiveFpvFeed> createState() => _DroneLiveFpvFeedState();
}

class _DroneLiveFpvFeedState extends ConsumerState<DroneLiveFpvFeed> {
  StreamSubscription<Uint8List>? _fpvSubscription;
  ui.Image? _currentFrame;
  bool _isProcessingFrame = false;
  bool _disposed = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  late final dynamic _droneService;

  @override
  void initState() {
    super.initState();
    _droneService = ref.read(droneServiceProvider);
    if (widget.isConnected) {
      _startFpvStream();
    }
    if (widget.isRecording) {
      _startRecordTimer();
    }
  }

  @override
  void didUpdateWidget(covariant DroneLiveFpvFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _startFpvStream();
      } else {
        _stopFpvStream();
      }
    }
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startRecordTimer();
      } else {
        _stopRecordTimer();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _fpvSubscription?.cancel();
    _droneService.stopFpvStream();
    _recordTimer?.cancel();
    _currentFrame?.dispose();
    super.dispose();
  }

  void _startFpvStream() {
    _fpvSubscription?.cancel();
    _droneService.startFpvStream();
    _fpvSubscription =
        (_droneService.fpvByteStream as Stream<Uint8List>).listen((frameBytes) {
      if (_isProcessingFrame || _disposed) return;
      _isProcessingFrame = true;
      _decodeYuvFrame(frameBytes);
    });
  }

  void _stopFpvStream() {
    _fpvSubscription?.cancel();
    _droneService.stopFpvStream();
    if (mounted) {
      setState(() => _currentFrame = null);
    }
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    if (mounted) setState(() => _recordDuration = Duration.zero);
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_disposed && mounted) {
        setState(() => _recordDuration = Duration(seconds: timer.tick));
      }
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    if (mounted) setState(() => _recordDuration = Duration.zero);
  }

  Future<void> _decodeYuvFrame(Uint8List bytes) async {
    try {
      const width = 160;
      const height = 120;
      final rgbaBytes = Uint8List(width * height * 4);

      for (int i = 0; i < width * height; i++) {
        final yVal = bytes[i];
        final rgbaIdx = i * 4;
        rgbaBytes[rgbaIdx] = (yVal * 0.75).toInt();
        rgbaBytes[rgbaIdx + 1] = yVal;
        rgbaBytes[rgbaIdx + 2] = (yVal * 0.82).toInt();
        rgbaBytes[rgbaIdx + 3] = 255;
      }

      ui.decodeImageFromPixels(
        rgbaBytes,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (result) {
          if (!_disposed && mounted) {
            setState(() {
              _currentFrame?.dispose();
              _currentFrame = result;
              _isProcessingFrame = false;
            });
          } else {
            result.dispose();
            _isProcessingFrame = false;
          }
        },
      );
    } catch (_) {
      _isProcessingFrame = false;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hasFrame = _currentFrame != null;

    return ColoredBox(
      color: const Color(0xFF0D0D0D),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.isConnected && hasFrame)
            RawImage(
              image: _currentFrame,
              fit: BoxFit.cover,
            )
          else
            _buildPlaceholder(),

          if (widget.isConnected && !widget.isMiniMode) ...[
            Positioned(
              top: 56,
              left: 16,
              child: _HudChip(
                icon: Icons.videocam_rounded,
                label: 'FPV',
              ),
            ),
            if (widget.isRecording)
              Positioned(
                top: 56,
                right: 16,
                child: _HudChip(
                  icon: Icons.fiber_manual_record,
                  label: _formatDuration(_recordDuration),
                  accent: AppColors.tomato,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: AppColors.white.withValues(alpha: 0.25),
            size: widget.isMiniMode ? 22 : 40,
          ),
          if (!widget.isMiniMode) ...[
            const SizedBox(height: 12),
            Text(
              widget.isConnected
                  ? 'Iniciando câmera…'
                  : 'Aguardando feed',
              style: AppText.small.copyWith(
                color: AppColors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _HudChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.small.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
