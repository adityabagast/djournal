import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MoneyRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MoneyRepository(db);
  });

  tearDown(() => db.close());

  Future<MoneySnapshot> snapshot() async => MoneySnapshot(
    wallets: await repo.watchWallets().first,
    categories: await repo.watchCategories().first,
    transactions: await repo.watchTransactions().first,
    budgets: await repo.watchBudgets().first,
  );

  Future<void> spend(String walletId, String categoryId, int amount) =>
      repo.saveTransaction(
        type: 'expense',
        amount: amount,
        walletId: walletId,
        categoryId: categoryId,
        note: null,
        occurredAt: DateTime(2026, 10, 5, 12),
      );

  test('tambah, ubah, sembunyikan, dan urutkan kategori', () async {
    await repo.addCategory(kind: 'expense', name: ' Kuota ', color: '#2F5D8A');
    var snap = await snapshot();
    final kuota = snap.categories.firstWhere((c) => c.name == 'Kuota');
    expect(kuota.systemKey, isNull);
    // Kategori baru masuk paling bawah.
    expect(snap.categories.where((c) => c.kind == 'expense').last.id, kuota.id);

    await repo.updateCategory(
      id: kuota.id,
      name: 'Pulsa',
      color: '#8A2D5C',
      icon: 'kuota',
    );
    await repo.setCategoryHidden(kuota.id, true);
    snap = await snapshot();
    expect(snap.categories.any((c) => c.id == kuota.id), isFalse);
    final hidden = snap.hiddenCategories.single;
    expect(
      (hidden.name, hidden.color, hidden.icon),
      ('Pulsa', '#8A2D5C', 'kuota'),
    );
    // Tetap bisa dibaca untuk transaksi lama.
    expect(snap.categoryById[kuota.id], isNotNull);

    final expense = snap.categories.where((c) => c.kind == 'expense').toList();
    final reversed = expense.reversed.map((c) => c.id).toList();
    await repo.reorderCategories(reversed);
    snap = await snapshot();
    expect(
      snap.categories.where((c) => c.kind == 'expense').map((c) => c.id),
      reversed,
    );
  });

  test('gabung kategori memindahkan transaksi dan budget', () async {
    var snap = await snapshot();
    final wallet = snap.wallets.single;
    await repo.addCategory(kind: 'expense', name: 'Jajan', color: '#9A3412');
    snap = await snapshot();
    final jajan = snap.categories.firstWhere((c) => c.name == 'Jajan');
    final food = snap.categories.firstWhere((c) => c.systemKey == 'food');

    await spend(wallet.id, jajan.id, 15000);
    await spend(wallet.id, jajan.id, 5000);
    await spend(wallet.id, food.id, 30000);
    // Bulan yang sama: budget Makan dipertahankan; bulan lain dipindah.
    await repo.setBudget(
      categoryId: jajan.id,
      startMonth: '2026-10',
      amount: 100000,
    );
    await repo.setBudget(
      categoryId: jajan.id,
      startMonth: '2026-11',
      amount: 120000,
    );
    await repo.setBudget(
      categoryId: food.id,
      startMonth: '2026-10',
      amount: 1500000,
    );

    await repo.mergeCategory(fromId: jajan.id, toId: food.id);
    snap = await snapshot();
    expect(snap.categoryById.containsKey(jajan.id), isFalse);
    expect(snap.spentIn(food.id, '2026-10'), 50000);
    expect(snap.budgetFor(food.id, '2026-10'), 1500000);
    expect(snap.budgetFor(food.id, '2026-11'), 120000);
    expect(snap.budgets.where((b) => b.categoryId == jajan.id), isEmpty);
  });

  test('hapus kategori yang tidak dipakai', () async {
    await repo.addCategory(kind: 'income', name: 'Hadiah', color: '#17624A');
    var snap = await snapshot();
    final hadiah = snap.categories.firstWhere((c) => c.name == 'Hadiah');
    await repo.setBudget(
      categoryId: hadiah.id,
      startMonth: '2026-10',
      amount: 1,
    );

    await repo.deleteCategory(hadiah.id);
    snap = await snapshot();
    expect(snap.categoryById.containsKey(hadiah.id), isFalse);
    expect(snap.budgets.where((b) => b.categoryId == hadiah.id), isEmpty);
  });
}
