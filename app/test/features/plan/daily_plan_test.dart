import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/features/backup/data/backup_service.dart';
import 'package:djournal/features/plan/data/plan_repository.dart';
import 'package:djournal/features/plan/domain/daily_plan.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPlan _plan(String id, String date, {bool done = false}) {
  final ts = DateTime.utc(2026, 11, 1);
  return DailyPlan(
    id: id,
    createdAt: ts,
    updatedAt: ts,
    isDirty: true,
    title: id,
    planDate: date,
    doneAt: done ? ts : null,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('hitungan', () {
    test('progres hari: selesai, total, persen', () {
      final p = PlanProgress.of([
        _plan('a', '2026-11-23', done: true),
        _plan('b', '2026-11-23'),
        _plan('c', '2026-11-23'),
      ]);
      expect((p.done, p.total, p.percent), (1, 3, 33));
      expect(p.allDone, isFalse);
      expect(PlanProgress.of(const []).percent, 0);
      expect(PlanProgress.of(const []).allDone, isFalse);
      expect(PlanProgress.of([_plan('a', 'x', done: true)]).allDone, isTrue);
    });

    test('besok dan 7 hari terakhir melewati batas bulan', () {
      expect(nextDay('2026-11-30'), '2026-12-01');
      expect(nextDay('2026-12-31'), '2027-01-01');
      expect(lastSevenDays('2026-12-03'), [
        '2026-11-27',
        '2026-11-28',
        '2026-11-29',
        '2026-11-30',
        '2026-12-01',
        '2026-12-02',
        '2026-12-03',
      ]);
    });

    test('sisa: hanya hari lalu, belum selesai, dan belum dibiarkan', () {
      final plans = [
        _plan('lama', '2026-11-20'),
        _plan('kemarin', '2026-11-22'),
        _plan('beres', '2026-11-22', done: true),
        _plan('kini', '2026-11-23'),
        _plan('besok', '2026-11-24'),
      ];
      expect(leftovers(plans, '2026-11-23').map((p) => p.id), [
        'lama',
        'kemarin',
      ]);
      expect(
        leftovers(
          plans,
          '2026-11-23',
          ignoredThrough: '2026-11-21',
        ).map((p) => p.id),
        ['kemarin'],
      );
      expect(
        leftovers(plans, '2026-11-23', ignoredThrough: '2026-11-22'),
        isEmpty,
      );
    });
  });

  group('repository', () {
    late AppDatabase db;
    late PlanRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PlanRepository(db);
    });
    tearDown(() => db.close());

    Future<List<DailyPlan>> all() => repo.watchFrom('2026-01-01').first;

    test('tambah, centang, batal centang, ubah, pindah, hapus', () async {
      final id = await repo.add(title: '  Olahraga ', date: '2026-11-24');
      var p = (await all()).single;
      expect((p.title, p.planDate, p.doneAt), ('Olahraga', '2026-11-24', null));

      await repo.setDone(id, true);
      expect((await all()).single.doneAt, isNotNull);
      await repo.setDone(id, false);
      expect((await all()).single.doneAt, isNull);

      await repo.rename(id, 'Lari pagi');
      await repo.setDone(id, true);
      await repo.move([id], '2026-11-25');
      p = (await all()).single;
      // Dipindah ke hari lain = belum dikerjakan.
      expect(
        (p.title, p.planDate, p.doneAt),
        ('Lari pagi', '2026-11-25', null),
      );

      await repo.delete(id);
      expect(await all(), isEmpty);
      expect(
        (await db.select(db.dailyPlans).get()).single.deletedAt,
        isNotNull,
      );
    });

    test('urut sesuai waktu ditambahkan dan hanya dari tanggal awal', () async {
      await repo.add(title: 'lama', date: '2026-10-01');
      await repo.add(title: 'satu', date: '2026-11-24');
      await repo.add(title: 'dua', date: '2026-11-24');
      final rows = await repo.watchFrom('2026-11-01').first;
      expect(rows.map((p) => p.title), ['satu', 'dua']);
    });

    test('hapus semua data ikut menghapus rencana', () async {
      await repo.add(title: 'a', date: '2026-11-24');
      await db.resetData();
      expect(await db.select(db.dailyPlans).get(), isEmpty);
    });
  });

  test('rencana ikut backup JSON dan pulih di HP lain', () async {
    final a = AppDatabase(NativeDatabase.memory());
    final b = AppDatabase(NativeDatabase.memory());
    final id = await PlanRepository(a).add(title: 'Servis', date: '2026-11-24');
    await PlanRepository(a).setDone(id, true);
    await BackupService(b).importJson(await BackupService(a).exportJson());
    final row = (await b.select(b.dailyPlans).get()).single;
    expect((row.id, row.title, row.planDate), (id, 'Servis', '2026-11-24'));
    expect(row.doneAt, isNotNull);
    await a.close();
    await b.close();
  });
}
