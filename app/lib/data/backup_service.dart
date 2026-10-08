import 'dart:convert';

import 'package:drift/drift.dart';

import 'db/app_database.dart';
import 'sync/row_json.dart';

class BackupFormatException implements Exception {
  BackupFormatException(this.message);
  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Hasil impor: baris yang disimpan dan yang dilewati karena data di HP
/// sudah sama atau lebih baru.
typedef ImportResult = ({int imported, int skipped});

/// Ekspor/impor data lokal ke file. Paket gratis Supabase tidak punya
/// backup otomatis, jadi ini cadangan yang dipegang user sendiri.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  // Nama lama app; tetap dipakai supaya file backup lama masih bisa diimpor.
  static const format = 'djournal-backup';
  static const version = 1;

  /// Semua data, termasuk yang sudah dihapus (supaya penghapusan ikut
  /// terbawa saat dipulihkan). Bentuk baris sama dengan payload sync.
  Future<String> exportJson() async {
    final data = {
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'wallets': (await _db.select(_db.wallets).get())
          .map(walletToJson)
          .toList(),
      'categories': (await _db.select(_db.categories).get())
          .map(categoryToJson)
          .toList(),
      'transactions': (await _db.select(_db.transactions).get())
          .map(transactionToJson)
          .toList(),
      'budgets': (await _db.select(_db.budgets).get())
          .map(budgetToJson)
          .toList(),
      'journalEntries': (await _db.select(_db.journalEntries).get())
          .map(entryToJson)
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Gabungkan isi file backup ke database lokal. Tidak ada yang dihapus;
  /// untuk baris yang sama, versi dengan updatedAt lebih baru yang dipakai.
  /// Baris yang diimpor ditandai is_dirty supaya ikut terkirim ke server.
  Future<ImportResult> importJson(String content) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw BackupFormatException('bukan JSON');
    }
    if (data['format'] != format) {
      throw BackupFormatException('bukan file backup Nyawtat');
    }
    if ((data['version'] as num?)?.toInt() != version) {
      throw BackupFormatException('versi backup tidak dikenal');
    }

    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) {
      try {
        return ((data[key] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(parse)
            .toList();
      } catch (e) {
        throw BackupFormatException('isi "$key" rusak: $e');
      }
    }

    final wallets = rows('wallets', (j) => walletFromJson(j, dirty: true));
    final categories = rows(
      'categories',
      (j) => categoryFromJson(j, dirty: true),
    );
    final txs = rows(
      'transactions',
      (j) => transactionFromJson(j, dirty: true),
    );
    final budgets = rows('budgets', (j) => budgetFromJson(j, dirty: true));
    final entries = rows(
      'journalEntries',
      (j) => entryFromJson(j, dirty: true),
    );

    var imported = 0;
    var skipped = 0;

    await _db.transaction(() async {
      await _mergeDefaults(wallets, categories);

      Future<void> put<T extends Table, D>(
        TableInfo<T, D> table,
        Insertable<D> row,
        String id,
        DateTime updatedAt,
      ) async {
        final local = await _db
            .customSelect(
              'SELECT updated_at FROM ${table.actualTableName} WHERE id = ?',
              variables: [Variable.withString(id)],
              readsFrom: {table},
            )
            .getSingleOrNull();
        if (local != null &&
            !updatedAt.isAfter(
              DateTime.fromMillisecondsSinceEpoch(
                local.read<int>('updated_at'),
                isUtc: true,
              ),
            )) {
          skipped++;
          return;
        }
        await _db.into(table).insertOnConflictUpdate(row);
        imported++;
      }

      // Urutan mengikuti foreign key: dompet & kategori dulu.
      for (final w in wallets) {
        await put(_db.wallets, w, w.id, w.updatedAt);
      }
      for (final c in categories) {
        await put(_db.categories, c, c.id, c.updatedAt);
      }
      for (final t in txs) {
        await put(_db.transactions, t, t.id, t.updatedAt);
      }
      for (final b in budgets) {
        // Index lokal unik per (kategori, bulan): buang baris lain yang bentrok
        // kalau budget dari file lebih baru. Server menyelesaikan sisanya.
        final clash =
            await (_db.select(_db.budgets)..where(
                  (x) =>
                      x.categoryId.equals(b.categoryId) &
                      x.startMonth.equals(b.startMonth) &
                      x.id.equals(b.id).not(),
                ))
                .getSingleOrNull();
        if (clash != null) {
          if (!b.updatedAt.isAfter(clash.updatedAt)) {
            skipped++;
            continue;
          }
          await (_db.delete(
            _db.budgets,
          )..where((x) => x.id.equals(clash.id))).go();
        }
        await put(_db.budgets, b, b.id, b.updatedAt);
      }
      for (final e in entries) {
        await put(_db.journalEntries, e, e.id, e.updatedAt);
      }
    });

    return (imported: imported, skipped: skipped);
  }

  /// Kategori bawaan (system_key sama) dan dompet "Tunai" bawaan di HP
  /// yang berbeda id dengan milik file backup digabung ke versi file:
  /// rujukannya dipindah, lalu baris lokal ditandai terhapus.
  Future<void> _mergeDefaults(
    List<Wallet> wallets,
    List<Category> categories,
  ) async {
    final now = DateTime.now().toUtc();
    final local = await (_db.select(
      _db.categories,
    )..where((c) => c.deletedAt.isNull() & c.systemKey.isNotNull())).get();

    for (final mine in local) {
      final match = categories
          .where(
            (c) =>
                c.deletedAt == null &&
                c.systemKey == mine.systemKey &&
                c.kind == mine.kind &&
                c.id != mine.id,
          )
          .firstOrNull;
      if (match == null) continue;

      await _db.into(_db.categories).insertOnConflictUpdate(match);
      await (_db.update(
        _db.transactions,
      )..where((t) => t.categoryId.equals(mine.id))).write(
        TransactionsCompanion(
          categoryId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(
        _db.budgets,
      )..where((b) => b.categoryId.equals(mine.id))).write(
        BudgetsCompanion(
          categoryId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await _softDelete(_db.categories, mine.id, now);
    }

    final localCash =
        await (_db.select(_db.wallets)..where(
              (w) =>
                  w.deletedAt.isNull() &
                  w.type.equals('cash') &
                  w.openingBalance.equals(0),
            ))
            .get();
    for (final mine in localCash) {
      final match = wallets
          .where(
            (w) =>
                w.deletedAt == null &&
                w.type == 'cash' &&
                w.name == mine.name &&
                w.id != mine.id,
          )
          .firstOrNull;
      if (match == null) continue;

      await _db.into(_db.wallets).insertOnConflictUpdate(match);
      await (_db.update(
        _db.transactions,
      )..where((t) => t.walletId.equals(mine.id))).write(
        TransactionsCompanion(
          walletId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await (_db.update(
        _db.transactions,
      )..where((t) => t.toWalletId.equals(mine.id))).write(
        TransactionsCompanion(
          toWalletId: Value(match.id),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
      await _softDelete(_db.wallets, mine.id, now);
    }
  }

  Future<void> _softDelete(TableInfo table, String id, DateTime now) =>
      _db.customUpdate(
        'UPDATE ${table.actualTableName} '
        'SET deleted_at = ?, updated_at = ?, is_dirty = 1 WHERE id = ?',
        variables: [
          Variable.withInt(now.millisecondsSinceEpoch),
          Variable.withInt(now.millisecondsSinceEpoch),
          Variable.withString(id),
        ],
        updates: {table},
      );
}
