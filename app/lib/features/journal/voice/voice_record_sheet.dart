import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../ui/common.dart';
import 'voice_recorder_service.dart';

enum VoiceRecordMode {
  voiceOnly,
  textOnly,
}

class VoiceRecordSheet extends StatefulWidget {
  const VoiceRecordSheet({
    super.key,
    this.initialMode = VoiceRecordMode.voiceOnly,
  });

  final VoiceRecordMode initialMode;

  static Future<VoiceRecordingResult?> show(
    BuildContext context, {
    VoiceRecordMode initialMode = VoiceRecordMode.voiceOnly,
  }) {
    return showModalBottomSheet<VoiceRecordingResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceRecordSheet(initialMode: initialMode),
    );
  }

  @override
  State<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<VoiceRecordSheet>
    with SingleTickerProviderStateMixin {
  late final VoiceRecorderService _recorder;
  late VoiceRecordMode _mode;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _starting = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _recorder = VoiceRecorderService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _recorder.addListener(_onRecorderUpdate);
    _startRecording();
  }

  void _onRecorderUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    setState(() {
      _starting = true;
      _errorMessage = null;
    });

    final success = await _recorder.startRecording(
      recordAudio: _mode == VoiceRecordMode.voiceOnly,
      enableSpeech: _mode == VoiceRecordMode.textOnly,
    );
    if (!mounted) return;

    if (!success) {
      setState(() {
        _starting = false;
        _errorMessage =
            'Izin mikrofon diperlukan atau perekam tidak dapat dimulai.';
      });
    } else {
      setState(() => _starting = false);
    }
  }

  Future<void> _switchMode(VoiceRecordMode next) async {
    if (_mode == next) return;
    await _recorder.cancelRecording();
    setState(() => _mode = next);
    await _startRecording();
  }

  @override
  void dispose() {
    _recorder.removeListener(_onRecorderUpdate);
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await _recorder.cancelRecording();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _finish() async {
    final result = await _recorder.stopRecording();
    if (!mounted) return;

    if (result != null) {
      final finalResult = _mode == VoiceRecordMode.textOnly
          ? VoiceRecordingResult(
              audioPath: '',
              durationMs: result.durationMs,
              transcript: result.transcript,
            )
          : VoiceRecordingResult(
              audioPath: result.audioPath,
              durationMs: result.durationMs,
              transcript: '',
            );

      Navigator.of(context).pop(finalResult);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatTimer(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.divider)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _mode == VoiceRecordMode.voiceOnly
                      ? 'Rekam Catatan Suara'
                      : 'Dikte Suara ke Teks',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: _cancel,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Selector Segmented Control
            Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.divider),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _ModeButton(
                    title: '🎙️ Catatan Suara',
                    sub: 'Rekam File Audio',
                    selected: _mode == VoiceRecordMode.voiceOnly,
                    onTap: () => _switchMode(VoiceRecordMode.voiceOnly),
                  ),
                  _ModeButton(
                    title: '✍️ Dikte Suara',
                    sub: 'Langsung Jadi Teks',
                    selected: _mode == VoiceRecordMode.textOnly,
                    onTap: () => _switchMode(VoiceRecordMode.textOnly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.expense,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: t.bodySmall?.copyWith(color: colors.expense),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Mic Pulsing Ring Animation
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 72 * _pulseAnimation.value,
                          height: 72 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.expense.withValues(
                              alpha: (0.35 - (_pulseAnimation.value - 0.9) * 0.5)
                                  .clamp(0.05, 0.4),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.expense,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.expense.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Timer
              Text(
                _formatTimer(_recorder.elapsedMilliseconds),
                style: t.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Status label
              Text(
                _starting
                    ? 'Menyiapkan perekam...'
                    : (_mode == VoiceRecordMode.voiceOnly
                        ? 'Merekam audio (Mode Suara Saja)...'
                        : 'Mendengarkan & mentranskripsi suara...'),
                style: t.bodySmall?.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 14),

              // Visualizer Box
              if (_mode == VoiceRecordMode.voiceOnly) ...[
                // Audio-only wave visualizer
                Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.divider),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(14, (index) {
                      // Amplitude reactive height
                      final base = 10.0;
                      final ampScale =
                          (_recorder.currentAmplitude * 44.0).clamp(0.0, 44.0);
                      final wave = (index % 3 == 0 ? 1.0 : (index % 2 == 0 ? 0.7 : 0.5));
                      final barHeight = (base + ampScale * wave).clamp(8.0, 56.0);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 4,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ] else ...[
                // Live Transcription Box
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 76, maxHeight: 120),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.divider),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transkripsi Langsung:',
                          style: t.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recorder.liveTranscript.isEmpty
                              ? 'Mulai berbicara, ucapan Anda akan muncul di sini...'
                              : _recorder.liveTranscript,
                          style: t.bodyMedium?.copyWith(
                            color: _recorder.liveTranscript.isEmpty
                                ? colors.muted
                                : colors.ink,
                            fontStyle: _recorder.liveTranscript.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.expense,
                      side: BorderSide(color: colors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l.cancel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _starting || _errorMessage != null ? null : _finish,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _mode == VoiceRecordMode.textOnly
                          ? 'Tulis ke Catatan'
                          : 'Selesai & Pasang',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = Theme.of(context).textTheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.ink : colors.muted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(
                  fontSize: 10,
                  color: selected ? colors.primary : colors.muted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
