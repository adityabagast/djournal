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
        dueDay: Value(_dayOf(dueDate)),
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
        // Tanggal diubah user = patokan baru untuk bulan-bulan berikutnya.
        dueDay: dueDate != null ? Value(_dayOf(dueDate)) : const Value.absent(),
        repeatInterval: repeatInterval != null ? Value(repeatInterval) : const Value.absent(),
        walletId: walletId != null ? Value(walletId) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        isPaid: isPaid != null ? Value(isPaid) : const Value.absent(),
        paidAt: paidAt != null ? Value(paidAt) : const Value.absent(),
      ),
    );
  }

  /// Bayar tagihan: catat transaksi pengeluaran, lalu
  /// - tagihan berulang (`monthly` / `yearly`) dijadwalkan ke jatuh tempo
  ///   berikutnya dan tetap belum lunas;
  /// - tagihan sekali (`once` / null) ditandai lunas.
  ///
  /// Semua langkah dalam satu transaksi database, jadi tidak ada keadaan
  /// "uang sudah keluar tapi tagihan belum ter-update".
  ///
  /// Mengembalikan jatuh tempo berikutnya (YYYY-MM-DD) untuk tagihan
  /// berulang, atau null kalau tagihan selesai / tidak ditemukan.
  Future<String?> payBill({
    required String billId,
    required String walletId,
    String? categoryId,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final bill = await getBill(billId);
      if (bill == null || bill.isPaid || bill.deletedAt != null) return null;

      var catId = categoryId ?? bill.categoryId;
      if (catId == null) {
        final billCats = await (_db.select(_db.categories)
              ..where((c) => c.systemKey.equals('bills') & c.deletedAt.isNull())
              ..limit(1))
            .get();
        catId = billCats.firstOrNull?.id;
      }

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

      final next = nextDueDate(
        bill.dueDate,
        bill.repeatInterval,
        anchorDay: bill.dueDay,
      );
      await (_db.update(_db.bills)..where((b) => b.id.equals(billId))).write(
        BillsCompanion(
          updatedAt: Value(now),
          isDirty: const Value(true),
          paidAt: Value(now),
          isPaid: Value(next == null),
          dueDate: next != null ? Value(next) : const Value.absent(),
        ),
      );
      return next;
    });
  }

  /// Jatuh tempo berikutnya untuk tagihan berulang, atau null kalau
  /// tagihan tidak berulang (`once`, null, atau nilai tak dikenal).
  ///
  /// Tanggal yang tidak ada di bulan tujuan dipotong ke akhir bulan:
  /// 31 Jan → 28/29 Feb, 29 Feb (tahunan) → 28 Feb tahun berikutnya.
  /// [anchorDay] = tanggal asli pilihan user, supaya setelah dipotong
  /// bulan berikutnya kembali lagi (31 Jan → 28 Feb → 31 Mar).
  static String? nextDueDate(
    String dueDate,
    String? repeatInterval, {
    int? anchorDay,
  }) {
    final months = switch (repeatInterval) {
      'monthly' => 1,
      'yearly' => 12,
      _ => 0,
    };
    if (months == 0) return null;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return null;
    final firstOfTarget = DateTime(due.year, due.month + months, 1);
    final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
    final wanted = anchorDay ?? due.day;
    final day = wanted > lastDay ? lastDay : wanted;
    return toLocalDate(DateTime(firstOfTarget.year, firstOfTarget.month, day));
  }

  static int? _dayOf(String ymd) => DateTime.tryParse(ymd)?.day;

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
