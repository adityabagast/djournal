import 'db/app_database.dart';

/// Pengaturan lokal (tabel app_settings, tidak disinkronkan).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<String?> watch(String key) {
    final q = _db.select(_db.appSettings)..where((s) => s.key.equals(key));
    return q.watchSingleOrNull().map((row) => row?.value);
  }

  Future<void> remove(String key) =>
      (_db.delete(_db.appSettings)..where((s) => s.key.equals(key))).go();

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(AppSetting(key: key, value: value));
}
