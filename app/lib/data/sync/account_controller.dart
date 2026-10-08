import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'api_client.dart';
import 'sync_engine.dart';

/// Alamat server default. Di HP via USB pakai `adb reverse tcp:5095 tcp:5095`
/// supaya localhost di HP diteruskan ke laptop.
const defaultServerUrl = 'http://localhost:5095';
const serverUrlKey = 'server_url';

@immutable
class AccountState {
  const AccountState({
    this.loading = true,
    this.email,
    this.serverUrl = defaultServerUrl,
    this.syncing = false,
    this.lastSyncAt,
    this.error,
  });

  final bool loading;

  /// null = belum login (app tetap bisa dipakai offline).
  final String? email;
  final String serverUrl;
  final bool syncing;
  final DateTime? lastSyncAt;

  /// Error sync terakhir; null kalau sukses.
  final ApiError? error;

  bool get loggedIn => email != null;

  AccountState copyWith({
    bool? loading,
    String? Function()? email,
    String? serverUrl,
    bool? syncing,
    DateTime? Function()? lastSyncAt,
    ApiError? Function()? error,
  }) => AccountState(
    loading: loading ?? this.loading,
    email: email != null ? email() : this.email,
    serverUrl: serverUrl ?? this.serverUrl,
    syncing: syncing ?? this.syncing,
    lastSyncAt: lastSyncAt != null ? lastSyncAt() : this.lastSyncAt,
    error: error != null ? error() : this.error,
  );
}

final tokenStoreProvider = Provider((ref) => TokenStore());

final accountProvider = NotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

/// Login, logout, dan sinkronisasi otomatis. Mirip "service" stateful di
/// .NET yang di-inject ke UI; UI cukup ref.watch(accountProvider).
class AccountController extends Notifier<AccountState> {
  StreamSubscription<void>? _dbChanges;
  Timer? _debounce;
  bool _rerun = false;

  @override
  AccountState build() {
    ref.onDispose(() {
      _dbChanges?.cancel();
      _debounce?.cancel();
    });
    Future.microtask(_init);
    return const AccountState();
  }

  ApiClient _api() =>
      ApiClient(baseUrl: state.serverUrl, tokens: ref.read(tokenStoreProvider));

  SyncEngine _engine() => SyncEngine(ref.read(databaseProvider), _api());

  Future<void> _init() async {
    final settings = ref.read(settingsRepositoryProvider);
    final url = await settings.watch(serverUrlKey).first;
    final last = await settings.watch(SyncEngine.lastSyncKey).first;
    final email = await ref.read(tokenStoreProvider).readEmail();
    state = state.copyWith(
      loading: false,
      serverUrl: url ?? defaultServerUrl,
      email: () => email,
      lastSyncAt: () => last == null ? null : DateTime.parse(last).toLocal(),
    );

    // Setiap ada perubahan data lokal: tunggu 3 detik tenang, lalu sync.
    final db = ref.read(databaseProvider);
    _dbChanges = db.tableUpdates().listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), _syncIfDirty);
    });

    if (state.loggedIn) unawaited(sync());
  }

  Future<void> _syncIfDirty() async {
    if (!state.loggedIn || state.syncing) return;
    if (await _engine().hasDirtyRows()) await sync();
  }

  /// Satu siklus push → pull. Aman dipanggil berkali-kali.
  Future<void> sync() async {
    if (!state.loggedIn) return;
    if (state.syncing) {
      _rerun = true;
      return;
    }
    state = state.copyWith(syncing: true);
    try {
      final at = await _engine().run();
      state = state.copyWith(
        syncing: false,
        lastSyncAt: () => at,
        error: () => null,
      );
    } on ApiException catch (e) {
      state = state.copyWith(syncing: false, error: () => e.error);
    } catch (e, st) {
      debugPrint('sync gagal: $e\n$st');
      state = state.copyWith(syncing: false, error: () => ApiError.server);
    }
    if (_rerun) {
      _rerun = false;
      unawaited(sync());
    }
  }

  /// Lempar [ApiException] kalau gagal, supaya form bisa menampilkan pesan.
  Future<void> signIn({
    required String serverUrl,
    required String email,
    required String password,
    required bool register,
  }) async {
    final url = serverUrl.trim();
    await ref.read(settingsRepositoryProvider).set(serverUrlKey, url);
    state = state.copyWith(serverUrl: url);

    final api = _api();
    final cleanEmail = email.trim().toLowerCase();
    if (register) await api.register(cleanEmail, password);
    await api.login(cleanEmail, password);

    state = state.copyWith(email: () => cleanEmail, error: () => null);
    unawaited(sync());
  }

  /// Logout: coba sync terakhir, hapus token, lalu kosongkan data di HP
  /// (data aman di server dan akan kembali saat login lagi).
  Future<void> signOut() async {
    try {
      await _engine().run();
    } catch (_) {
      // Tetap logout walau offline; pemanggil sudah memperingatkan user.
    }
    await ref.read(tokenStoreProvider).clear();
    final db = ref.read(databaseProvider);
    await db.resetData();
    final settings = ref.read(settingsRepositoryProvider);
    await settings.remove(SyncEngine.cursorKey);
    await settings.remove(SyncEngine.lastSyncKey);
    state = state.copyWith(
      email: () => null,
      lastSyncAt: () => null,
      error: () => null,
    );
  }

  Future<bool> hasUnsyncedChanges() => _engine().hasDirtyRows();
}
