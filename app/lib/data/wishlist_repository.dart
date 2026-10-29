import 'package:drift/drift.dart';

import '../core/format.dart';
import 'db/app_database.dart';

class WishlistRepository {
  WishlistRepository(this._db);

  /// Awalan catatan transfer yang dibuat [deposit]. Dipakai juga untuk
  /// mengenali setoran tabungan (mis. di streak harian), jadi jangan diubah
  /// tanpa memperbarui [isDepositTransfer].
  static const depositNotePrefix = 'Nabung Wishlist: ';

  /// True kalau transaksi adalah transfer setoran wishlist dari [deposit].
  static bool isDepositTransfer({required String type, String? note}) =>
      type == 'transfer' && (note?.startsWith(depositNotePrefix) ?? false);

  final AppDatabase _db;

  Stream<List<Wishlist>> watchWishlists() {
    final q = _db.select(_db.wishlists)
      ..where((w) => w.deletedAt.isNull())
      ..orderBy([
        (w) => OrderingTerm(expression: w.isFulfilled),
        (w) => OrderingTerm(expression: w.createdAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  Future<Wishlist?> getWishlist(String id) =>
      (_db.select(_db.wishlists)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<String> createWishlist({
    required String title,
    required int targetAmount,
    required int targetMonths,
    String? targetDate,
    String? walletId,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final id = newId();
    await _db.into(_db.wishlists).insert(
      WishlistsCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        title: title,
        targetAmount: targetAmount,
        savedAmount: const Value(0),
        targetMonths: Value(targetMonths),
        targetDate: Value(targetDate),
        walletId: Value(walletId),
        notes: Value(notes),
        isFulfilled: const Value(false),
      ),
    );
    return id;
  }

  Future<void> updateWishlist({
    required String id,
    String? title,
    int? targetAmount,
    int? savedAmount,
    int? targetMonths,
    String? targetDate,
    String? walletId,
    String? notes,
    bool? isFulfilled,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.wishlists)..where((w) => w.id.equals(id))).write(
      WishlistsCompanion(
        updatedAt: Value(now),
        isDirty: const Value(true),
        title: title != null ? Value(title) : const Value.absent(),
        targetAmount: targetAmount != null ? Value(targetAmount) : const Value.absent(),
        savedAmount: savedAmount != null ? Value(savedAmount) : const Value.absent(),
        targetMonths: targetMonths != null ? Value(targetMonths) : const Value.absent(),
        targetDate: targetDate != null ? Value(targetDate) : const Value.absent(),
        walletId: walletId != null ? Value(walletId) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        isFulfilled: isFulfilled != null ? Value(isFulfilled) : const Value.absent(),
      ),
    );
  }

  Future<void> deposit({
    required String wishlistId,
    required int amount,
    String? sourceWalletId,
  }) {
    // Satu transaksi database: transfer tabungan dan saldo wishlist
    // selalu ter-update bersamaan.
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      final current = await getWishlist(wishlistId);
      if (current == null) return;

      final newSaved = current.savedAmount + amount;
      final fulfilled = newSaved >= current.targetAmount;

      // Catat mutasi / transaksi jika ada dompet yang dipilih
      if (sourceWalletId != null) {
        final targetWalletId = current.walletId;
        if (targetWalletId != null && targetWalletId != sourceWalletId) {
          // Transfer antar dompet (misal: Rekening Utama -> Rekening Tabungan)
          await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              type: 'transfer',
              amount: amount,
              walletId: sourceWalletId,
              toWalletId: Value(targetWalletId),
              note: Value('$depositNotePrefix${current.title}'),
              occurredAt: now,
              localDate: toLocalDate(now.toLocal()),
            ),
          );
        }
      }

      await (_db.update(_db.wishlists)..where((w) => w.id.equals(wishlistId))).write(
        WishlistsCompanion(
          updatedAt: Value(now),
          isDirty: const Value(true),
          savedAmount: Value(newSaved),
          isFulfilled: Value(fulfilled),
        ),
      );
    });
  }

  Future<void> deleteWishlist(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.wishlists)..where((w) => w.id.equals(id))).write(
      WishlistsCompanion(
        updatedAt: Value(now),
        deletedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }
}
