import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/home_widget_sync.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppDatabase db;
  late MoneyRepository repo;
  final now = DateTime(2026, 10, 9, 10);

  setUpAll(() => initializeDateFormatting());

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

  Future<void> seed() async {
    final snap = await snapshot();
    final cash = snap.wallets.single;
    final food = snap.categories.firstWhere((c) => c.systemKey == 'food');
    await repo.updateWallet(
      id: cash.id,
      name: cash.name,
      type: cash.type,
      openingBalance: 1000000,
    );
    await repo.setBudget(
      categoryId: food.id,
      startMonth: '2026-10',
      amount: 500000,
    );
    for (final (day, amount) in [(9, 25000), (9, 15000), (3, 260000)]) {
      await repo.saveTransaction(
        type: 'expense',
        amount: amount,
        walletId: cash.id,
        categoryId: food.id,
        note: null,
        occurredAt: DateTime(2026, 10, day, 8),
      );
    }
  }

  test('data widget berisi saldo, keluar hari ini, dan budget', () async {
    await seed();
    final data = buildHomeWidgetData(
      snap: await snapshot(),
      entries: const [],
      l: lookupAppLocalizations(const Locale('id')),
      localeTag: 'id',
      hide: false,
      now: now,
    );
    expect(data['nw_date'], '2026-10-09');
    expect(data['nw_j_count'], '0');
    expect(data['nw_j_sub'], '');
    expect(data['nw_balance'], 'Rp 700.000');
    expect(data['nw_today_out'], 'Rp 40.000');
    expect(data['nw_has_budget'], '1');
    expect(data['nw_budget_pct'], '60');
    expect(data['nw_budget_over'], '0');
    expect(
      data['nw_budget_line'],
      'Budget Oktober terpakai 60% · sisa Rp 200.000',
    );
    expect(data['nw_l_record'], 'Catat');
  });

  test('PIN aktif: semua nominal disembunyikan', () async {
    await seed();
    final data = buildHomeWidgetData(
      snap: await snapshot(),
      entries: const [],
      l: lookupAppLocalizations(const Locale('en')),
      localeTag: 'en',
      hide: true,
      now: now,
    );
    expect(data['nw_hide'], '1');
    expect(data['nw_balance'], 'Rp •••••');
    expect(data['nw_today_out'], 'Rp •••••');
    expect(data['nw_budget_line'], isNot(contains('200.000')));
    expect(data['nw_l_balance'], 'Balance');
  });

  test('widget jurnal: jumlah entri hari ini dan jam terakhir', () async {
    JournalEntry entry(String date, String? time) => JournalEntry(
      id: '$date $time',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
      isDirty: false,
      entryDate: date,
      entryTime: time,
      title: 'Rahasia',
      body: 'Isi yang tidak boleh muncul di widget',
    );
    final data = buildHomeWidgetData(
      snap: await snapshot(),
      entries: [
        entry('2026-10-09', '21:30'),
        entry('2026-10-09', '07:10'),
        entry('2026-10-08', '23:00'),
      ],
      l: lookupAppLocalizations(const Locale('id')),
      localeTag: 'id',
      hide: false,
      now: now,
    );
    expect(data['nw_j_count'], '2');
    expect(data['nw_j_sub'], '2 entri · terakhir 21:30');
    expect(data.values.join(), isNot(contains('Rahasia')));
  });
}
