/// Rilis Nyawtat di GitHub, hasil baca API `releases/latest`.
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    this.publishedAt,
    this.apkUrl,
    this.apkSize,
    this.apkSha256,
  });

  /// Tanpa awalan "v", mis. "0.12.0".
  final String version;

  /// Isi catatan rilis yang sudah dibersihkan dari markdown, hanya bagian
  /// sebelum "Unduh"/"Download".
  final String notes;
  final String pageUrl;
  final DateTime? publishedAt;

  /// APK untuk ABI HP ini; null = tidak ada file yang cocok (buka halaman
  /// rilis saja).
  final String? apkUrl;
  final int? apkSize;

  /// Hex kecil; null = rilis tidak mencantumkan checksum.
  final String? apkSha256;

  /// [abi] memakai nama folder Android: 'arm64-v8a', 'armeabi-v7a', 'x86_64'.
  factory ReleaseInfo.fromGitHub(Map<String, dynamic> json, {String? abi}) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final body = json['body'] as String? ?? '';
    final assets = (json['assets'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final apkName = abi == null ? null : 'app-$abi-release.apk';
    final asset = apkName == null
        ? null
        : assets.where((a) => a['name'] == apkName).firstOrNull;

    String? sha;
    final digest = asset?['digest'] as String?;
    if (digest != null && digest.startsWith('sha256:')) {
      sha = digest.substring(7).toLowerCase();
    } else if (apkName != null) {
      // Cadangan: checksum ditulis di catatan rilis, sebaris dengan nama file.
      for (final line in body.split('\n')) {
        if (!line.contains(apkName)) continue;
        final m = RegExp(r'\b[0-9a-fA-F]{64}\b').firstMatch(line);
        if (m != null) {
          sha = m.group(0)!.toLowerCase();
          break;
        }
      }
    }

    return ReleaseInfo(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      notes: cleanReleaseNotes(body),
      pageUrl: json['html_url'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      apkUrl: asset?['browser_download_url'] as String?,
      apkSize: (asset?['size'] as num?)?.toInt(),
      apkSha256: sha,
    );
  }
}

/// Bandingkan versi "a.b.c" per angka. Bagian non-angka (mis. "-beta")
/// diabaikan. Hasil < 0 kalau [a] lebih lama dari [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(RegExp(r'^\d+').stringMatch(p) ?? '') ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// Catatan rilis jadi teks polos: berhenti di bagian unduhan, buang judul
/// utama, tanda markdown, dan tautan (teksnya tetap).
String cleanReleaseNotes(String body) {
  final out = <String>[];
  for (final raw in body.split('\n')) {
    var line = raw.trimRight();
    final heading = RegExp(r'^#{1,6}\s*').firstMatch(line);
    if (heading != null) {
      final title = line.substring(heading.end).trim().toLowerCase();
      if (title.startsWith('unduh') || title.startsWith('download')) break;
      if (heading.group(0)!.trim() == '#') continue;
      line = line.substring(heading.end).trim();
    }
    line = line
        .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll('**', '')
        .replaceAll('`', '')
        .replaceFirst(RegExp(r'^\s*[-*]\s+'), '• ');
    if (line.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
    out.add(line);
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return out.join('\n');
}
