import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'pin_store.dart';

@immutable
class LockState {
  const LockState({
    this.loading = true,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.locked = false,
    this.failedAttempts = 0,
    this.lockedOutUntil,
  });

  final bool loading;
  final bool pinEnabled;
  final bool biometricEnabled;

  /// HP punya sensor sidik jari / wajah yang sudah didaftarkan.
  final bool biometricAvailable;
  final bool locked;
  final int failedAttempts;

  /// Setelah terlalu banyak PIN salah, tunggu sampai waktu ini.
  final DateTime? lockedOutUntil;

  LockState copyWith({
    bool? loading,
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
    bool? locked,
    int? failedAttempts,
    DateTime? Function()? lockedOutUntil,
  }) => LockState(
    loading: loading ?? this.loading,
    pinEnabled: pinEnabled ?? this.pinEnabled,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    locked: locked ?? this.locked,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedOutUntil: lockedOutUntil != null
        ? lockedOutUntil()
        : this.lockedOutUntil,
  );
}

enum UnlockResult { ok, wrong, lockedOut }

final pinStoreProvider = Provider((ref) => PinStore());

final lockProvider = NotifierProvider<LockController, LockState>(
  LockController.new,
);

/// Status kunci aplikasi. Terkunci saat app dibuka dan saat kembali dari
/// background setelah [relockAfter].
class LockController extends Notifier<LockState> {
  static const relockAfter = Duration(seconds: 30);
  static const freeAttempts = 5;

  final _auth = LocalAuthentication();
  DateTime? _backgroundAt;

  PinStore get _store => ref.read(pinStoreProvider);

  @override
  LockState build() {
    Future.microtask(_init);
    return const LockState();
  }

  Future<void> _init() async {
    final hasPin = await _store.hasPin();
    final bio = hasPin && await _store.biometricEnabled();
    state = state.copyWith(
      loading: false,
      pinEnabled: hasPin,
      biometricEnabled: bio,
      biometricAvailable: await _checkBiometricAvailable(),
      locked: hasPin,
    );
  }

  Future<bool> _checkBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Dipanggil saat app pindah ke background / kembali.
  void onBackground() => _backgroundAt = DateTime.now();

  void onForeground() {
    final since = _backgroundAt;
    _backgroundAt = null;
    if (state.pinEnabled &&
        since != null &&
        DateTime.now().difference(since) >= relockAfter) {
      state = state.copyWith(locked: true);
    }
  }

  void lockNow() {
    if (state.pinEnabled) state = state.copyWith(locked: true);
  }

  /// Sisa waktu tunggu setelah terlalu banyak PIN salah (null = boleh coba).
  Duration? get lockoutRemaining {
    final until = state.lockedOutUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<UnlockResult> unlockWithPin(String pin) async {
    if (lockoutRemaining != null) return UnlockResult.lockedOut;
    if (await _store.verify(pin)) {
      state = state.copyWith(
        locked: false,
        failedAttempts: 0,
        lockedOutUntil: () => null,
      );
      return UnlockResult.ok;
    }
    final failed = state.failedAttempts + 1;
    // Mulai percobaan ke-5: tunggu 30 detik, bertambah tiap kali salah lagi.
    final wait = failed >= freeAttempts
        ? Duration(seconds: 30 * (failed - freeAttempts + 1))
        : null;
    state = state.copyWith(
      failedAttempts: failed,
      lockedOutUntil: () => wait == null ? null : DateTime.now().add(wait),
    );
    return wait == null ? UnlockResult.wrong : UnlockResult.lockedOut;
  }

  /// Minta sidik jari / wajah. Mengembalikan true kalau berhasil.
  Future<bool> authenticateBiometric(String reason) async {
    if (!state.biometricAvailable) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('biometrik gagal: $e');
      return false;
    }
  }

  Future<bool> unlockWithBiometric(String reason) async {
    if (!state.biometricEnabled) return false;
    final ok = await authenticateBiometric(reason);
    if (ok) {
      state = state.copyWith(
        locked: false,
        failedAttempts: 0,
        lockedOutUntil: () => null,
      );
    }
    return ok;
  }

  Future<bool> verifyPin(String pin) => _store.verify(pin);

  Future<void> enablePin(String pin) async {
    await _store.setPin(pin);
    state = state.copyWith(pinEnabled: true, locked: false);
  }

  Future<void> disablePin() async {
    await _store.clear();
    state = state.copyWith(
      pinEnabled: false,
      biometricEnabled: false,
      locked: false,
      failedAttempts: 0,
      lockedOutUntil: () => null,
    );
  }

  Future<void> setBiometric(bool enabled) async {
    await _store.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }
}
