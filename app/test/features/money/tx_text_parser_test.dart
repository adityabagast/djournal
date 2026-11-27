import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/features/money/data/money_repository.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/features/money/domain/tx_suggestions.dart';
import 'package:djournal/features/money/domain/tx_text_parser.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// "catatan|nominal|jenis", satu baris per usulan.
List<String> parse(String text) => [
  for (final s in parseTxText(text)) '${s.note}|${s.amount}|${s.type}',
];

void main() {
  group('parseTxText', () {
    test('bentuk nominal', () {
      expect(parse('Beli es kopi 28rb pakai GoPay, parkir 2rb.'), [
        'Es kopi|28000|expense',
        'Parkir|2000|expense',
      ]);
      expect(parse('Isi bensin Rp 50.000 di jalan, terus makan soto 22k.'), [
        'Bensin|50000|expense',
        'Makan soto|22000|expense',
      ]);
      expect(parse('kopi 25.000 dan roti 12500'), [
        'Kopi|25000|expense',
        'Roti|12500|expense',
      ]);
      expect(parse('Bayar kos 1.250.000'), ['Kos|1250000|expense']);
      expect(parse('Beli HP 1,5jt'), ['HP|1500000|expense']);
      expect(parse('Beli HP 1.5 juta'), ['HP|1500000|expense']);
      expect(parse('Makan siang 38 ribu'), ['Makan siang|38000|expense']);
    });

    test('nama diambil dari kata sebelum nominal', () {
      expect(parse('Tadi beli bakso bareng teman lama, habis 35 ribu.'), [
        'Bakso|35000|expense',
      ]);
      expect(parse('Habis 35 ribu.'), ['|35000|expense']);
    });

    test('pemasukan', () {
      expect(parse('Gajian 5,5 juta masuk ke BCA.'), ['Gajian|5500000|income']);
      expect(parse('Dapat bonus 300rb.'), ['Bonus|300000|income']);
      // "dapat" + kata beli tetap pengeluaran.
      expect(
        parse('Akhirnya dapat sepatu, beli sepatu 200rb.').single,
        'Sepatu|200000|expense',
      );
    });

    test('bukan transaksi', () {
      for (final s in [
        'Mau beli sepatu 450rb minggu depan.',
        'Harga tiketnya 75.000.',
        'Besok bayar kos 900rb.',
        'Kopi diskon 10rb.',
        'Tahun 2026 aku lari 5 km jam 09.00.',
        'Tanggal 12 ada 3 rapat.',
        'Nomor rumahnya 120.',
        'Beli permen 100.',
        'Telepon 081234567890 ya.',
        '',
      ]) {
        expect(parse(s), isEmpty, reason: s);
      }
    });

    test('kunci stabil saat kata di sekitarnya diubah', () {
      String key(String s) => parseTxText(s).last.key;
      expect(key('Kopi 25rb.'), key('Kopi susu enak 25rb, murah.'));
      final twice = parseTxText('Ojek 15rb pergi, ojek 15rb pulang.');
      expect(twice.map((s) => s.key).toSet(), hasLength(2));
    });
  });

  group('TxSuggestionController', () {
    late AppDatabase db;
    late MoneyRepository money;
    late TxSuggestionController controller;
    const date = '2026-10-21';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      money = MoneyRepository(db);
      controller = TxSuggestionController();
      await money.addWallet(name: 'GoPay', type: 'ewallet', openingBalance: 0);
    });

    tearDown(() => db.close());

    Future<MoneySnapshot> snap() async => MoneySnapshot(
      wallets: await money.watchWallets().first,
      categories: await money.watchCategories().first,
      transactions: await money.watchTransactions().first,
    );

    Future<void> spend(MoneySnapshot s, String note, int amount, String key) =>
        money.saveTransaction(
          type: 'expense',
          amount: amount,
          walletId: s.wallets.first.id,
          categoryId: s.categories.firstWhere((c) => c.systemKey == key).id,
          note: note,
          occurredAt: DateTime(2026, 10, 21, 8),
        );

    test('dompet dan kategori ditebak', () async {
      final s = await snap();
      final items = controller.items(
        'Beli es kopi 28rb pakai gopay, parkir 2rb.',
        date,
        s,
      );
      expect(items.map((i) => s.walletById[i.walletId]!.name), [
        'GoPay',
        s.wallets.first.name,
      ]);
      expect(items.map((i) => s.categoryById[i.categoryId]!.systemKey), [
        'food',
        'transport',
      ]);
      expect(items.every((i) => i.state == TxDraftState.pending), isTrue);
    });

    test('kategori ikut transaksi lama dengan catatan sama', () async {
      var s = await snap();
      await spend(s, 'Es kopi', 10000, 'entertainment');
      s = await snap();
      final item = controller.items('Beli es kopi 28rb.', date, s).single;
      expect(s.categoryById[item.categoryId]!.systemKey, 'entertainment');
    });

    test('nominal yang sudah ada di hari itu tidak ditawarkan lagi', () async {
      var s = await snap();
      await spend(s, 'Ojek', 15000, 'transport');
      s = await snap();
      const text = 'Ojek 15rb pergi, ojek 15rb pulang.';
      expect(controller.items(text, date, s).map((i) => i.state), [
        TxDraftState.recorded,
        TxDraftState.pending,
      ]);
      // Hari lain tidak terpengaruh.
      expect(
        controller.items(text, '2026-10-20', s).map((i) => i.state).toSet(),
        {TxDraftState.pending},
      );
    });

    test('terima, batal, abaikan, ubah, dan tambah manual', () async {
      final s = await snap();
      const text = 'Kopi 25rb, roti 12rb.';
      List<TxDraft> items() => controller.items(text, date, s);
      final [kopi, roti] = items();

      controller.accept(kopi.key);
      controller.dismiss(roti.key);
      expect(items().map((i) => i.state), [
        TxDraftState.accepted,
        TxDraftState.dismissed,
      ]);

      controller.save(kopi.copyWith(note: 'Kopi susu', amount: 26000));
      expect(items().first.note, 'Kopi susu');
      expect(items().first.amount, 26000);

      controller.save(
        TxDraft(
          key: controller.newManualKey(),
          note: 'Tip',
          amount: 5000,
          type: 'expense',
          categoryId: null,
          walletId: s.wallets.first.id,
          manual: true,
        ),
      );
      expect(controller.accepted(text, date, s).map((i) => i.note), [
        'Kopi susu',
        'Tip',
      ]);

      controller.undo(items().last);
      controller.undo(items().first);
      expect(controller.accepted(text, date, s), isEmpty);
      expect(controller.hasChoices, isTrue); // roti diabaikan
    });

    test('nota tiap transaksi terpisah, pemakaian foto terlacak', () async {
      final s = await snap();
      const text = 'Kopi 25rb, roti 12rb.';
      final [kopi, roti] = controller.items(text, date, s);
      controller.photos = ['/f/1.jpg', '/f/2.jpg'];
      TxDraft withReceipt(TxDraft d, String path) => TxDraft(
        key: d.key,
        note: d.note,
        amount: d.amount,
        type: d.type,
        categoryId: d.categoryId,
        walletId: d.walletId,
        receiptPath: path,
      );

      controller.save(withReceipt(kopi, '/f/1.jpg'));
      controller.save(withReceipt(roti, '/f/2.jpg'));
      final [a, b] = controller.accepted(text, date, s);
      expect(a.receiptPath, '/f/1.jpg');
      expect(b.receiptPath, '/f/2.jpg');

      expect(
        controller.receiptUser('/f/1.jpg', exceptKey: roti.key)?.key,
        kopi.key,
      );
      // Draft sendiri tidak dihitung sebagai pemakai lain.
      expect(controller.receiptUser('/f/1.jpg', exceptKey: kopi.key), isNull);
      // Yang dibatalkan tidak lagi memakai fotonya.
      controller.undo(a);
      expect(controller.receiptUser('/f/1.jpg', exceptKey: roti.key), isNull);
    });

    test('tanpa dompet tidak menawarkan apa pun', () {
      final empty = MoneySnapshot(
        wallets: const [],
        categories: const [],
        transactions: const [],
      );
      expect(controller.items('Kopi 25rb', date, empty), isEmpty);
    });
  });
}
