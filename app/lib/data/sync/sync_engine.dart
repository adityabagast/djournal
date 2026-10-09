import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'backend.dart';
import 'row_json.dart';

/// Sinkronisasi offline-first (docs/data-model.md §5): push semua baris
/// is_dirty, lalu pull perubahan sejak cursor terakhir.
class SyncEngine {
  SyncEngine(this._db, this._api);

  final AppDatabase _db;
  final SyncApi _api;

  static const cursorKey = 'sync_cursor';
  static const lastSyncKey = 'last_sync_at';

  /// Jalankan satu siklus sync. Mengembalikan waktu selesai.
  Future<DateTime> run() async {
    final cursor = int.tryParse(await _setting(cursorKey) ?? '') ?? 0;

    if (cursor == 0) {
      // Sync pertama di device ini: ambil data server dulu supaya dompet
      // dan kategori bawaan tidak dobel dengan milik device lain.
      final first = await _api.pull(0);
      await _db.transaction(() async {
        await _applyPull(first);
        await _mergeSeedDuplicates();
      });
    }

    await _push();

    final since = int.tryParse(await _setting(cursorKey) ?? '') ?? 0;
    final pulled = await _api.pull(since);
    await _db.transaction(() => _applyPull(pulled));

    final now = DateTime.now();
    await _setSetting(lastSyncKey, now.toUtc().toIso8601String());
    return now;
  }

  Future<bool> hasDirtyRows() async {
    final counts = await Future.wait([
      _countDirty(_db.wallets, _db.wallets.isDirty),
      _countDirty(_db.categories, _db.categories.isDirty),
      _countDirty(_db.transactions, _db.transactions.isDirty),
      _countDirty(_db.budgets, _db.budgets.isDirty),
      _countDirty(_db.journalEntries, _db.journalEntries.isDirty),
    ]);
    return counts.any((c) => c > 0);
  }

