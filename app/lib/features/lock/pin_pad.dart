import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/security/pin_store.dart';
import '../../ui/common.dart';

/// Layar PIN hijau seperti desain: ikon gembok, judul, 4 titik, keypad.
/// Dipakai untuk membuka kunci, membuat PIN, dan konfirmasi PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.message,
    required this.onCompleted,
    this.error,
    this.enabled = true,
    this.footer,
    this.onBack,
  });

  final String title;
  final String message;
  final String? error;
  final bool enabled;

  /// Dipanggil saat 4 angka terisi. Titik dikosongkan lagi setelahnya.
  final Future<void> Function(String pin) onCompleted;

  /// Tombol tambahan di bawah keypad (biometrik, lupa PIN).
  final Widget? footer;

  /// Tampilkan tombol kembali di kiri atas (untuk layar dari Pengaturan).
  final VoidCallback? onBack;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  Future<void> _press(String digit) async {
    if (!widget.enabled || _busy || _pin.length >= PinStore.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == PinStore.pinLength) {
      setState(() => _busy = true);
      await widget.onCompleted(_pin);
      if (mounted) {
        setState(() {
          _pin = '';
          _busy = false;
        });
      }
    }
  }

  void _delete() {
    if (_pin.isEmpty || _busy) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const onDark = AppColors.primaryOnDark;

    Widget key(String digit) => _KeyButton(
      label: digit,
      onTap: widget.enabled ? () => _press(digit) : null,
      child: Text(
        digit,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Material(
      color: AppColors.primary,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.onBack == null
                          ? const SizedBox(height: 48)
                          : IconButton(
                              tooltip: l.back,
                              onPressed: widget.onBack,
                              color: Colors.white,
                              icon: const Icon(Icons.arrow_back),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: onDark, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      label: '${_pin.length} / ${PinStore.pinLength}',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < PinStore.pinLength; i++)
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                color: i < _pin.length
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          widget.error ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFD7C2),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ]) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final d in row) ...[
                            key(d),
                            if (d != row.last) const SizedBox(width: 28),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 72),
                        const SizedBox(width: 28),
                        key('0'),
                        const SizedBox(width: 28),
                        _KeyButton(
                          label: l.deleteDigit,
                          filled: false,
                          onTap: _delete,
                          child: const Icon(
                            Icons.backspace_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ?widget.footer,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: filled
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Tombol teks putih bergaris bawah di bawah keypad.
class PinFooterButton extends StatelessWidget {
  const PinFooterButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryOnDark,
        textStyle: const TextStyle(
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primaryOnDark,
        ),
      ),
      child: Text(label),
    );
  }
}
