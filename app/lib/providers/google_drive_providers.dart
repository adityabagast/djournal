import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/google_drive_service.dart';
import '../providers.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService(ref.watch(settingsRepositoryProvider));
});

class GoogleDriveController extends Notifier<GoogleDriveInfo> {
  @override
  GoogleDriveInfo build() {
    Future.microtask(_init);
    return const GoogleDriveInfo();
  }

  GoogleDriveService get _service => ref.read(googleDriveServiceProvider);

  Future<void> _init() async {
    final info = await _service.getInitialInfo();
    state = info;
  }

  Future<void> signIn() async {
    final account = await _service.signIn();
    if (account != null) {
      state = state.copyWith(
        email: () => account.email,
        displayName: () => account.displayName,
        photoUrl: () => account.photoUrl,
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = state.copyWith(
      email: () => null,
      displayName: () => null,
      photoUrl: () => null,
    );
  }

  Future<void> toggleAutoBackup() async {
    final updated = !state.autoBackup;
    await _service.setAutoBackup(updated);
    state = state.copyWith(autoBackup: updated);
  }

  Future<bool> backupToDrive({
    required List<int> bytes,
    required String fileName,
  }) async {
    state = state.copyWith(isUploading: true);
    try {
      final file = await _service.uploadExcelBackup(
        bytes: bytes,
        fileName: fileName,
      );
      if (file != null) {
        state = state.copyWith(
          isUploading: false,
          lastBackupTime: () => DateTime.now(),
          lastFileName: () => fileName,
          lastFileUrl: () => file.webViewLink,
        );
        return true;
      }
    } catch (_) {
      state = state.copyWith(isUploading: false);
      rethrow;
    }
    state = state.copyWith(isUploading: false);
    return false;
  }

  Future<bool> openInSheets() async {
    return await _service.openInGoogleSheets(state.lastFileUrl);
  }
}

final googleDriveProvider =
    NotifierProvider<GoogleDriveController, GoogleDriveInfo>(
  GoogleDriveController.new,
);

