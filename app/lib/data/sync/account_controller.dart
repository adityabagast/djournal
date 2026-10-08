import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../providers.dart';
import 'backend.dart';
import 'sync_engine.dart';

/// Email akun yang datanya ada di HP ini. Disimpan di app_settings supaya
/// tetap diketahui walau sesi login sudah kedaluwarsa.
const accountEmailKey = 'account_email';

@immutable
class AccountState {
  const AccountState({
    this.loading = true,
    this.email,
    this.syncing = false,
    this.lastSyncAt,
    this.error,
  });

  final bool loading;

  /// null = belum login (app tetap bisa dipakai offline).
  final String? email;
  final bool syncing;
  final DateTime? lastSyncAt;

  /// Error sync terakhir; null kalau sukses.
  final ApiError? error;

  bool get loggedIn => email != null;

  AccountState copyWith({
    bool? loading,
    String? Function()? email,
    bool? syncing,
    DateTime? Function()? lastSyncAt,
    ApiError? Function()? error,
  }) => AccountState(
    loading: loading ?? this.loading,
    email: email != null ? email() : this.email,
    syncing: syncing ?? this.syncing,
    lastSyncAt: lastSyncAt != null ? lastSyncAt() : this.lastSyncAt,
    error: error != null ? error() : this.error,
  );
}

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

  SupabaseBackend? get _backend =>
      backendConfigured ? SupabaseBackend(Supabase.instance.client) : null;

  SyncEngine _engine(SyncApi api) =>
      SyncEngine(ref.read(databaseProvider), api);

  Future<void> _init() async {
    final settings = ref.read(settingsRepositoryProvider);
    final email = await settings.watch(accountEmailKey).first;
    final last = await settings.watch(SyncEngine.lastSyncKey).first;
    state = state.copyWith(
      loading: false,
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
    final backend = _backend;
    if (backend == null || !state.loggedIn || state.syncing) return;
    if (await _engine(backend).hasDirtyRows()) await sync();
  }

  /// Satu siklus push → pull. Aman dipanggil berkali-kali.
  Future<void> sync() async {
    final backend = _backend;
    if (backend == null || !state.loggedIn) return;
    if (state.syncing) {
      _rerun = true;
      return;
    }
    if (backend.currentEmail == null) {
      state = state.copyWith(error: () => ApiError.sessionExpired);
      return;
    }

    state = state.copyWith(syncing: true);
    try {
      final at = await _engine(backend).run();
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
    required String email,
    required String password,
    required bool register,
  }) async {
    final backend = _backend;
    if (backend == null) throw ApiException(ApiError.server, 'not configured');

    final cleanEmail = email.trim().toLowerCase();
    if (register) {
      await backend.signUp(cleanEmail, password);
    } else {
      await backend.signIn(cleanEmail, password);
    }

    // Data di HP milik akun lain (login ulang dengan email berbeda):
    // kosongkan dulu supaya data dua akun tidak tercampur.
    final previous = state.email;
    if (previous != null && previous != cleanEmail) await _clearLocal();

    await ref.read(settingsRepositoryProvider).set(accountEmailKey, cleanEmail);
    state = state.copyWith(email: () => cleanEmail, error: () => null);
    unawaited(sync());
  }

  /// Logout: coba sync terakhir, keluar dari Supabase, lalu kosongkan data
  /// di HP (data aman di server dan kembali saat login lagi).
  Future<void> signOut() async {
    final backend = _backend;
    if (backend != null) {
      try {
        await _engine(backend).run();
      } catch (_) {
        // Tetap logout walau offline; pemanggil sudah memperingatkan user.
      }
      try {
        await backend.signOut();
      } catch (_) {}
    }
    await _clearLocal();
    state = state.copyWith(
      email: () => null,
      lastSyncAt: () => null,
      error: () => null,
    );
  }

  Future<void> _clearLocal() async {
    await ref.read(databaseProvider).resetData();
    final settings = ref.read(settingsRepositoryProvider);
    await settings.remove(SyncEngine.cursorKey);
    await settings.remove(SyncEngine.lastSyncKey);
    await settings.remove(accountEmailKey);
  }

  Future<bool> hasUnsyncedChanges() async {
    final backend = _backend;
    if (backend == null) return false;
    return _engine(backend).hasDirtyRows();
  }
}
