import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/security/lock_controller.dart';
import '../../ui/common.dart';
import 'pin_pad.dart';

/// Buat PIN baru: ketik, lalu ulangi. Mengembalikan true kalau tersimpan.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  static Future<bool?> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PinSetupScreen()));

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;

  Future<void> _completed(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = context.l10n.pinMismatch;
      });
      return;
    }
    await ref.read(lockProvider.notifier).enablePin(pin);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PinPad(
      // Key berbeda supaya titik kosong lagi saat pindah ke langkah 2.
      key: ValueKey(_first == null),
      title: _first == null ? l.createPin : l.confirmPin,
      message: _first == null ? l.createPinHint : l.confirmPinHint,
      error: _error,
      onCompleted: _completed,
      onBack: () => Navigator.of(context).pop(false),
    );
  }
}

/// Minta PIN saat ini (mis. sebelum mematikan kunci). True kalau benar.
class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({super.key});

  static Future<bool?> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PinVerifyScreen()));

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PinPad(
      title: l.currentPin,
      message: l.currentPinHint,
      error: _error,
      onBack: () => Navigator.of(context).pop(false),
      onCompleted: (pin) async {
        final ok = await ref.read(lockProvider.notifier).verifyPin(pin);
        if (!context.mounted) return;
        if (ok) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _error = l.wrongPin);
        }
      },
    );
  }
}
