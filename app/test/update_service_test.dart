import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:djournal/data/update/update_service.dart';
import 'package:djournal/domain/models/release_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final bytes = List<int>.generate(4096, (i) => i % 251);
  final goodSha = sha256.convert(bytes).toString();
  const url =
      'https://github.com/adityabagast/djournal/releases/download/v0.12.0/app-arm64-v8a-release.apk';

  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('upd'));
  tearDown(() => tmp.delete(recursive: true));

  UpdateService service() => UpdateService(
    client: MockClient((_) async => http.Response.bytes(bytes, 200)),
  );

  ReleaseInfo release({String apkUrl = url, String? sha}) => ReleaseInfo(
    version: '0.12.0',
    notes: '',
    pageUrl: '',
    apkUrl: apkUrl,
    apkSize: bytes.length,
    apkSha256: sha,
  );

  test('checksum cocok: file tersimpan dan progres sampai 100%', () async {
    final file = File('${tmp.path}/a.apk');
    var last = 0.0;
    await service().download(
      release(sha: goodSha),
      file,
      onProgress: (v) => last = v,
      isCancelled: () => false,
    );
    expect(await file.readAsBytes(), bytes);
    expect(last, 1.0);
  });

  test('checksum tidak cocok: ditolak dan file dihapus', () async {
    final file = File('${tmp.path}/b.apk');
    await expectLater(
      service().download(
        release(sha: '0' * 64),
        file,
        onProgress: (_) {},
        isCancelled: () => false,
      ),
      throwsA(isA<UpdateException>().having((e) => e.kind, 'kind', 'checksum')),
    );
    expect(await file.exists(), isFalse);
  });

  test('URL di luar rilis repo ini ditolak sebelum diunduh', () async {
    await expectLater(
      service().download(
        release(apkUrl: 'https://example.com/app.apk'),
        File('${tmp.path}/c.apk'),
        onProgress: (_) {},
        isCancelled: () => false,
      ),
      throwsA(isA<UpdateException>().having((e) => e.kind, 'kind', 'source')),
    );
  });

  test('cek update: kode HTTP dibedakan, bukan semua "jaringan"', () async {
    for (final (code, kind) in [
      (404, 'notfound'),
      (403, 'ratelimit'),
      (429, 'ratelimit'),
      (500, 'server'),
    ]) {
      final svc = UpdateService(
        client: MockClient((_) async => http.Response('', code)),
      );
      await expectLater(
        svc.fetchLatest(),
        throwsA(isA<UpdateException>().having((e) => e.kind, 'kind', kind)),
        reason: 'HTTP $code',
      );
    }
  });
}
