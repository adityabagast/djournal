import 'dart:async';

import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/core/storage/settings_repository.dart';
import 'package:djournal/core/theme.dart';
import 'package:djournal/features/plan/data/plan_repository.dart';
import 'package:djournal/features/plan/presentation/plan_screen.dart';
import 'package:djournal/features/plan/presentation/plan_section.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DailyPlan _plan(String title, String date, {bool done = false}) {
  final ts = DateTime.utc(2026, 11, 1);
  return DailyPlan(
    id: title,
    createdAt: ts,
    updatedAt: ts,
    isDirty: true,
    title: title,
    planDate: date,
    doneAt: done ? ts : null,
  );
}

/// Pengganti drift, yang macet di testWidgets.
class _FakeRepo implements PlanRepository {
  _FakeRepo(this.rows);

  List<DailyPlan> rows;
  final _changes = StreamController<void>.broadcast();

  void _set(List<DailyPlan> next) {
    rows = next;
    _changes.add(null);
  }

  @override
  Stream<List<DailyPlan>> watchFrom(String from) async* {
    yield rows;
    await for (final _ in _changes.stream) {
      yield rows;
    }
  }

  @override
  Future<String> add({required String title, required String date}) async {
    _set([...rows, _plan(title, date)]);
    return title;
  }

  @override
  Future<void> setDone(String id, bool done) async => _set([
    for (final p in rows)
      p.id == id ? _plan(p.title, p.planDate, done: done) : p,
  ]);

  @override
  Future<void> rename(String id, String title) async =>
      _set([for (final p in rows) p.id == id ? _plan(title, p.planDate) : p]);

  @override
  Future<void> move(List<String> ids, String date) async => _set([
    for (final p in rows) ids.contains(p.id) ? _plan(p.title, date) : p,
  ]);

  @override
  Future<void> delete(String id) async => _set([
    for (final p in rows)
      if (p.id != id) p,
  ]);
}

class _FakeSettings implements SettingsRepository {
  final values = <String, String>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<String?> watch(String key) async* {
    yield values[key];
    await for (final _ in _changes.stream) {
      yield values[key];
    }
  }

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
    _changes.add(null);
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
    _changes.add(null);
  }
}

const _today = '2026-11-23';
const _tomorrow = '2026-11-24';
final _night = DateTime(2026, 11, 23, 20);
final _morning = DateTime(2026, 11, 23, 7);

