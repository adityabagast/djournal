import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:url_launcher/url_launcher.dart';

import 'settings_repository.dart';

class GoogleDriveInfo {
  const GoogleDriveInfo({
    this.email,
    this.displayName,
    this.photoUrl,
    this.lastBackupTime,
    this.lastFileName,
    this.lastFileUrl,
    this.lastFileSize,
    this.isUploading = false,
    this.autoBackup = true,
  });

  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? lastBackupTime;
  final String? lastFileName;
  final String? lastFileUrl;
  final int? lastFileSize;
  final bool isUploading;
  final bool autoBackup;

  bool get isConnected => email != null;

  GoogleDriveInfo copyWith({
    String? Function()? email,
    String? Function()? displayName,
    String? Function()? photoUrl,
    DateTime? Function()? lastBackupTime,
    String? Function()? lastFileName,
    String? Function()? lastFileUrl,
    int? Function()? lastFileSize,
    bool? isUploading,
    bool? autoBackup,
  }) {
    return GoogleDriveInfo(
      email: email != null ? email() : this.email,
      displayName: displayName != null ? displayName() : this.displayName,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      lastBackupTime:
          lastBackupTime != null ? lastBackupTime() : this.lastBackupTime,
      lastFileName: lastFileName != null ? lastFileName() : this.lastFileName,
      lastFileUrl: lastFileUrl != null ? lastFileUrl() : this.lastFileUrl,
      lastFileSize: lastFileSize != null ? lastFileSize() : this.lastFileSize,
      isUploading: isUploading ?? this.isUploading,
      autoBackup: autoBackup ?? this.autoBackup,
    );
  }
}

class GoogleDriveService {
  GoogleDriveService(this._settings) {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        drive.DriveApi.driveFileScope,
      ],
    );
  }

  final SettingsRepository _settings;
  late final GoogleSignIn _googleSignIn;

  static const lastDriveBackupKey = 'gdrive_last_backup_time';
  static const lastDriveFileUrlKey = 'gdrive_last_file_url';
  static const lastDriveFileNameKey = 'gdrive_last_file_name';
  static const autoDriveBackupKey = 'gdrive_auto_backup';

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleDriveInfo> getInitialInfo() async {
    final lastTimeStr = await _settings.watch(lastDriveBackupKey).first;
    final lastUrl = await _settings.watch(lastDriveFileUrlKey).first;
    final lastName = await _settings.watch(lastDriveFileNameKey).first;
    final autoBackupVal = await _settings.watch(autoDriveBackupKey).first;

    DateTime? lastTime;
    if (lastTimeStr != null) {
      try {
        lastTime = DateTime.parse(lastTimeStr).toLocal();
      } catch (_) {}
    }

    GoogleSignInAccount? account = _googleSignIn.currentUser;
    try {
      account ??= await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('signInSilently error: $e');
    }

    return GoogleDriveInfo(
      email: account?.email,
      displayName: account?.displayName,
      photoUrl: account?.photoUrl,
      lastBackupTime: lastTime,
      lastFileName: lastName,
      lastFileUrl: lastUrl,
      autoBackup: autoBackupVal != 'false',
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }

  Future<drive.File?> uploadExcelBackup({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      var client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        final account = await _googleSignIn.signIn();
        if (account == null) return null;
        client = await _googleSignIn.authenticatedClient();
      }
      if (client == null) return null;

      final driveApi = drive.DriveApi(client);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      final fileToUpload = drive.File()
        ..name = fileName
        ..description = 'Cadangan data Nyawtat (Format Excel / Google Sheets)'
        ..mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      final created = await driveApi.files.create(
        fileToUpload,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink, createdTime, size',
      );

      final now = DateTime.now();
      await _settings.set(lastDriveBackupKey, now.toUtc().toIso8601String());
      if (created.webViewLink != null) {
        await _settings.set(lastDriveFileUrlKey, created.webViewLink!);
      }
      await _settings.set(lastDriveFileNameKey, fileName);

      return created;
    } catch (e) {
      debugPrint('Upload Excel to Drive error: $e');
      rethrow;
    }
  }

  Future<drive.File?> getLatestBackup() async {
    try {
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;

      final driveApi = drive.DriveApi(client);
      final fileList = await driveApi.files.list(
        q: "name contains 'Nyawtat' and mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' and trashed = false",
        orderBy: 'createdTime desc',
        pageSize: 1,
        $fields: 'files(id, name, createdTime, size, webViewLink, webContentLink)',
      );

      return fileList.files?.firstOrNull;
    } catch (e) {
      debugPrint('getLatestBackup error: $e');
      return null;
    }
  }

  Future<bool> openInGoogleSheets(String? webViewLink) async {
    if (webViewLink == null || webViewLink.isEmpty) return false;
    final uri = Uri.parse(webViewLink);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<List<int>?> downloadFile(String fileId) async {
    try {
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return null;

      final driveApi = drive.DriveApi(client);
      final res = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (res is drive.Media) {
        final chunks = <int>[];
        await for (final chunk in res.stream) {
          chunks.addAll(chunk);
        }
        return chunks;
      }
      return null;
    } catch (e) {
      debugPrint('downloadFile error: $e');
      return null;
    }
  }

  Future<void> setAutoBackup(bool enabled) async {
    await _settings.set(autoDriveBackupKey, enabled ? 'true' : 'false');
  }
}