  Future<int> _countDirty(TableInfo table, Expression<bool> isDirty) async {
    final count = countAll(filter: isDirty);
    final row = await (_db.selectOnly(table)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  // ---------------------------------------------------------------- push

  Future<void> _push() async {
    final wallets = await (_db.select(
      _db.wallets,
    )..where((t) => t.isDirty)).get();
    final categories = await (_db.select(
      _db.categories,
    )..where((t) => t.isDirty)).get();
    final txs = await (_db.select(
      _db.transactions,
    )..where((t) => t.isDirty)).get();
    final budgets = await (_db.select(
      _db.budgets,
    )..where((t) => t.isDirty)).get();
    final entries = await (_db.select(
      _db.journalEntries,
    )..where((t) => t.isDirty)).get();

    if (wallets.isEmpty &&
        categories.isEmpty &&
        txs.isEmpty &&
        budgets.isEmpty &&
        entries.isEmpty) {
      return;
    }

    await _api.push({
      'wallets': wallets.map(walletToJson).toList(),
      'categories': categories.map(categoryToJson).toList(),
      'transactions': txs.map(transactionToJson).toList(),
      'budgets': budgets.map(budgetToJson).toList(),
      'journalEntries': entries.map(entryToJson).toList(),
    });

    // Tandai bersih hanya kalau baris tidak diubah lagi selama push
    // berjalan (updated_at masih sama). Kalau berubah, ikut push berikutnya.
    await _db.transaction(() async {
      for (final w in wallets) {
        await (_db.update(_db.wallets)..where(
              (t) => t.id.equals(w.id) & t.updatedAt.equalsValue(w.updatedAt),
            ))
            .write(const WalletsCompanion(isDirty: Value(false)));
      }
      for (final c in categories) {
        await (_db.update(_db.categories)..where(
              (t) => t.id.equals(c.id) & t.updatedAt.equalsValue(c.updatedAt),
            ))
            .write(const CategoriesCompanion(isDirty: Value(false)));
      }
      for (final x in txs) {
        await (_db.update(_db.transactions)..where(
              (t) => t.id.equals(x.id) & t.updatedAt.equalsValue(x.updatedAt),
            ))
            .write(const TransactionsCompanion(isDirty: Value(false)));
      }
      for (final b in budgets) {
        await (_db.update(_db.budgets)..where(
              (t) => t.id.equals(b.id) & t.updatedAt.equalsValue(b.updatedAt),
            ))
            .write(const BudgetsCompanion(isDirty: Value(false)));
      }
      for (final e in entries) {
        await (_db.update(_db.journalEntries)..where(
              (t) => t.id.equals(e.id) & t.updatedAt.equalsValue(e.updatedAt),
            ))
            .write(const JournalEntriesCompanion(isDirty: Value(false)));
      }
    });
  }

  // ---------------------------------------------------------------- pull

  /// Simpan baris dari server. Baris lokal yang belum di-push dan lebih
  /// baru dibiarkan (last-write-wins); sisanya ditimpa versi server.
  Future<void> _applyPull(Map<String, dynamic> res) async {
    List<Map<String, dynamic>> rows(String key) =>
        ((res[key] as List?) ?? const []).cast<Map<String, dynamic>>();

    Future<bool> localWins(
      TableInfo table,
      String id,
      DateTime remoteUpdated,
    ) async {
      final row = await _db
          .customSelect(
            'SELECT is_dirty, updated_at FROM ${table.actualTableName} WHERE id = ?',
            variables: [Variable.withString(id)],
            readsFrom: {table},
          )
          .getSingleOrNull();
      if (row == null) return false;
      final dirty = row.read<bool>('is_dirty');
      final updated = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
        isUtc: true,
      );
      return dirty && updated.isAfter(remoteUpdated);
    }

    // Urutan mengikuti foreign key: dompet & kategori dulu.
    for (final j in rows('wallets')) {
      final w = walletFromJson(j);
      if (await localWins(_db.wallets, w.id, w.updatedAt)) continue;
      await _db.into(_db.wallets).insertOnConflictUpdate(w);
    }
    for (final j in rows('categories')) {
      final c = categoryFromJson(j);
      if (await localWins(_db.categories, c.id, c.updatedAt)) continue;
      await _db.into(_db.categories).insertOnConflictUpdate(c);
    }
    for (final j in rows('transactions')) {
      final t = transactionFromJson(j);
      if (await localWins(_db.transactions, t.id, t.updatedAt)) continue;
      await _db.into(_db.transactions).insertOnConflictUpdate(t);
    }
    for (final j in rows('budgets')) {
      final b = budgetFromJson(j);
      if (await localWins(_db.budgets, b.id, b.updatedAt)) continue;
      // Budget unik per (kategori, bulan): buang baris lokal lain yang bentrok.
      await (_db.delete(_db.budgets)..where(
            (t) =>
                t.categoryId.equals(b.categoryId) &
                t.startMonth.equals(b.startMonth) &
                t.id.equals(b.id).not(),
          ))
          .go();
      await _db.into(_db.budgets).insertOnConflictUpdate(b);
    }
    for (final j in rows('journalEntries')) {
      final e = entryFromJson(j);
      if (await localWins(_db.journalEntries, e.id, e.updatedAt)) continue;
      await _db.into(_db.journalEntries).insertOnConflictUpdate(e);
    }

    await _setSetting(cursorKey, '${(res['cursor'] as num).toInt()}');
  }

  /// Setelah pull pertama: kategori bawaan (system_key sama) dan dompet
  /// "Tunai" bawaan yang dibuat device ini digabung ke milik server,
  /// supaya tidak muncul dua kali.
  Future<void> _mergeSeedDuplicates() async {
    final now = DateTime.now().toUtc();
    final cats = await _db.select(_db.categories).get();
    final serverCats = cats.where((c) => !c.isDirty && c.systemKey != null);

    for (final local in cats.where((c) => c.isDirty && c.systemKey != null)) {
      final match = serverCats
          .where((s) => s.systemKey == local.systemKey && s.kind == local.kind)
          .firstOrNull;
      if (match == null) continue;

      await (_db.update(
        _db.transactions,
      )..where((t) => t.categoryId.equals(local.id))).write(
        TransactionsCompanion(
          categoryId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      // Budget yang sudah ada di server untuk kategori+bulan yang sama menang.
      final localBudgets = await (_db.select(
        _db.budgets,
      )..where((b) => b.categoryId.equals(local.id))).get();
      for (final b in localBudgets) {
        final taken =
            await (_db.select(_db.budgets)..where(
                  (x) =>
                      x.categoryId.equals(match.id) &
                      x.startMonth.equals(b.startMonth),
                ))
                .getSingleOrNull();
        if (taken != null) {
          await (_db.delete(_db.budgets)..where((x) => x.id.equals(b.id))).go();
        } else {
          await (_db.update(
            _db.budgets,
          )..where((x) => x.id.equals(b.id))).write(
            BudgetsCompanion(
              categoryId: Value(match.id),
              updatedAt: Value(now),
              isDirty: const Value(true),
            ),
          );
        }
      }
      // Belum pernah di-push, jadi aman dihapus permanen.
      await (_db.delete(
        _db.categories,
      )..where((c) => c.id.equals(local.id))).go();
    }

    final wallets = await _db.select(_db.wallets).get();
    for (final local in wallets.where(
      (w) =>
          w.isDirty &&
          w.deletedAt == null &&
          w.type == 'cash' &&
          w.openingBalance == 0,
    )) {
      // Jangan gabung ke dompet yang sudah dihapus di device lain.
      final match = wallets
          .where(
            (s) =>
                !s.isDirty &&
                s.deletedAt == null &&
                s.type == 'cash' &&
                s.name == local.name,
          )
          .firstOrNull;
      if (match == null) continue;

      await (_db.update(
        _db.transactions,
      )..where((t) => t.walletId.equals(local.id))).write(
        TransactionsCompanion(
          walletId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(
        _db.transactions,
      )..where((t) => t.toWalletId.equals(local.id))).write(
        TransactionsCompanion(
          toWalletId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await (_db.delete(_db.wallets)..where((w) => w.id.equals(local.id))).go();
    }
  }

  // ------------------------------------------------------------ settings

  Future<String?> _setting(String key) async => (await (_db.select(
    _db.appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setSetting(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(AppSetting(key: key, value: value));
}
