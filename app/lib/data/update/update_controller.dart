import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/platform_info.dart';
import '../../domain/models/release_info.dart';
import '../../providers/database_providers.dart';
import '../settings_repository.dart';
import 'update_service.dart';

enum UpdatePhase { idle, checking, upToDate, available, downloading, ready }

class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.release,
    this.progress = 0,
    this.apkPath,
    this.error,
    this.snoozed = false,
  });

  final UpdatePhase phase;
  final ReleaseInfo? release;

  /// 0–1 saat [UpdatePhase.downloading].
  final double progress;
  final String? apkPath;

  /// Kesalahan terakhir: network | checksum | permission | source.
  final String? error;

  /// User memilih "Nanti" untuk versi ini; kartu di Hari Ini disembunyikan.
  final bool snoozed;

  /// Kartu di Hari Ini tampil untuk versi baru yang belum ditunda, dan
  /// selalu tampil selama unduhan berjalan atau siap dipasang.
  bool get showCard => switch (phase) {
    UpdatePhase.available => !snoozed,
    UpdatePhase.downloading || UpdatePhase.ready => true,
    _ => false,
  };

  UpdateState copyWith({
    UpdatePhase? phase,
    ReleaseInfo? release,
    double? progress,
    String? apkPath,
    String? error,
    bool clearError = false,
    bool? snoozed,
  }) => UpdateState(
    phase: phase ?? this.phase,
    release: release ?? this.release,
    progress: progress ?? this.progress,
    apkPath: apkPath ?? this.apkPath,
    error: clearError ? null : (error ?? this.error),
    snoozed: snoozed ?? this.snoozed,
  );
}

const _keyAuto = 'update_auto';
const _keyLastCheck = 'update_last_check';
const _keySnooze = 'update_snooze';

final updateServiceProvider = Provider((ref) => UpdateService());

final appVersionProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Pengaturan › Tentang › Cek update otomatis (bawaan: aktif).
final updateAutoProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(_keyAuto)
      .map((v) => v != 'false'),
);

/// Waktu cek update terakhir (berhasil), null = belum pernah.
final updateLastCheckProvider = StreamProvider<DateTime?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(_keyLastCheck).map((v) {
    final ms = int.tryParse(v ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }),
);

final updateProvider = NotifierProvider<UpdateController, UpdateState>(
  UpdateController.new,
);

/// Alur cek → unduh → pasang. Unduhan dan pemasangan di dalam app hanya di
/// Android; platform lain membuka halaman rilis di browser.
class UpdateController extends Notifier<UpdateState> {
  bool _cancel = false;

  UpdateService get _service => ref.read(updateServiceProvider);
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  @override
  UpdateState build() => const UpdateState();

  /// Dipanggil saat app dibuka: paling sering sekali per ~20 jam, diam
  /// kalau gagal (mis. offline).
  Future<void> autoCheck() async {
    if (!PlatformInfo.isAndroid) return;
    if (await _settings.watch(_keyAuto).first == 'false') return;
    final last = int.tryParse(await _settings.watch(_keyLastCheck).first ?? '');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last != null && now - last < const Duration(hours: 20).inMilliseconds) {
      return;
    }
    await _clearDownloads();
    await check(silent: true);
  }

  Future<void> check({bool silent = false}) async {
    if (state.phase == UpdatePhase.checking ||
        state.phase == UpdatePhase.downloading) {
      return;
    }
    state = state.copyWith(phase: UpdatePhase.checking, clearError: true);
    try {
      final abi = PlatformInfo.isAndroid ? await _service.deviceAbi() : null;
      final release = await _service.fetchLatest(abi: abi);
      final current = (await ref.read(appVersionProvider.future)).version;
      await _settings.set(
        _keyLastCheck,
        '${DateTime.now().millisecondsSinceEpoch}',
      );
      if (compareVersions(release.version, current) > 0) {
        state = UpdateState(
          phase: UpdatePhase.available,
          release: release,
          snoozed: await _isSnoozed(release.version),
        );
      } else {
        state = UpdateState(phase: UpdatePhase.upToDate, release: release);
      }
    } on UpdateException catch (e) {
      state = UpdateState(
        phase: UpdatePhase.idle,
        error: silent ? null : e.kind,
      );
    } on Exception {
      state = UpdateState(
        phase: UpdatePhase.idle,
        error: silent ? null : 'network',
      );
    }
  }

  /// "Nanti": sembunyikan kartu versi ini sampai besok.
  Future<void> snooze() async {
    final r = state.release;
    if (r == null) return;
    _cancel = true;
    final until = DateTime.now().add(const Duration(days: 1));
    await _settings.set(
      _keySnooze,
      '${r.version}|${until.millisecondsSinceEpoch}',
    );
    state = state.copyWith(
      phase: state.phase == UpdatePhase.downloading
          ? UpdatePhase.available
          : state.phase,
      snoozed: true,
    );
  }

  Future<void> download() async {
    final r = state.release;
    if (r == null) return;
    if (!PlatformInfo.isAndroid || r.apkUrl == null) {
      await openReleasePage();
      return;
    }
    _cancel = false;
    state = state.copyWith(
      phase: UpdatePhase.downloading,
      progress: 0,
      clearError: true,
      snoozed: false,
    );
    final file = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'updates',
        'nyawtat-${r.version}.apk',
      ),
    );
    try {
      await _service.download(
        r,
        file,
        isCancelled: () => _cancel,
        onProgress: (v) {
          if (!_cancel) state = state.copyWith(progress: v);
        },
      );
      state = state.copyWith(
        phase: UpdatePhase.ready,
        progress: 1,
        apkPath: file.path,
      );
    } on UpdateException catch (e) {
      state = state.copyWith(
        phase: UpdatePhase.available,
        progress: 0,
        error: e.kind == 'cancelled' ? null : e.kind,
        clearError: e.kind == 'cancelled',
      );
    }
  }

  void cancelDownload() => _cancel = true;

  /// Buka layar pemasangan Android untuk APK yang sudah diunduh.
  Future<void> install() async {
    final path = state.apkPath;
    if (path == null) return;
    final result = await _service.install(path);
    state = result == 'permission'
        ? state.copyWith(error: 'permission')
        : state.copyWith(clearError: true);
  }

  Future<void> openReleasePage() async {
    final url = state.release?.pageUrl;
    final uri = Uri.parse(
      url == null || url.isEmpty
          ? 'https://github.com/${UpdateService.repo}/releases/latest'
          : url,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> setAuto(bool on) =>
      _settings.set(_keyAuto, on ? 'true' : 'false');

  Future<bool> _isSnoozed(String version) async {
    final v = await _settings.watch(_keySnooze).first;
    if (v == null) return false;
    final parts = v.split('|');
    final until = int.tryParse(parts.length == 2 ? parts[1] : '') ?? 0;
    return parts.first == version &&
        DateTime.now().millisecondsSinceEpoch < until;
  }

  /// APK lama dari unduhan sebelumnya tidak dibutuhkan lagi.
  Future<void> _clearDownloads() async {
    try {
      final dir = Directory(
        p.join((await getTemporaryDirectory()).path, 'updates'),
      );
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      // Biarkan; dicoba lagi saat cek berikutnya.
    }
  }
}
