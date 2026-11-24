import 'package:googleapis/drive/v3.dart' as drive;

const _folderName = 'Nyawtat';
const _folderMime = 'application/vnd.google-apps.folder';
const _excelMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Penanda tersembunyi di folder buatan app, supaya folder tetap ditemukan
/// walau diganti nama atau dipindahkan user. Jangan diubah: folder lama tidak
/// akan dikenali lagi.
const _markerKey = 'nyawtat';
const _markerValue = 'backup';

/// Id folder backup di akun Drive yang aktif; dibuat kalau belum ada.
/// Id tidak disimpan di HP supaya tetap benar saat ganti akun atau folder
/// dihapus.
Future<String> _ensureBackupFolder(drive.DriveApi api) async {
  final found = await api.files.list(
    q: "appProperties has { key='$_markerKey' and value='$_markerValue' } "
        "and mimeType = '$_folderMime' "
        "and 'me' in owners and trashed = false",
    orderBy: 'createdTime',
    pageSize: 1,
    $fields: 'files(id)',
  );
  final existing = found.files?.firstOrNull?.id;
  if (existing != null) return existing;

  final created = await api.files.create(
    drive.File()
      ..name = _folderName
      ..mimeType = _folderMime
      ..appProperties = {_markerKey: _markerValue},
    $fields: 'id',
  );
  return created.id!;
}

/// Unggah backup Excel ke folder Nyawtat. Kalau foldernya gagal disiapkan,
/// error diteruskan dan file tidak diunggah ke My Drive.
Future<drive.File> uploadBackupToFolder(
  drive.DriveApi api, {
  required List<int> bytes,
  required String fileName,
}) async {
  final folderId = await _ensureBackupFolder(api);
  return api.files.create(
    drive.File()
      ..name = fileName
      ..description = 'Cadangan data Nyawtat (Format Excel / Google Sheets)'
      ..mimeType = _excelMime
      ..parents = [folderId],
    uploadMedia: drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: _excelMime,
    ),
    $fields: 'id, name, webViewLink, webContentLink, createdTime, size',
  );
}
