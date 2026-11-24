import 'dart:convert';

import 'package:archive/archive.dart';

/// Data pemulihan di sheet `_Data_Sistem`: satu string per sel kolom A.
///
/// Excel hanya menerima 32.767 karakter per sel, jadi JSON di-gzip, dijadikan
/// base64 (aman dari perubahan spasi/baris baru saat file disimpan ulang),
/// lalu dipotong. Awalan [_prefix] mencegah potongan terbaca sebagai angka.
const _marker = 'nyawtat-backup:gzip-base64:1';
const _prefix = 'z';
const _chunkSize = 30000;

List<String> encodeBackupPayload(String json) {
  final data = base64.encode(GZipEncoder().encode(utf8.encode(json))!);
  return [
    _marker,
    for (var i = 0; i < data.length; i += _chunkSize)
      _prefix +
          data.substring(
            i,
            i + _chunkSize < data.length ? i + _chunkSize : data.length,
          ),
  ];
}

/// JSON pemulihan, atau null kalau sel-selnya bukan backup Nyawtat yang utuh.
String? decodeBackupPayload(List<String> cells) {
  if (cells.isEmpty) return null;
  final first = cells.first.trim();
  if (first != _marker) return first.startsWith('{') ? cells.first : null;
  try {
    final data = StringBuffer();
    for (final c in cells.skip(1)) {
      final t = c.trim();
      if (t.isEmpty) continue;
      if (!t.startsWith(_prefix)) return null;
      data.write(t.substring(_prefix.length));
    }
    final bytes = base64.decode(data.toString());
    if (bytes.length < 18) return null;
    final out = GZipDecoder().decodeBytes(bytes, verify: true);
    // 4 byte terakhir gzip = panjang asli; memastikan tidak ada yang hilang.
    final n = bytes.length;
    final size = bytes[n - 4] |
        bytes[n - 3] << 8 |
        bytes[n - 2] << 16 |
        bytes[n - 1] << 24;
    if (out.length != size || getCrc32(out) != _crcOf(bytes)) return null;
    return utf8.decode(out);
  } catch (_) {
    return null;
  }
}

int _crcOf(List<int> gz) {
  final n = gz.length;
  return gz[n - 8] | gz[n - 7] << 8 | gz[n - 6] << 16 | gz[n - 5] << 24;
}
