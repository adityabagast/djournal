import 'package:djournal/features/update/domain/release_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sha =
      'a3f1c2d4e5f60718293a4b5c6d7e8f90112233445566778899aabbccddeeff00';

  Map<String, dynamic> release({String body = '', bool digest = true}) => {
    'tag_name': 'v0.12.0',
    'html_url': 'https://github.com/adityabagast/djournal/releases/tag/v0.12.0',
    'published_at': '2026-11-09T03:00:00Z',
    'body': body,
    'assets': [
      {
        'name': 'app-armeabi-v7a-release.apk',
        'browser_download_url': 'https://github.com/adityabagast/djournal/releases/download/v0.12.0/app-armeabi-v7a-release.apk',
        'size': 23000000,
      },
      {
        'name': 'app-arm64-v8a-release.apk',
        'browser_download_url': 'https://github.com/adityabagast/djournal/releases/download/v0.12.0/app-arm64-v8a-release.apk',
        'size': 25165824,
        if (digest) 'digest': 'sha256:${sha.toUpperCase()}',
      },
    ],
  };

  test('compareVersions membandingkan per angka', () {
    expect(compareVersions('0.12.0', '0.11.0'), greaterThan(0));
    expect(compareVersions('0.10.0', '0.9.3'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('0.11.0+14', '0.11.0'), 0);
    expect(compareVersions('0.11.0', '0.11.1'), lessThan(0));
  });

  test('memilih APK sesuai ABI dan membaca checksum dari digest', () {
    final r = ReleaseInfo.fromGitHub(release(), abi: 'arm64-v8a');
    expect(r.version, '0.12.0');
    expect(r.apkUrl, endsWith('app-arm64-v8a-release.apk'));
    expect(r.apkSize, 25165824);
    expect(r.apkSha256, sha);
    expect(r.publishedAt, DateTime.utc(2026, 11, 9, 3));
  });

  test('checksum cadangan dari catatan rilis; tanpa ABI = tanpa APK', () {
    final body = 'SHA-256\n- app-arm64-v8a-release.apk: $sha\n';
    final r = ReleaseInfo.fromGitHub(
      release(body: body, digest: false),
      abi: 'arm64-v8a',
    );
    expect(r.apkSha256, sha);
    final none = ReleaseInfo.fromGitHub(release());
    expect((none.apkUrl, none.apkSha256), (null, null));
  });

  test('catatan rilis dibersihkan dan berhenti di bagian Unduh', () {
    const body =
        '# Nyawtat 0.12.0\n\nVersi **baru**.\n\n## Baru\n'
        '- **Pengingat** menulis\n- Lihat [CHANGELOG](https://x.y)\n\n'
        '## Unduh\n- app-arm64-v8a-release.apk';
    expect(
      cleanReleaseNotes(body),
      'Versi baru.\n\nBaru\n• Pengingat menulis\n• Lihat CHANGELOG',
    );
  });
}
