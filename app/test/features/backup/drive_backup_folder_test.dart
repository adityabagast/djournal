import 'dart:convert';

import 'package:djournal/features/backup/data/drive_backup_folder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

/// Drive tiruan: mencatat request, menjawab daftar folder sesuai [folders].
class _FakeDrive {
  _FakeDrive({this.folders = const [], this.createFolderStatus = 200});

  final List<String> folders;
  final int createFolderStatus;
  final requests = <http.Request>[];

  late final api = drive.DriveApi(MockClient((req) async {
    requests.add(req);
    if (req.method == 'GET') {
      return http.Response(
        jsonEncode({
          'files': [
            for (final id in folders) {'id': id},
          ],
        }),
        200,
        headers: _json,
      );
    }
    if (_isUpload(req)) {
      return http.Response(
        jsonEncode({'id': 'file-1', 'webViewLink': 'https://example.test/f'}),
        200,
        headers: _json,
      );
    }
    return http.Response(
      jsonEncode(
        createFolderStatus == 200
            ? {'id': 'folder-baru'}
            : {
                'error': {'code': createFolderStatus, 'message': 'ditolak'},
              },
      ),
      createFolderStatus,
      headers: _json,
    );
  }));

  static bool _isUpload(http.Request r) => r.url.path.contains('/upload/');

  List<http.Request> get uploads => requests.where(_isUpload).toList();

  List<http.Request> get folderCreates => requests
      .where((r) => r.method == 'POST' && !_isUpload(r))
      .toList();
}

Future<drive.File> _upload(_FakeDrive fake) => uploadBackupToFolder(
      fake.api,
      bytes: utf8.encode('dummy'),
      fileName: 'Nyawtat_Cadangan_dummy.xlsx',
    );

void main() {
  test('folder belum ada: dibuat dengan penanda, backup masuk ke sana',
      () async {
    final fake = _FakeDrive();

    final file = await _upload(fake);

    final body = jsonDecode(fake.folderCreates.single.body) as Map;
    expect(body['name'], 'Nyawtat');
    expect(body['mimeType'], 'application/vnd.google-apps.folder');
    expect(body['appProperties'], {'nyawtat': 'backup'});
    expect(fake.uploads.single.body, contains('"parents":["folder-baru"]'));
    expect(file.id, 'file-1');
  });

  test('folder sudah ada: dipakai ulang, tidak membuat folder kedua',
      () async {
    final fake = _FakeDrive(folders: ['folder-lama']);

    await _upload(fake);

    expect(fake.folderCreates, isEmpty);
    expect(fake.uploads.single.body, contains('"parents":["folder-lama"]'));
  });

  test('pencarian folder lewat penanda, milik sendiri, bukan di sampah',
      () async {
    final fake = _FakeDrive(folders: ['folder-lama']);

    await _upload(fake);

    final q = fake.requests.first.url.queryParameters['q']!;
    expect(q, contains("appProperties has { key='nyawtat' and value='backup' }"));
    expect(q, contains("mimeType = 'application/vnd.google-apps.folder'"));
    expect(q, contains("'me' in owners"));
    expect(q, contains('trashed = false'));
    expect(q, isNot(contains('name')));
  });

  test('gagal membuat folder: backup gagal, tidak jatuh ke My Drive',
      () async {
    final fake = _FakeDrive(createFolderStatus: 403);

    await expectLater(
      _upload(fake),
      throwsA(isA<drive.DetailedApiRequestError>()),
    );
    expect(fake.uploads, isEmpty);
  });
}
