import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN aplikasi di secure storage OS (Android Keystore / iOS Keychain),
/// sesuai docs/data-model.md §4.7: PIN tidak pernah disimpan di SQLite.
/// Yang disimpan hanya salt + hash, bukan PIN-nya.
class PinStore {
  PinStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _pinKey = 'app_pin';
  static const _biometricKey = 'app_pin_biometric';
  static const pinLength = 4;

  /// Diulang supaya menebak PIN dari hash butuh waktu (PIN hanya 4 angka).
  static const _iterations = 20000;

  Future<bool> hasPin() => _storage.containsKey(key: _pinKey);

  Future<void> setPin(String pin) async {
    _check(pin);
    final salt = _randomBytes(16);
    final hash = _hash(pin, salt);
    await _storage.write(
      key: _pinKey,
      value: '${base64Encode(salt)}:${base64Encode(hash)}',
    );
  }

  Future<bool> verify(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final expected = base64Decode(parts[1]);
    final actual = _hash(pin, base64Decode(parts[0]));
    // Bandingkan semua byte (waktu konstan).
    var diff = expected.length ^ actual.length;
    for (var i = 0; i < expected.length && i < actual.length; i++) {
      diff |= expected[i] ^ actual[i];
    }
    return diff == 0;
  }

  Future<void> clear() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);
  }

  Future<bool> biometricEnabled() async =>
      await _storage.read(key: _biometricKey) == 'true';

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricKey, value: '$enabled');

  static void _check(String pin) {
    if (pin.length != pinLength || int.tryParse(pin) == null) {
      throw ArgumentError('PIN harus $pinLength angka');
    }
  }

  static List<int> _hash(String pin, List<int> salt) {
    var digest = sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert([...digest, ...salt]).bytes;
    }
    return digest;
  }

  static List<int> _randomBytes(int n) {
    final random = Random.secure();
    return List<int>.generate(n, (_) => random.nextInt(256));
  }
}
