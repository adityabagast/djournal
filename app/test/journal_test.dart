import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/insights.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/money_snapshot.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late JournalRepository journal;
  late MoneyRepository money;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    journal = JournalRepository(db);
    money = MoneyRepository(db);
  });

  tearDown(() => db.close());

  Future<List<JournalEntry>> entries() => journal.watchEntries().first;

  Future<void> write(String date, {String? time, int? mood, String? title}) =>
      journal.saveEntry(
        entryDate: date,
        entryTime: time,
        mood: mood,
        title: title ?? 'x',
        body: null,
        tags: const [],
      );

  test('simpan entri: teks dibersihkan, tag jadi JSON', () async {
    await journal.saveEntry(
      entryDate: '2026-10-08',
      entryTime: null,
      mood: 4,
      title: '  Sarapan  ',
      body: '   ',
      tags: parseTags('teman, #kerja, teman, '),
    );
    final e = (await entries()).single;
    expect(e.title, 'Sarapan');
    expect(e.body, isNull);
    expect(e.entryTime, isNull);
    expect(entryTags(e), ['teman', 'kerja']);
  });

  test('beberapa entri per hari, urut jam; edit dan hapus', () async {
    await write('2026-10-08', time: '19:30', title: 'Malam');
    await write('2026-10-08', time: '07:15', title: 'Pagi');
    await write('2026-10-07', title: 'Kemarin');

    var list = await entries();
    expect(list.first.entryDate, '2026-10-08');
    final today = list.where((e) => e.entryDate == '2026-10-08').toList()
      ..sort((a, b) => entrySortKey(b).compareTo(entrySortKey(a)));
    expect(today.map((e) => e.title), ['Malam', 'Pagi']);

    final pagi = today.firstWhere((e) => e.title == 'Pagi');
    final malam = today.firstWhere((e) => e.title == 'Malam');
    await journal.saveEntry(
      id: pagi.id,
      entryDate: pagi.entryDate,
      entryTime: null,
      mood: 2,
      title: 'Pagi buru-buru',
      body: null,
      tags: const [],
    );
    await journal.deleteEntry(malam.id);

    list = await entries();
    expect(list, hasLength(2));
    final edited = list.firstWhere((e) => e.id == pagi.id);
    expect(edited.title, 'Pagi buru-buru');
    expect(edited.entryTime, isNull);
    expect(edited.mood, 2);
  });

  test(
    'mood harian = rata-rata dibulatkan, entri tanpa mood diabaikan',
    () async {
      await write('2026-10-08', mood: 3);
      await write('2026-10-08', mood: 4);
      await write('2026-10-08');
      final list = await entries();
      expect(dayMood(list, '2026-10-08'), 4); // 3.5 → 4
      expect(dayMood(list, '2026-10-07'), isNull);
    },
  );

  test('insight mood × pengeluaran', () async {
    final wallets = await money.watchWallets().first;
    final cats = await money.watchCategories().first;
    final food = cats.firstWhere((c) => c.systemKey == 'food');
    Future<void> spend(int amount, DateTime at) => money.saveTransaction(
      type: 'expense',
      amount: amount,
      walletId: wallets.first.id,
      categoryId: food.id,
      note: null,
      occurredAt: at,
    );

    await write('2026-10-05', mood: 2);
    await spend(100000, DateTime(2026, 10, 5, 12));
    await write('2026-10-07', mood: 5);
    await spend(20000, DateTime(2026, 10, 7, 12));
    await write('2026-10-08', mood: 4); // hari baik tanpa pengeluaran

    final snap = MoneySnapshot(
      wallets: wallets,
      categories: cats,
      transactions: await money.watchTransactions().first,
    );
    final r = moodSpending(await entries(), snap);
    expect(r.good, 10000); // (20.000 + 0) / 2
    expect(r.low, 100000);
  });
}
