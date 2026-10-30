import 'package:djournal/data/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

// Schema lama ada di drift_schemas/. Setelah menaikkan schemaVersion:
//   dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/drift_schema_vN.json
//   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  const latest = 6;

  for (var from = 1; from < latest; from++) {
    test('upgrade v$from -> v$latest menghasilkan schema yang sama', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      await verifier.migrateAndValidate(db, latest);
      await db.close();
    });
  }

  test('data v1 tetap utuh setelah upgrade ke versi terbaru', () async {
    final schema = await verifier.schemaAt(1);
    const ts = 1791504000; // 2026-10-08 UTC, detik
    schema.rawDatabase
      ..execute(
        'INSERT INTO wallets (id, created_at, updated_at, name, type, opening_balance) '
        "VALUES ('w1', $ts, $ts, 'BCA', 'bank', 1500000)",
      )
      ..execute(
        'INSERT INTO journal_entries (id, created_at, updated_at, entry_date, mood, title, body) '
        "VALUES ('e1', $ts, $ts, '2026-10-08', 4, 'Hari pertama', 'Isi lama')",
      )
      ..execute(
        'INSERT INTO attachments (id, created_at, updated_at, entry_id, mime_type, size_bytes) '
        "VALUES ('a1', $ts, $ts, 'e1', 'image/jpeg', 2048)",
      );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);

    final wallet = await (db.select(
      db.wallets,
    )..where((w) => w.id.equals('w1'))).getSingle();
    expect(wallet.name, 'BCA');
    expect(wallet.openingBalance, 1500000);

    final entry = await (db.select(
      db.journalEntries,
    )..where((e) => e.id.equals('e1'))).getSingle();
    expect(entry.title, 'Hari pertama');
    expect(entry.audioPath, isNull);

    final attachment = await (db.select(
      db.attachments,
    )..where((a) => a.id.equals('a1'))).getSingle();
    expect(attachment.entryId, 'e1');
    expect(attachment.transactionId, isNull);

    expect(await db.select(db.wishlists).get(), isEmpty);
    expect(await db.select(db.bills).get(), isEmpty);
    await db.close();
  });

  test('upgrade v5 -> v6 mengisi due_day dari tanggal jatuh tempo', () async {
    final schema = await verifier.schemaAt(5);
    const ts = 1791504000;
    schema.rawDatabase.execute(
      'INSERT INTO bills (id, created_at, updated_at, title, amount, due_date, repeat_interval) '
      "VALUES ('b1', $ts, $ts, 'Listrik', 250000, '2026-11-07', 'monthly')",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, latest);
    final bill = await db.select(db.bills).getSingle();
    expect(bill.dueDay, 7);
    await db.close();
  });
}
