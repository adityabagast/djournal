import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Kode error yang diterjemahkan di UI.
enum ApiError {
  network,
  invalidCredentials,
  emailTaken,
  invalidEmail,
  passwordTooShort,
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

class AuthTokens {
  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthTokens.fromLogin(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    // Kurangi 1 menit supaya token diperbarui sebelum benar-benar kedaluwarsa.
    expiresAt: DateTime.now().add(
      Duration(seconds: (json['expiresIn'] as num).toInt() - 60),
    ),
  );

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };
}

/// Token dan email disimpan di secure storage OS (Android Keystore /
/// iOS Keychain), bukan di SQLite.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tokensKey = 'auth_tokens';
  static const _emailKey = 'auth_email';

  Future<AuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null) return null;
    return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<void> save(AuthTokens tokens, {String? email}) async {
    await _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
    if (email != null) await _storage.write(key: _emailKey, value: email);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokensKey);
    await _storage.delete(key: _emailKey);
  }
}

/// Klien HTTP untuk server djournal (server/README.md). Token diperbarui
/// otomatis lewat /refresh saat kedaluwarsa atau ditolak (401).
class ApiClient {
  ApiClient({required this.baseUrl, required this.tokens, http.Client? client})
    : _http = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _http;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<void> register(String email, String password) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/auth/register'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (res.statusCode == 200) return;
    if (res.statusCode == 400) throw _registerError(res.body);
    throw ApiException(ApiError.server, 'HTTP ${res.statusCode}');
  }

  Future<void> login(String email, String password) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/auth/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (res.statusCode == 401) throw ApiException(ApiError.invalidCredentials);
    _ensureOk(res);
    await tokens.save(
      AuthTokens.fromLogin(jsonDecode(res.body) as Map<String, dynamic>),
      email: email,
    );
  }

  Future<Map<String, dynamic>> push(Map<String, dynamic> body) async {
    final res = await _authorized(
      (token) => _http.post(
        _uri('/api/sync/push'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      ),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pull(int since) async {
    final res = await _authorized(
      (token) => _http.get(
        _uri('/api/sync/pull', {'since': '$since'}),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  /// Kirim request ber-token; perbarui token sekali kalau kedaluwarsa/401.
  Future<http.Response> _authorized(
    Future<http.Response> Function(String token) send,
  ) async {
    final stored = await tokens.readTokens();
    if (stored == null) throw ApiException(ApiError.sessionExpired);
    var current = DateTime.now().isAfter(stored.expiresAt)
        ? await _refresh(stored)
        : stored;

    var res = await _send(() => send(current.accessToken));
    if (res.statusCode == 401) {
      current = await _refresh(current);
      res = await _send(() => send(current.accessToken));
    }
    if (res.statusCode == 401) throw ApiException(ApiError.sessionExpired);
    _ensureOk(res);
    return res;
  }

  Future<AuthTokens> _refresh(AuthTokens old) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/auth/refresh'),
        headers: _jsonHeaders,
        body: jsonEncode({'refreshToken': old.refreshToken}),
      ),
    );
    if (res.statusCode == 401) throw ApiException(ApiError.sessionExpired);
    _ensureOk(res);
    final fresh = AuthTokens.fromLogin(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
    await tokens.save(fresh);
    return fresh;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Server mati, salah alamat, tidak ada internet, timeout, CORS, dst.
      throw ApiException(ApiError.network, '$e');
    }
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? detail;
    try {
      detail =
          (jsonDecode(res.body) as Map<String, dynamic>)['detail'] as String?;
    } catch (_) {}
    throw ApiException(ApiError.server, detail ?? 'HTTP ${res.statusCode}');
  }

  /// Error validasi Identity: {"errors": {"DuplicateUserName": [...], ...}}
  ApiException _registerError(String body) {
    Map<String, dynamic> errors = const {};
    try {
      errors =
          (jsonDecode(body) as Map<String, dynamic>)['errors']
              as Map<String, dynamic>? ??
          const {};
    } catch (_) {}
    if (errors.containsKey('DuplicateUserName') ||
        errors.containsKey('DuplicateEmail')) {
      return ApiException(ApiError.emailTaken);
    }
    if (errors.containsKey('InvalidEmail') ||
        errors.containsKey('InvalidUserName')) {
      return ApiException(ApiError.invalidEmail);
    }
    if (errors.containsKey('PasswordTooShort')) {
      return ApiException(ApiError.passwordTooShort);
    }
    return ApiException(ApiError.server, errors.keys.join(', '));
  }
}
