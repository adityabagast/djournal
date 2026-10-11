import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:djournal/data/search.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MoneyRepository money;
  late JournalRepository journal;
  late MoneySnapshot snap;
  late List<JournalEntry> entries;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    money = MoneyRepository(db);
    journal = JournalRepository(db);
    await money.addWallet(name: 'GoPay', type: 'ewallet', openingBalance: 0);
    final wallets = {
      for (final w in await money.watchWallets().first) w.name: w,
    };
    final cats = {
      for (final c in await money.watchCategories().first) c.systemKey: c,
    };
    Future<void> tx(
      String type,
      int amount,
      String wallet,
      String? cat,
      String? note,
      DateTime at, {
      String? to,
    }) => money.saveTransaction(
      type: type,
      amount: amount,
      walletId: wallets[wallet]!.id,
      toWalletId: to == null ? null : wallets[to]!.id,
      categoryId: cat == null ? null : cats[cat]!.id,
      note: note,
      occurredAt: at,
    );
    await tx(
      'expense',
      25000,
      'GoPay',
      'food',
      'Kopi susu',
      DateTime(2026, 10, 11, 7, 30),
    );
    await tx(
      'expense',
      32000,
      'Tunai',
      'food',
      'Roti',
      DateTime(2026, 10, 10, 15),
    );
    await tx(
      'income',
      8500000,
      'Tunai',
      'salary',
      'Gaji Oktober',
      DateTime(2026, 10, 1, 9),
    );
    await tx(
      'expense',
      22000,
      'Tunai',
      'food',
      'Kopi susu',
      DateTime(2026, 7, 21, 8),
    );
    await tx(
      'transfer',
      100000,
      'Tunai',
      null,
      null,
      DateTime(2026, 10, 9, 12),
      to: 'GoPay',
    );
    await journal.saveEntry(
      entryDate: '2026-10-09',
      entryTime: '21:30',
      mood: 5,
      title: 'Kedai kopi baru',
      body: 'Coba kedai dekat kantor.',
      tags: ['kerja'],
    );
    await journal.saveEntry(
      entryDate: '2026-10-08',
      entryTime: null,
      mood: null,
      title: 'Hujan',
      body: 'Di rumah saja.',
      tags: [],
    );
    snap = MoneySnapshot(
      wallets: await money.watchWallets().first,
      categories: await money.watchCategories().first,
      transactions: await money.watchTransactions().first,
    );
    entries = await journal.watchEntries().first;
  });

  tearDown(() => db.close());

  SearchResults find(
    String q, {
    SearchScope scope = SearchScope.all,
    SearchPeriod period = SearchPeriod.all,
  }) => searchAll(
    query: q,
    entries: entries,
    money: snap,
    categoryName: (c) => c.name,
    transferLabel: 'Transfer',
    scope: scope,
    period: period,
    now: DateTime(2026, 10, 11, 20),
  );

  test('kata dicari di jurnal dan transaksi, terbaru dulu', () {
    final r = find('KOPI');
    expect(r.entryCount, 1);
    expect(r.txCount, 2);
    expect(r.expense, 47000);
    expect(r.hits.first.tx?.note, 'Kopi susu');
    expect(r.hits.first.date, '2026-10-11');
    expect(r.hits[1].entry?.title, 'Kedai kopi baru');
  });

  test('semua kata harus cocok; kategori, dompet, dan tag ikut dicari', () {
    expect(find('kopi gopay').txCount, 1);
    expect(find('makan').txCount, 3);
    expect(find('#kerja').entryCount, 1);
    expect(find('transfer gopay').txCount, 1);
    expect(find('kopi teh').hits, isEmpty);
  });

  test('nominal bisa dicari dengan atau tanpa titik ribuan', () {
    expect(find('25000').txCount, 1);
    expect(find('8.500.000').hits.single.tx?.note, 'Gaji Oktober');
    // Angka pendek tidak dianggap nominal.
    expect(find('25').hits, isEmpty);
  });

  test('saringan jenis dan periode', () {
    expect(find('kopi', scope: SearchScope.journal).hits, hasLength(1));
    expect(find('kopi', scope: SearchScope.transactions).hits, hasLength(2));
    expect(find('kopi', period: SearchPeriod.thisMonth).txCount, 1);
    expect(find('kopi', period: SearchPeriod.threeMonths).txCount, 1);
    expect(find('kopi', period: SearchPeriod.all).txCount, 2);
    expect(find('   ').hits, isEmpty);
  });
}
