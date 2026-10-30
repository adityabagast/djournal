import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'app_database.g.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Budgets,
    JournalEntries,
    Wishlists,
    Bills,
    Attachments,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seed();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(journalEntries, journalEntries.audioPath);
        await m.addColumn(journalEntries, journalEntries.audioDurationMs);
        await m.addColumn(journalEntries, journalEntries.audioTranscript);
      }
      if (from < 3) {
        await m.addColumn(attachments, attachments.transactionId);
      }
      if (from < 4) {
        await m.createTable(wishlists);
        await m.createTable(bills);
      }
      if (from < 5) {
        // Upgrade dari v1/v2 dulu tidak mengubah entry_id jadi nullable dan
        // tidak membuat index, sehingga foto struk transaksi gagal disimpan.
        // Bangun ulang tabelnya; aman juga untuk instalasi baru v3/v4.
        await m.alterTable(TableMigration(attachments));
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attachment_entry ON attachments (entry_id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attachment_tx ON attachments (transaction_id)',
        );
      }
      if (from < 6) {
        // Dari < v4 tabel bills baru dibuat di atas, sudah lengkap.
        if (from >= 4) await m.addColumn(bills, bills.dueDay);
        // Tanggal asli tagihan lama tidak diketahui; pakai hari jatuh tempo
        // saat ini sebagai patokan terbaik.
        await customStatement(
          'UPDATE bills SET due_day = CAST(substr(due_date, 9, 2) AS INTEGER)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      // Nama file lama; jangan diganti, nanti data lokal di web tidak terbaca.
      name: 'djournal',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// Hapus semua data yang disinkronkan lalu isi ulang data awal.
  /// Dipakai saat logout; pengaturan lokal (bahasa, alamat server) tetap.
  Future<void> resetData() => transaction(() async {
    for (final table in <TableInfo>[
      attachments,
      journalEntries,
      wishlists,
      bills,
      budgets,
      transactions,
      categories,
      wallets,
    ]) {
      await delete(table).go();
    }
    await seed();
  });

  /// Data awal: satu dompet dan kategori bawaan (docs/data-model.md §4.2).
  Future<void> seed() async {
    final now = DateTime.now().toUtc();

    await into(wallets).insert(
      WalletsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        name: 'Tunai',
        type: 'cash',
      ),
    );

    const expense = [
      ('food', 'Makan', '#9A3412'),
      ('transport', 'Transport', '#1E4E79'),
      ('shopping', 'Belanja', '#6B2C7A'),
      ('bills', 'Tagihan', '#7A5A00'),
      ('entertainment', 'Hiburan', '#1F5F4E'),
      ('other', 'Lainnya', '#4A4E4C'),
    ];
    const income = [
      ('salary', 'Gaji', '#17624A'),
      ('bonus', 'Bonus', '#1E4E79'),
      ('other_income', 'Lainnya', '#4A4E4C'),
    ];

    await batch((b) {
      var order = 0;
      for (final (key, name, color) in expense) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            name: name,
            kind: 'expense',
            color: color,
            systemKey: Value(key),
            sortOrder: Value(order++),
          ),
        );
      }
      order = 0;
      for (final (key, name, color) in income) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            name: name,
            kind: 'income',
            color: color,
            systemKey: Value(key),
            sortOrder: Value(order++),
          ),
        );
      }
    });
  }
}
