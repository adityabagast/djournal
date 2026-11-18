import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kode error yang diterjemahkan di UI.
enum ApiError {
  network,
  invalidCredentials,
  emailTaken,
  invalidEmail,
  passwordTooShort,
  confirmEmail,
  sessionExpired,
  server,
}

class ApiException implements Exception {
  ApiException(this.error, [this.detail]);

  final ApiError error;
  final String? detail;

  @override
  String toString() => 'ApiException($error, $detail)';
}

/// Yang dibutuhkan SyncEngine dari server: kirim perubahan, ambil perubahan.
abstract interface class SyncApi {
  Future<Map<String, dynamic>> push(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> pull(int since);
}

/// Login dan sync lewat Supabase. Sync memanggil fungsi SQL
/// `sync_push` / `sync_pull` (supabase/migrations).
class SupabaseBackend implements SyncApi {
  SupabaseBackend(this.client);

  final SupabaseClient client;

  static const _timeout = Duration(seconds: 30);

  String? get currentEmail => client.auth.currentUser?.email;

  Future<void> signUp(String email, String password) => _guard(() async {
    final res = await client.auth.signUp(email: email, password: password);
    // Kalau "Confirm email" menyala di dashboard, belum ada sesi sampai
    // user mengklik link di email.
    if (res.session == null) throw ApiException(ApiError.confirmEmail);
  });

  Future<void> signIn(String email, String password) => _guard(
    () => client.auth.signInWithPassword(email: email, password: password),
  );

  Future<void> signOut() => _guard(() => client.auth.signOut());

  @override
  Future<Map<String, dynamic>> push(Map<String, dynamic> payload) =>
      _guard(() async {
        final res = await client
            .rpc('sync_push', params: {'payload': payload})
            .timeout(_timeout);
        return Map<String, dynamic>.from(res as Map);
      });

  @override
  Future<Map<String, dynamic>> pull(int since) => _guard(() async {
    final res = await client
        .rpc('sync_pull', params: {'since': since})
        .timeout(_timeout);
    return Map<String, dynamic>.from(res as Map);
  });

  /// Terjemahkan error Supabase / jaringan ke [ApiError].
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException {
      rethrow;
    } on AuthRetryableFetchException catch (e) {
      throw ApiException(ApiError.network, e.message);
    } on AuthSessionMissingException catch (e) {
      throw ApiException(ApiError.sessionExpired, e.message);
    } on AuthWeakPasswordException catch (e) {
      throw ApiException(ApiError.passwordTooShort, e.message);
    } on AuthException catch (e) {
      throw ApiException(switch (e.code) {
        'invalid_credentials' => ApiError.invalidCredentials,
        'user_already_exists' || 'email_exists' => ApiError.emailTaken,
        'email_address_invalid' || 'validation_failed' => ApiError.invalidEmail,
        'weak_password' => ApiError.passwordTooShort,
        'email_not_confirmed' => ApiError.confirmEmail,
        'session_not_found' ||
        'refresh_token_not_found' => ApiError.sessionExpired,
        _ => ApiError.server,
      }, e.message);
    } on PostgrestException catch (e) {
      // 42501 = belum login / token tidak valid (dari fungsi sync).
      if (e.code == '42501' || e.code == 'PGRST301' || e.code == 'PGRST303') {
        throw ApiException(ApiError.sessionExpired, e.message);
      }
      throw ApiException(ApiError.server, '${e.code}: ${e.message}');
    } on TimeoutException {
      throw ApiException(ApiError.network, 'timeout');
    } on http.ClientException catch (e) {
      // Tidak ada internet, DNS gagal, koneksi putus, dst.
      throw ApiException(ApiError.network, e.message);
    }
  }
}

/// Simpan sesi login (access + refresh token) di secure storage OS
/// (Android Keystore / iOS Keychain), bukan di SharedPreferences.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _storage = FlutterSecureStorage();
  static const _key = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
