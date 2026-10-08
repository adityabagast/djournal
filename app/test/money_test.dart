import 'package:djournal/core/format.dart';
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
  );

  test('seed membuat dompet Tunai dan kategori bawaan', () async {
    final snap = await snapshot();
    expect(snap.wallets.map((w) => w.name), ['Tunai']);
    expect(snap.categories.where((c) => c.kind == 'expense'), hasLength(6));
    expect(snap.categories.where((c) => c.kind == 'income'), hasLength(3));
  });

  test('saldo dihitung dari saldo awal + transaksi', () async {
    await repo.addWallet(name: 'BCA', type: 'bank', openingBalance: 1000000);
    var snap = await snapshot();
    final bca = snap.wallets.firstWhere((w) => w.name == 'BCA');
    final food = snap.categories.firstWhere((c) => c.systemKey == 'food');
    final salary = snap.categories.firstWhere((c) => c.systemKey == 'salary');
    final at = DateTime(2026, 10, 8, 12, 30);

    await repo.saveTransaction(
      type: 'expense',
      amount: 25000,
      walletId: bca.id,
      categoryId: food.id,
      note: '  Kopi susu ',
      occurredAt: at,
    );
    await repo.saveTransaction(
      type: 'income',
      amount: 500000,
      walletId: bca.id,
      categoryId: salary.id,
      note: '',
      occurredAt: at,
    );

    snap = await snapshot();
    expect(snap.balanceOf(bca.id), 1000000 - 25000 + 500000);
    expect(snap.totalBalance, 1475000);

    final kopi = snap.transactions.firstWhere((t) => t.type == 'expense');
    expect(kopi.note, 'Kopi susu');
    expect(kopi.localDate, '2026-10-08');
    expect(
      snap.transactions.firstWhere((t) => t.type == 'income').note,
      isNull,
    );
    expect(snap.expenseByCategory('2026-10').single.$2, 25000);
  });

  test('edit dan soft delete transaksi', () async {
    var snap = await snapshot();
    final cash = snap.wallets.single;
    final food = snap.categories.firstWhere((c) => c.systemKey == 'food');
    await repo.saveTransaction(
      type: 'expense',
      amount: 10000,
      walletId: cash.id,
      categoryId: food.id,
      note: null,
      occurredAt: DateTime(2026, 10, 7),
    );
    final tx = (await snapshot()).transactions.single;

    await repo.saveTransaction(
      id: tx.id,
      type: 'expense',
      amount: 12000,
      walletId: cash.id,
      categoryId: food.id,
      note: null,
      occurredAt: DateTime(2026, 10, 8),
    );
    snap = await snapshot();
    expect(snap.transactions.single.amount, 12000);
    expect(snap.transactions.single.localDate, '2026-10-08');

    await repo.deleteTransaction(tx.id);
    snap = await snapshot();
    expect(snap.transactions, isEmpty);
    expect(snap.balanceOf(cash.id), 0);
  });

  test(
    'budget berlaku mulai bulan diatur dan berlanjut ke bulan berikutnya',
    () async {
      final cats = await repo.watchCategories().first;
      final food = cats.firstWhere((c) => c.systemKey == 'food');
      final transport = cats.firstWhere((c) => c.systemKey == 'transport');

      await repo.setBudget(
        categoryId: food.id,
        startMonth: '2026-09',
        amount: 1000000,
      );
      await repo.setBudget(
        categoryId: food.id,
        startMonth: '2026-11',
        amount: 1500000,
      );
      await repo.setBudget(
        categoryId: transport.id,
        startMonth: '2026-10',
        amount: 400000,
      );
      // Bulan yang sama ditimpa, bukan baris baru.
      await repo.setBudget(
        categoryId: transport.id,
        startMonth: '2026-10',
        amount: 300000,
      );

      final snap = MoneySnapshot(
        wallets: await repo.watchWallets().first,
        categories: cats,
        transactions: const [],
        budgets: await repo.watchBudgets().first,
      );
      expect(snap.budgets, hasLength(3));
      expect(snap.budgetFor(food.id, '2026-08'), 0);
      expect(snap.budgetFor(food.id, '2026-10'), 1000000); // berlanjut dari Sep
      expect(snap.budgetFor(food.id, '2026-12'), 1500000);
      expect(snap.budgetFor(transport.id, '2026-10'), 300000);
      expect(snap.totalBudget('2026-10'), 1300000);
    },
  );

  test('format rupiah dan input nominal', () {
    expect(rupiah(0), 'Rp 0');
    expect(rupiah(1250000), 'Rp 1.250.000');
    expect(rupiah(-999), 'Rp 999');
    expect(parseAmount('1.250.000'), 1250000);
    expect(toLocalDate(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
  });
}
