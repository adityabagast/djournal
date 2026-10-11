import 'package:drift/drift.dart';

import '../core/format.dart';
import 'db/app_database.dart';

/// Akses data keuangan. Mirip repository di .NET: UI tidak menyentuh
/// tabel langsung.
class MoneyRepository {
  MoneyRepository(this._db);

  final AppDatabase _db;

  /// Semua dompet yang belum dihapus, termasuk yang diarsipkan
  /// (MoneySnapshot memisahkannya).
  Stream<List<Wallet>> watchWallets() {
    final q = _db.select(_db.wallets)
      ..where((w) => w.deletedAt.isNull())
      ..orderBy([(w) => OrderingTerm(expression: w.sortOrder)]);
    return q.watch();
  }

  Stream<List<Category>> watchCategories() {
    final q = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull() & c.isArchived.equals(false))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    return q.watch();
  }

  /// Semua transaksi aktif, terbaru dulu.
  Stream<List<MoneyTx>> watchTransactions() {
    final q = _db.select(_db.transactions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Stream<List<Budget>> watchBudgets() {
    final q = _db.select(_db.budgets)..where((b) => b.deletedAt.isNull());
    return q.watch();
  }

  /// Atur budget kategori mulai bulan [startMonth] (YYYY-MM) dan seterusnya.
  /// Satu baris per (kategori, bulan): bulan yang sama ditimpa, bulan baru
  /// menambah baris supaya histori tetap ada. amount 0 = tanpa budget.
  Future<void> setBudget({
    required String categoryId,
    required String startMonth,
    required int amount,
  }) async {
    final now = DateTime.now().toUtc();
    final existing =
        await (_db.select(_db.budgets)..where(
              (b) =>
                  b.categoryId.equals(categoryId) &
                  b.startMonth.equals(startMonth),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              categoryId: categoryId,
              amount: amount,
              startMonth: startMonth,
            ),
          );
    } else {
      await (_db.update(
        _db.budgets,
      )..where((b) => b.id.equals(existing.id))).write(
        BudgetsCompanion(
          amount: Value(amount),
          updatedAt: Value(now),
          deletedAt: const Value(null),
          isDirty: const Value(true),
        ),
      );
    }
  }

  /// Transfer: [walletId] = dompet asal, [toWalletId] = dompet tujuan, dan
  /// [categoryId] null (aturan yang sama dicek server). Selain transfer,
  /// [toWalletId] selalu null.
  Future<void> saveTransaction({
    String? id,
    required String type,
    required int amount,
    required String walletId,
    String? toWalletId,
    required String? categoryId,
    required String? note,
    required DateTime occurredAt,
  }) async {
    final now = DateTime.now().toUtc();
    final cleanNote = (note == null || note.trim().isEmpty)
        ? null
        : note.trim();
    final isTransfer = type == 'transfer';
    assert(!isTransfer || (toWalletId != null && toWalletId != walletId));
    final to = isTransfer ? toWalletId : null;
    final category = isTransfer ? null : categoryId;

    if (id == null) {
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              type: type,
              amount: amount,
              walletId: walletId,
              toWalletId: Value(to),
              categoryId: Value(category),
              note: Value(cleanNote),
              occurredAt: occurredAt.toUtc(),
              localDate: toLocalDate(occurredAt),
            ),
          );
    } else {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          updatedAt: Value(now),
          isDirty: const Value(true),
          type: Value(type),
          amount: Value(amount),
          walletId: Value(walletId),
          toWalletId: Value(to),
          categoryId: Value(category),
          note: Value(cleanNote),
          occurredAt: Value(occurredAt.toUtc()),
          localDate: Value(toLocalDate(occurredAt)),
        ),
      );
    }
  }

  /// Soft delete supaya penghapusan ikut tersinkron nanti.
  Future<void> deleteTransaction(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  Future<void> addWallet({
    required String name,
    required String type,
    required int openingBalance,
  }) async {
    final now = DateTime.now().toUtc();
    final maxOrder = _db.wallets.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.wallets,
    )..addColumns([maxOrder])).getSingle();
    await _db
        .into(_db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            name: name.trim(),
            type: type,
            openingBalance: Value(openingBalance),
            sortOrder: Value((row.read(maxOrder) ?? -1) + 1),
          ),
        );
  }

  Future<void> updateWallet({
    required String id,
    required String name,
    required String type,
    required int openingBalance,
  }) async {
    await (_db.update(_db.wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        name: Value(name.trim()),
        type: Value(type),
        openingBalance: Value(openingBalance),
        updatedAt: Value(DateTime.now().toUtc()),
        isDirty: const Value(true),
      ),
    );
  }

  /// Samakan saldo dompet dengan [targetBalance] lewat satu transaksi
  /// kategori Lainnya (pemasukan kalau naik, pengeluaran kalau turun),
  /// seperti "Edit saldo" di aplikasi lain. Saldo awal tidak diubah supaya
  /// riwayatnya tetap terlihat.
  Future<void> adjustWalletBalance({
    required String walletId,
    required int currentBalance,
    required int targetBalance,
    required String note,
    DateTime? at,
  }) async {
    final diff = targetBalance - currentBalance;
    if (diff == 0) return;
    final kind = diff > 0 ? 'income' : 'expense';
    final systemKey = diff > 0 ? 'other_income' : 'other';
    final categories =
        await (_db.select(_db.categories)
              ..where((c) => c.deletedAt.isNull() & c.kind.equals(kind))
              ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
            .get();
    final category =
        categories.where((c) => c.systemKey == systemKey).firstOrNull ??
        categories.firstOrNull;
    await saveTransaction(
      type: kind,
      amount: diff.abs(),
      walletId: walletId,
      categoryId: category?.id,
      note: note,
      occurredAt: at ?? DateTime.now(),
    );
  }

  /// Arsip = dompet disembunyikan dari daftar, pilihan dompet, dan total
  /// saldo, tapi transaksinya tetap ada (mis. rekening yang sudah ditutup).
  Future<void> setWalletArchived(String id, bool archived) async {
    await (_db.update(_db.wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now().toUtc()),
        isDirty: const Value(true),
      ),
    );
  }

  /// Soft delete dompet beserta semua transaksinya (termasuk transfer
  /// dari/ke dompet ini), supaya saldo dan laporan tetap konsisten.
  Future<void> deleteWallet(String id) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.transactions)..where(
            (t) =>
                t.deletedAt.isNull() &
                (t.walletId.equals(id) | t.toWalletId.equals(id)),
          ))
          .write(
            TransactionsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              isDirty: const Value(true),
            ),
          );
      await (_db.update(_db.wallets)..where((w) => w.id.equals(id))).write(
        WalletsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
    });
  }
}
