import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  /// Rencana sejak [from] (YYYY-MM-DD), urut tanggal lalu waktu ditambahkan.
  Stream<List<DailyPlan>> watchFrom(String from) {
    final q = _db.select(_db.dailyPlans)
      ..where(
        (p) => p.deletedAt.isNull() & p.planDate.isBiggerOrEqualValue(from),
      )
      ..orderBy([
        (p) => OrderingTerm(expression: p.planDate),
        (p) => OrderingTerm(expression: p.createdAt),
        (p) => OrderingTerm(expression: p.rowId),
      ]);
    return q.watch();
  }

  Future<String> add({required String title, required String date}) async {
    final now = DateTime.now().toUtc();
    final id = newId();
    await _db
        .into(_db.dailyPlans)
        .insert(
          DailyPlansCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            title: title.trim(),
            planDate: date,
          ),
        );
    return id;
  }

  Future<void> setDone(String id, bool done) => _update([
    id,
  ], DailyPlansCompanion(doneAt: Value(done ? DateTime.now().toUtc() : null)));

  Future<void> rename(String id, String title) =>
      _update([id], DailyPlansCompanion(title: Value(title.trim())));

  /// Pindah ke [date] sebagai belum dikerjakan.
  Future<void> move(List<String> ids, String date) => _update(
    ids,
    DailyPlansCompanion(planDate: Value(date), doneAt: const Value(null)),
  );

  Future<void> delete(String id) => _update([
    id,
  ], DailyPlansCompanion(deletedAt: Value(DateTime.now().toUtc())));

  Future<void> _update(List<String> ids, DailyPlansCompanion row) =>
      (_db.update(_db.dailyPlans)..where((p) => p.id.isIn(ids))).write(
        row.copyWith(
          updatedAt: Value(DateTime.now().toUtc()),
          isDirty: const Value(true),
        ),
      );
}
