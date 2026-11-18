import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/tokens.dart';

class VoicePlayerCard extends StatefulWidget {
  const VoicePlayerCard({
    super.key,
    required this.audioPath,
    this.durationMs,
    this.transcript,
    this.onDelete,
    this.onCopyToNotes,
    this.compact = false,
  });

  final String audioPath;
  final int? durationMs;
  final String? transcript;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onCopyToNotes;
  final bool compact;

  @override
  State<VoicePlayerCard> createState() => _VoicePlayerCardState();
}

class _VoicePlayerCardState extends State<VoicePlayerCard> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!widget.audioPath.startsWith('demo')) {
      _player = AudioPlayer();
    }
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.audioPath.startsWith('demo')) {
      _duration = Duration(milliseconds: widget.durationMs ?? 42000);
      _position = Duration(milliseconds: (widget.durationMs ?? 42000) ~/ 3);
      if (mounted) setState(() => _isLoaded = true);
      return;
    }
    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      final d = await _player!.setFilePath(widget.audioPath);
      if (d != null) {
        _duration = d;
      } else if (widget.durationMs != null) {
        _duration = Duration(milliseconds: widget.durationMs!);
      }

      _player!.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _position = Duration.zero;
            _player!.pause();
            _player!.seek(Duration.zero);
          }
        });
      });

      _player!.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() => _position = pos);
      });

      _player!.durationStream.listen((dur) {
        if (!mounted || dur == null) return;
        setState(() => _duration = dur);
      });

      if (mounted) setState(() => _isLoaded = true);
    } catch (e) {
      debugPrint('VoicePlayer init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isLoaded || _hasError) return;
    if (_player == null) {
      setState(() => _isPlaying = !_isPlaying);
      return;
    }
    if (_isPlaying) {
      _player!.pause();
    } else {
      _player!.play();
    }
  }

  void _cycleSpeed() {
    final next = switch (_speed) {
      1.0 => 1.5,
      1.5 => 2.0,
      _ => 1.0,
    };
    setState(() => _speed = next);
    _player?.setSpeed(next);
  }

  void _seek(double ratio) {
    if (_duration == Duration.zero) return;
    final targetMs = (_duration.inMilliseconds * ratio).round();
    if (_player == null) {
      setState(() => _position = Duration(milliseconds: targetMs));
      return;
    }
    _player!.seek(Duration(milliseconds: targetMs));
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final colors = context.colors;

    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.broken_image_outlined, size: 20, color: colors.muted),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                'File audio tidak ditemukan',
                style: t.bodySmall?.copyWith(color: colors.muted),
              ),
            ),
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: colors.expense,
                onPressed: widget.onDelete,
              ),
          ],
        ),
      );
    }

    final hasTranscript = widget.transcript != null &&
        widget.transcript!.trim().isNotEmpty;

    if (widget.compact) {
      // Mini player untuk tampilan feed
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            _PlayButton(
              isPlaying: _isPlaying,
              onTap: _togglePlay,
              size: 36,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WaveformSeeker(
                    position: _position,
                    duration: _duration,
                    onSeek: _seek,
                    height: 24,
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: t.bodySmall?.copyWith(
                          fontSize: AppFontSize.caption,
                          color: colors.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: t.bodySmall?.copyWith(
                          fontSize: AppFontSize.caption,
                          color: colors.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlayButton(
                isPlaying: _isPlaying,
                onTap: _togglePlay,
                size: 44,
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: _WaveformSeeker(
                  position: _position,
                  duration: _duration,
                  onSeek: _seek,
                  height: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _cycleSpeed,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${_speed}x',
                        style: t.bodySmall?.copyWith(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onDelete != null) ...[
                    const SizedBox(width: AppSpace.md),
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: colors.expense,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              l.delete,
                              style: t.bodySmall?.copyWith(
                                fontSize: AppFontSize.meta,
                                fontWeight: FontWeight.w600,
                                color: colors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (hasTranscript) ...[
            const SizedBox(height: AppSpace.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: colors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'Transkripsi Suara',
                            style: t.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              fontSize: AppFontSize.caption,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onCopyToNotes != null)
                        InkWell(
                          onTap: () =>
                              widget.onCopyToNotes!(widget.transcript!),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  'Salin ke catatan',
                                  style: t.bodySmall?.copyWith(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    widget.transcript!,
                    style: t.bodyMedium?.copyWith(
                      fontSize: AppFontSize.body,
                      height: 1.5,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.onTap,
    required this.size,
  });

  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: size * 0.55,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

class _WaveformSeeker extends StatelessWidget {
  const _WaveformSeeker({
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.height,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<double> onSeek;
  final double height;

  static const List<double> _barHeights = [
    0.35, 0.55, 0.85, 0.45, 0.70, 0.95, 0.60, 0.40,
    0.75, 0.90, 0.65, 0.45, 0.85, 0.55, 0.40, 0.70,
    0.95, 0.50, 0.35, 0.65, 0.80, 0.45,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalMs = duration.inMilliseconds;
    final currentMs = position.inMilliseconds;
    final ratio = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final activeIndex = (ratio * _barHeights.length).floor();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final r = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            onSeek(r);
          },
          onTapDown: (details) {
            final r = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            onSeek(r);
          },
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_barHeights.length, (index) {
                final barRatio = _barHeights[index];
                final isPlayed = index <= activeIndex;
                return Container(
                  width: 3.5,
                  height: (height * barRatio).clamp(4.0, height),
                  decoration: BoxDecoration(
                    color: isPlayed
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