Future<(_FakeRepo, _FakeSettings)> _pump(
  WidgetTester tester,
  List<DailyPlan> rows, {
  Widget? home,
  DateTime? now,
  String lang = 'id',
}) async {
  tester.view.physicalSize = const Size(420, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo(rows);
  final settings = _FakeSettings();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planRepositoryProvider.overrideWithValue(repo),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home:
            home ??
            Scaffold(
              body: SingleChildScrollView(
                child: PlanSection(now: now ?? _night),
              ),
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (repo, settings);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, Finder finder, double dx) async {
  // Bertahap dan pelan supaya jarak, bukan kecepatan, yang menentukan.
  await tester.timedDrag(finder, Offset(dx, 0), const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('centang mengubah persen dan memberi selamat saat tuntas', (
    tester,
  ) async {
    await _pump(tester, [
      _plan('Belanja', _today, done: true),
      _plan('Olahraga', _today),
    ]);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 dari 2 selesai'), findsOneWidget);
    expect(find.textContaining('Semua rencana'), findsNothing);

    await _tap(tester, find.text('Olahraga'));
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining('Semua rencana'), findsOneWidget);

    await _tap(tester, find.text('Belanja'));
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('kosong: satu kartu dengan satu tombol', (tester) async {
    await _pump(tester, const []);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('Buat rencana'), findsOneWidget);
    expect(find.text('Geser: besok'), findsNothing);
  });

  testWidgets('geser kartu untuk berpindah hari', (tester) async {
    await _pump(tester, [_plan('Lari', _today), _plan('Servis', _tomorrow)]);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('Lari'), findsOneWidget);
    expect(find.text('Servis'), findsNothing);

    await _drag(tester, find.text('Rencana hari ini'), -120);
    expect(find.text('Rencana besok'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
    expect(find.text('Lari'), findsNothing);
    expect(find.text('1 rencana · Selasa, 24 Nov'), findsOneWidget);

    // Tidak ada halaman lagi ke kanan.
    await _drag(tester, find.text('Rencana besok'), -120);
    expect(find.text('Servis'), findsOneWidget);

    await _drag(tester, find.text('Rencana besok'), 120);
    expect(find.text('Lari'), findsOneWidget);
  });

  testWidgets('geser pendek tidak memindah dan tidak mencentang', (
    tester,
  ) async {
    final (repo, _) = await _pump(tester, [_plan('Lari', _today)]);
    await _drag(tester, find.text('Lari'), -30);
    expect(find.text('Rencana hari ini'), findsOneWidget);
    expect(repo.rows.single.doneAt, isNull);
  });

  testWidgets('titik di bawah kartu juga memindah hari', (tester) async {
    await _pump(tester, [_plan('Lari', _today)]);
    await _tap(tester, find.byTooltip('Lihat rencana besok'));
    expect(find.text('Belum ada rencana untuk besok'), findsOneWidget);
    await _tap(tester, find.byTooltip('Lihat rencana hari ini'));
    expect(find.text('Lari'), findsOneWidget);
  });

  testWidgets('rencana besok belum bisa dicentang dari kartu', (tester) async {
    final (repo, _) = await _pump(tester, [_plan('Servis', _tomorrow)]);
    await _tap(tester, find.byTooltip('Lihat rencana besok'));
    await _tap(tester, find.text('Servis'));
    expect(repo.rows.single.doneAt, isNull);
  });

  testWidgets('popup: pilih hari, tulis beberapa, kartu pindah ke harinya', (
    tester,
  ) async {
    final (repo, _) = await _pump(tester, const []);
    await _tap(tester, find.text('Buat rencana'));
    // Malam: pilihan awal besok.
    expect(find.text('Mau ngapain besok?'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    await _tap(tester, find.text('Hari ini'));
    expect(find.text('Mau ngapain hari ini?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('planAddText')), ' Baca ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);

    await _tap(tester, find.text('Besok').first);
    await tester.enterText(find.byKey(const Key('planAddText')), 'Servis');
    await tester.pump();
    await _tap(tester, find.byTooltip('Tambahkan ke daftar'));
    await tester.enterText(find.byKey(const Key('planAddText')), 'Batal ini');
    await tester.pump();
    await _tap(tester, find.byTooltip('Tambahkan ke daftar'));
    await _tap(tester, find.byTooltip('Batalkan Batal ini'));

    await tester.enterText(find.byKey(const Key('planAddText')), 'Olahraga');
    await tester.pump();
    await _tap(tester, find.text('Simpan'));

    expect(repo.rows.map((p) => (p.title, p.planDate)), [
      ('Baca', _today),
      ('Servis', _tomorrow),
      ('Olahraga', _tomorrow),
    ]);
    // Kartu langsung menampilkan hari dari rencana terakhir.
    expect(find.text('Rencana besok'), findsOneWidget);
    expect(find.text('Olahraga'), findsOneWidget);
  });

  testWidgets('popup: pagi pilihan awal hari ini, kosong tidak disimpan', (
    tester,
  ) async {
    final (repo, _) = await _pump(tester, const [], now: _morning);
    await _tap(tester, find.text('Buat rencana'));
    expect(find.text('Mau ngapain hari ini?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('planAddText')), '   ');
    await tester.pump();
    await _tap(tester, find.text('Tutup'));
    expect(repo.rows, isEmpty);
    expect(find.text('Buat rencana'), findsOneWidget);
  });

  testWidgets('popup dari halaman besok memilih besok', (tester) async {
    await _pump(tester, [_plan('Lari', _today)], now: _morning);
    await _tap(tester, find.byTooltip('Lihat rencana besok'));
    await _tap(tester, find.text('Tambah'));
    expect(find.text('Mau ngapain besok?'), findsOneWidget);
  });

  testWidgets('sisa hari lalu bisa dipindah ke hari ini', (tester) async {
    final (repo, _) = await _pump(tester, [
      _plan('Cuci sepatu', '2026-11-22'),
      _plan('Beres', '2026-11-22', done: true),
    ]);
    expect(find.text('1 rencana sebelumnya belum selesai'), findsOneWidget);
    await _tap(tester, find.text('Pindahkan ke hari ini'));
    expect(repo.rows.first.planDate, _today);
    expect(repo.rows.last.planDate, '2026-11-22');
    expect(find.textContaining('belum selesai'), findsNothing);
  });

  testWidgets('sisa yang dibiarkan tidak ditawarkan lagi', (tester) async {
    final (repo, settings) = await _pump(tester, [
      _plan('Cuci sepatu', '2026-11-22'),
    ]);
    await _tap(tester, find.text('Biarkan'));
    expect(settings.values[planIgnoredKey], '2026-11-22');
    expect(find.textContaining('belum selesai'), findsNothing);
    expect(repo.rows.single.planDate, '2026-11-22');
  });

  testWidgets('lebih dari 4 rencana diringkas', (tester) async {
    await _pump(tester, [
      for (var i = 1; i <= 6; i++) _plan('Rencana $i', _today),
    ]);
    expect(find.text('Rencana 4'), findsOneWidget);
    expect(find.text('Rencana 5'), findsNothing);
    expect(find.text('+2 lainnya'), findsOneWidget);
  });

  testWidgets('halaman: ubah, pindah hari, hapus, dan progres 7 hari', (
    tester,
  ) async {
    final (repo, _) = await _pump(tester, [
      _plan('Lari', _today),
      _plan('Baca', _today),
      _plan('Kemarin', '2026-11-22', done: true),
    ], home: PlanScreen(now: _night));
    expect(find.text('0/2 selesai'), findsOneWidget);
    expect(find.text('1 hari tuntas'), findsOneWidget);

    await _tap(tester, find.byTooltip('Atur Lari'));
    await tester.enterText(find.byType(TextField).last, 'Lari pagi');
    await _tap(tester, find.text('Simpan'));
    expect(find.text('Lari pagi'), findsOneWidget);

    await _tap(tester, find.byTooltip('Atur Baca'));
    await _tap(tester, find.text('Pindahkan ke besok'));
    expect(find.text('Baca'), findsNothing);
    expect(repo.rows[1].planDate, _tomorrow);

    await _tap(tester, find.text('Besok'));
    expect(find.text('1 rencana'), findsOneWidget);
    // Rencana besok belum bisa dicentang.
    await _tap(tester, find.text('Baca'));
    expect(repo.rows[1].doneAt, isNull);

    await _tap(tester, find.byTooltip('Atur Baca'));
    await _tap(tester, find.text('Hapus'));
    expect(find.text('Baca'), findsNothing);
    expect(repo.rows, hasLength(2));
  });

  testWidgets('halaman: nama kosong tidak disimpan', (tester) async {
    final (repo, _) = await _pump(tester, [
      _plan('Lari', _today),
    ], home: PlanScreen(now: _night));
    await _tap(tester, find.byTooltip('Atur Lari'));
    await tester.enterText(find.byType(TextField).last, '   ');
    await _tap(tester, find.text('Simpan'));
    expect(repo.rows.single.title, 'Lari');
    expect(find.text('Atur rencana'), findsOneWidget);
  });

  testWidgets('teks Inggris tampil', (tester) async {
    await _pump(tester, const [], lang: 'en');
    expect(find.text('Make a plan'), findsOneWidget);
  });
}
