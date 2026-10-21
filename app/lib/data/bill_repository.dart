import 'package:drift/drift.dart';

import '../core/format.dart';
import 'db/app_database.dart';

class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;

  Stream<List<Bill>> watchBills() {
    final q = _db.select(_db.bills)
      ..where((b) => b.deletedAt.isNull())
      ..orderBy([
        (b) => OrderingTerm(expression: b.isPaid),
        (b) => OrderingTerm(expression: b.dueDate),
      ]);
    return q.watch();
  }

  Stream<List<Bill>> watchUnpaidBills() {
    final q = _db.select(_db.bills)
      ..where((b) => b.deletedAt.isNull() & b.isPaid.equals(false))
      ..orderBy([
        (b) => OrderingTerm(expression: b.dueDate),
      ]);
    return q.watch();
  }

  Future<Bill?> getBill(String id) =>
      (_db.select(_db.bills)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<String> createBill({
    required String title,
    required int amount,
    required String dueDate,
    String? repeatInterval,
    String? walletId,
    String? categoryId,
  }) async {
    final now = DateTime.now().toUtc();
    final id = newId();
    await _db.into(_db.bills).insert(
      BillsCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        title: title,
        amount: amount,
        dueDate: dueDate,
        repeatInterval: Value(repeatInterval),
        walletId: Value(walletId),
        categoryId: Value(categoryId),
        isPaid: const Value(false),
      ),
    );
    return id;
  }

  Future<void> updateBill({
    required String id,
    String? title,
    int? amount,
    String? dueDate,
    String? repeatInterval,
    String? walletId,
    String? categoryId,
    bool? isPaid,
    DateTime? paidAt,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        updatedAt: Value(now),
        isDirty: const Value(true),
        title: title != null ? Value(title) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        repeatInterval: repeatInterval != null ? Value(repeatInterval) : const Value.absent(),
        walletId: walletId != null ? Value(walletId) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        isPaid: isPaid != null ? Value(isPaid) : const Value.absent(),
        paidAt: paidAt != null ? Value(paidAt) : const Value.absent(),
      ),
    );
  }

  Future<void> payBill({
    required String billId,
    required String walletId,
    String? categoryId,
  }) async {
    final now = DateTime.now().toUtc();
    final bill = await getBill(billId);
    if (bill == null || bill.isPaid) return;

    var catId = categoryId ?? bill.categoryId;
    if (catId == null) {
      final billCats = await (_db.select(_db.categories)
            ..where((c) => c.systemKey.equals('bills') & c.deletedAt.isNull())
            ..limit(1))
          .get();
      catId = billCats.firstOrNull?.id;
    }

    // Catat transaksi pengeluaran
    await _db.into(_db.transactions).insert(
      TransactionsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        type: 'expense',
        amount: bill.amount,
        walletId: walletId,
        categoryId: Value(catId),
        note: Value('Bayar Tagihan: ${bill.title}'),
        occurredAt: now,
        localDate: toLocalDate(now.toLocal()),
      ),
    );

    // Tandai tagihan sebagai lunas
    await (_db.update(_db.bills)..where((b) => b.id.equals(billId))).write(
      BillsCompanion(
        updatedAt: Value(now),
        isDirty: const Value(true),
        isPaid: const Value(true),
        paidAt: Value(now),
      ),
    );
  }

  Future<void> deleteBill(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }
}
