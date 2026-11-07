import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/release_info.dart';

class UpdateException implements Exception {
  const UpdateException(this.kind);

  /// network | notfound | ratelimit | server | checksum | cancelled | source
  final String kind;

  @override
  String toString() => 'UpdateException($kind)';
}

/// Cek dan unduh rilis baru dari GitHub (repo publik, tanpa token).
/// Yang dikirim hanya permintaan baca daftar rilis; tidak ada data user.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const repo = 'adityabagast/djournal';
  static const _channel = MethodChannel('nyawtat/update');

  final http.Client _client;

  /// ABI utama HP (mis. 'arm64-v8a') untuk memilih APK yang cocok.
  Future<String?> deviceAbi() => _channel.invokeMethod<String>('abi');

  Future<ReleaseInfo> fetchLatest({String? abi}) async {
    final http.Response res;
    try {
      res = await _client
          .get(
            Uri.https('api.github.com', '/repos/$repo/releases/latest'),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const UpdateException('network');
    }
    if (res.statusCode == 404) throw const UpdateException('notfound');
    if (res.statusCode == 403 || res.statusCode == 429) {
      throw const UpdateException('ratelimit');
    }
    if (res.statusCode != 200) throw const UpdateException('server');
    return ReleaseInfo.fromGitHub(
      jsonDecode(res.body) as Map<String, dynamic>,
      abi: abi,
    );
  }

  /// Unduh APK [release] ke [file] sambil melapor progres 0–1. Checksum
  /// dicocokkan di akhir; file dihapus kalau tidak cocok atau dibatalkan.
  Future<void> download(
    ReleaseInfo release,
    File file, {
    required void Function(double progress) onProgress,
    required bool Function() isCancelled,
  }) async {
    final url = release.apkUrl;
    // Hanya file rilis dari repo ini sendiri.
    if (url == null ||
        !url.startsWith('https://github.com/$repo/releases/download/')) {
      throw const UpdateException('source');
    }
    final http.StreamedResponse res;
    try {
      res = await _client.send(http.Request('GET', Uri.parse(url)));
    } on Exception {
      throw const UpdateException('network');
    }
    if (res.statusCode != 200) throw const UpdateException('network');

    final total = res.contentLength ?? release.apkSize ?? 0;
    await file.parent.create(recursive: true);
    final out = file.openWrite();
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    var received = 0;
    try {
      await for (final chunk in res.stream) {
        if (isCancelled()) throw const UpdateException('cancelled');
        out.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      hasher.close();
      await out.close();
    } on UpdateException {
      await out.close();
      await _deleteQuietly(file);
      rethrow;
    } on Exception {
      await out.close();
      await _deleteQuietly(file);
      throw const UpdateException('network');
    }

    final expected = release.apkSha256;
    if (expected != null && digest.value.toString() != expected) {
      await _deleteQuietly(file);
      throw const UpdateException('checksum');
    }
  }

  /// Buka layar pemasangan Android. Hasil: 'started', atau 'permission'
  /// kalau user perlu mengizinkan "Instal aplikasi tak dikenal" dulu (layar
  /// izinnya sudah dibuka).
  Future<String> install(String path) async =>
      await _channel.invokeMethod<String>('installApk', {'path': path}) ??
      'started';

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Biarkan; folder cache dibersihkan saat cek berikutnya.
    }
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
