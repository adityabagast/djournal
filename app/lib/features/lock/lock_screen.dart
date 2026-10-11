import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/security/lock_controller.dart';
import '../../data/sync/account_controller.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../splash/splash_overlay.dart';
import 'pin_pad.dart';

/// Layar kunci yang menutupi seluruh app selama terkunci.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Langsung tawarkan biometrik kalau aktif, tapi setelah animasi
    // pembuka selesai supaya dialognya tidak menutupi splash.
    if (ref.read(splashDoneProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    } else {
      ref.listenManual(splashDoneProvider, (_, done) {
        if (done) _biometric();
      });
    }
    _startTickerIfLockedOut();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (!mounted) return;
    final lock = ref.read(lockProvider.notifier);
    if (!ref.read(lockProvider).biometricEnabled) return;
    await lock.unlockWithBiometric(context.l10n.biometricReason);
  }

  /// Perbarui hitung mundur selama masa tunggu.
  void _startTickerIfLockedOut() {
    _ticker?.cancel();
    final lock = ref.read(lockProvider.notifier);
    if (lock.lockoutRemaining == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final left = lock.lockoutRemaining;
      setState(() {
        _error = left == null
            ? null
            : context.l10n.tooManyAttempts(left.inSeconds + 1);
      });
      if (left == null) t.cancel();
    });
  }

  Future<void> _submit(String pin) async {
    final l = context.l10n;
    final result = await ref.read(lockProvider.notifier).unlockWithPin(pin);
    if (!mounted) return;
    switch (result) {
      case UnlockResult.ok:
        setState(() => _error = null);
      case UnlockResult.wrong:
        setState(() => _error = l.wrongPin);
      case UnlockResult.lockedOut:
        setState(() => _error = null);
        _startTickerIfLockedOut();
    }
  }

  Future<void> _forgotPin() async {
    final l = context.l10n;
    final loggedIn = ref.read(accountProvider).loggedIn;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.forgotPinTitle),
        content: Text(loggedIn ? l.forgotPinBody : l.forgotPinBodyLocal),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l.resetPin),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Data dihapus dulu, baru kunci dilepas: isi jurnal tidak pernah
    // terlihat tanpa PIN.
    if (loggedIn) {
      await ref.read(accountProvider.notifier).signOut();
    } else {
      await ref.read(databaseProvider).resetData();
    }
    await ref.read(lockProvider.notifier).disablePin();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lock = ref.watch(lockProvider);
    final lockedOut = ref.read(lockProvider.notifier).lockoutRemaining != null;

    return PinPad(
      title: l.appName,
      message: l.enterPin,
      error: _error,
      enabled: !lockedOut,
      onCompleted: _submit,
      footer: Column(
        children: [
          if (lock.biometricEnabled)
            PinFooterButton(label: l.useBiometric, onTap: _biometric),
          PinFooterButton(label: l.forgotPin, onTap: _forgotPin),
        ],
      ),
    );
  }
}
