import 'dart:math';

import 'package:djournal/features/games/domain/games.dart';
import 'package:djournal/features/games/presentation/games_hub_screen.dart';
import 'package:djournal/features/games/presentation/games_screen.dart';
import 'package:djournal/features/games/presentation/memory_screen.dart';
import 'package:djournal/features/games/presentation/prompt_screen.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/l10n/app_localizations_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget home) => ProviderScope(
  overrides: [
    // Tanpa database: daftar bawaan dipakai.
    wheelListsProvider.overrideWithValue(const AsyncValue.data({})),
    wheelColorsProvider.overrideWithValue(
      const AsyncValue.data(WheelColors(palette: 'custom')),
    ),
    memoryBestProvider.overrideWithValue(const AsyncValue.data(null)),
  ],
  child: MaterialApp(
    locale: const Locale('id'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  ),
);

Widget _app() => _wrap(WheelRpsScreen(random: Random(1)));

void main() {
  test('batu gunting kertas: tiap tangan mengalahkan berikutnya', () {
    expect(playRps(Hand.rock, Hand.scissors), RpsOutcome.win);
    expect(playRps(Hand.scissors, Hand.paper), RpsOutcome.win);
    expect(playRps(Hand.paper, Hand.rock), RpsOutcome.win);
    expect(playRps(Hand.scissors, Hand.rock), RpsOutcome.lose);
    expect(playRps(Hand.paper, Hand.paper), RpsOutcome.tie);
  });

  test('roda berhenti tepat di irisan yang dipilih', () {
    final random = Random(7);
    for (final count in [2, 3, 6, 12]) {
      for (var k = 0; k < count; k++) {
        final turns = Wheel.target(0.37, k, count, random);
        expect(Wheel.indexAt(turns, count), k, reason: 'n=$count k=$k');
        expect(turns, greaterThan(5));
      }
    }
  });

  test('warna roda: irisan terakhir tidak sama dengan irisan pertama', () {
    expect(Wheel.colorSlot(6, 7), 2);
    expect(Wheel.colorSlot(6, 8), 0);
    expect(Wheel.colorSlot(5, 6), 5);
    expect(Wheel.colorSlot(0, 1), 0);
  });

  test('warna roda: JSON rusak jatuh ke bawaan, slot diubah', () {
    final bad = WheelColors.fromJson({
      'palette': 'neon',
      'custom': ['#zzz'],
    });
    expect(bad.palette, WheelColors.defaultPalette);
    expect(bad.custom, WheelColors.defaults);

    final w = const WheelColors(palette: 'custom').withSlot(2, '#abcdef');
    expect(w.custom[2], '#ABCDEF');
    final back = WheelColors.fromJson(w.toJson());
    expect(back.palette, 'custom');
    expect(back.custom, w.custom);
    expect(w.resetCustom().custom, WheelColors.defaults);
  });

  testWidgets('roda: kartu warna kustom menampilkan slot & palet', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.scrollUntilVisible(
      find.text('Atur ulang'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Warna roda'), findsOneWidget);
    expect(find.text('Pelangi'), findsOneWidget);
    expect(find.bySemanticsLabel('Warna irisan 6'), findsOneWidget);
    expect(find.bySemanticsLabel('Pakai warna #3F3F46'), findsOneWidget);
  });

  testWidgets('roda: putar lalu Nyaw mengumumkan pilihan', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Ketuk Putar'), findsOneWidget);

    await tester.tap(find.text('Putar'));
    await tester.pump();
    expect(find.text('Tunggu ya'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Nyaw pilih'), findsOneWidget);
    expect(find.text('Putar lagi'), findsOneWidget);
    // Daftar makan: tombol catat pengeluaran muncul.
    expect(find.text('Catat pengeluaran'), findsOneWidget);
  });

  testWidgets('roda: daftar Ya/Tidak tidak menawarkan catat pengeluaran', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Ya / Tidak'));
    await tester.pump();
    await tester.tap(find.text('Putar'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Putar lagi'), findsOneWidget);
    expect(find.text('Catat pengeluaran'), findsNothing);
  });

  testWidgets('suit: skor bertambah setelah satu ronde', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Batu gunting kertas'));
    await tester.pump();

    await tester.tap(find.text('Batu').last);
    await tester.pump();
    expect(find.text('Batu… gunting… kertas!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    final results = ['Kamu menang!', 'Nyaw menang', 'Seri, coba lagi'];
    expect(
      results.where((r) => find.text(r).evaluate().isNotEmpty),
      hasLength(1),
    );

    // Tepat satu dari tiga skor jadi 1.
    expect(find.text('1'), findsOneWidget);
  });

  test(
    'memory: pasangan cocok tetap terbuka, tidak cocok menunggu ditutup',
    () {
      final g = MemoryGame(Random(3));
      final a = 0;
      final same = List.generate(
        12,
        (i) => i,
      ).firstWhere((i) => i != a && g.deck[i] == g.deck[a]);
      final other = List.generate(
        12,
        (i) => i,
      ).firstWhere((i) => g.deck[i] != g.deck[a]);

      g.flip(a);
      g.flip(other);
      expect(g.mismatch, isTrue);
      expect(g.moves, 1);
      expect(g.flip(same), isFalse, reason: 'terkunci sampai ditutup');
      g.hideMismatch();
      expect(g.open, isEmpty);

      g.flip(a);
      g.flip(same);
      expect(g.matched, {a, same});
      expect(g.moves, 2);
      expect(g.flip(a), isFalse, reason: 'kartu cocok tidak bisa dibalik lagi');
    },
  );

  test('memory: semua pasang cocok = menang', () {
    final g = MemoryGame(Random(9));
    for (var k = 0; k < MemoryGame.pairs; k++) {
      final idx = [
        for (var i = 0; i < 12; i++)
          if (g.deck[i] == k) i,
      ];
      g.flip(idx[0]);
      g.flip(idx[1]);
    }
    expect(g.won, isTrue);
    expect(g.moves, MemoryGame.pairs);
  });

  testWidgets('memory: layar menampilkan 12 kartu tertutup dan rekor kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(MemoryScreen(random: Random(1))));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Kartu tertutup 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Kartu tertutup 12'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kartu tertutup 1'));
    await tester.pump();
    expect(find.bySemanticsLabel('Kartu terbuka'), findsOneWidget);
  });

  test('kantong kocok: semua keluar sebelum ulang, tanpa kembar berurutan', () {
    final bag = ShuffleBag(5, Random(4));
    var last = -1;
    for (var round = 0; round < 20; round++) {
      final seen = <int>{};
      for (var k = 0; k < 5; k++) {
        final v = bag.next();
        expect(v, isNot(last), reason: 'ronde $round urutan $k');
        expect(
          seen.add(v),
          isTrue,
          reason: 'tidak boleh ulang dalam satu ronde',
        );
        last = v;
      }
      expect(seen, {0, 1, 2, 3, 4});
    }
  });

  testWidgets('kocok ide: tiap kocok pertanyaan beda, kategori bisa dipilih', (
    tester,
  ) async {
    final l = AppLocalizationsId();
    final gratitude = l.gamePromptGratitudeList.split('|');
    final dreams = l.gamePromptDreamsList.split('|');
    expect(gratitude.length, greaterThanOrEqualTo(20));

    String shown(List<String> from) =>
        from.singleWhere((q) => find.text(q).evaluate().isNotEmpty);

    await tester.pumpWidget(_wrap(PromptScreen(random: Random(2))));
    await tester.pumpAndSettle();

    final seen = <String>[shown(gratitude)];
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Kocok lagi'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      final q = shown(gratitude);
      expect(q, isNot(seen.last));
      seen.add(q);
    }
    expect(seen.toSet().length, seen.length, reason: 'belum ada yang berulang');

    await tester.tap(find.text('Mimpi'));
    await tester.pump();
    expect(dreams, contains(shown(dreams)));
  });

  testWidgets('hub: empat permainan dan kartu rehat di Hari Ini', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const GamesHubScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Roda putar'), findsOneWidget);
    expect(find.text('Batu gunting kertas'), findsOneWidget);
    expect(find.text('Memory kartu'), findsOneWidget);
    expect(find.text('Kocok pertanyaan'), findsOneWidget);

    await tester.tap(find.text('Memory kartu'));
    await tester.pumpAndSettle();
    expect(find.text('Cocokkan 6 pasang pose Nyaw.'), findsOneWidget);
  });

  testWidgets('RestCard membuka hub lewat Semua permainan', (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: RestCard())));
    await tester.pumpAndSettle();
    expect(find.text('Rehat sebentar'), findsOneWidget);
    await tester.tap(find.text('Semua permainan'));
    await tester.pumpAndSettle();
    expect(find.text('Rehat dulu, yuk'), findsOneWidget);
  });
}
