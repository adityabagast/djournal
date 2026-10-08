// Uji sync sungguhan antara dua "device" (dua database lokal) lewat Supabase.
// Butuh migration supabase/migrations sudah dijalankan dan "Confirm email"
// mati. Jalankan:
//   flutter test test/sync_e2e_test.dart --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
import 'package:djournal/config.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/data/sync/backend.dart';
import 'package:djournal/data/sync/sync_engine.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Device {
  Device()
    : db = AppDatabase(NativeDatabase.memory()),
      backend = SupabaseBackend(
        // Klien Dart murni, sesi hanya di memori (tiap device terpisah).
        SupabaseClient(
          supabaseUrl,
          supabaseKey,
          // PKCE butuh penyimpanan persisten; di test cukup alur implicit.
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
        ),
      );

  final AppDatabase db;
  final SupabaseBackend backend;
  late final money = MoneyRepository(db);
  late final journal = JournalRepository(db);

  Future<void> sync() => SyncEngine(db, backend).run();
}

void main() {
  // Dua database sekaligus memang disengaja di sini (dua device).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'dua device: data pindah lewat Supabase tanpa duplikat kategori/dompet',
    () async {
      // Supabase menolak domain tanpa server email (mis. example.com).
      // "Confirm email" mati, jadi tidak ada email yang benar-benar dikirim.
      // User tes bisa dihapus di Dashboard → Authentication → Users.
      final email =
          'djournal.e2e.${DateTime.now().millisecondsSinceEpoch}@gmail.com';
      const password = 'rahasia123';

      // Device A: daftar, catat transaksi + jurnal + budget, sync.
      final a = Device();
      await a.backend.signUp(email, password);
      final aWallet = (await a.money.watchWallets().first).single;
      final aFood = (await a.money.watchCategories().first).firstWhere(
        (c) => c.systemKey == 'food',
      );
      await a.money.saveTransaction(
        type: 'expense',
        amount: 25000,
        walletId: aWallet.id,
        categoryId: aFood.id,
        note: 'Kopi susu',
        occurredAt: DateTime(2026, 10, 8, 7, 45),
      );
      await a.journal.saveEntry(
        entryDate: '2026-10-08',
        entryTime: '07:30',
        mood: 4,
        title: 'Sarapan',
        body: null,
        tags: ['pagi'],
      );
      await a.money.setBudget(
        categoryId: aFood.id,
        startMonth: '2026-10',
        amount: 1000000,
      );
      await a.sync();
      expect(await SyncEngine(a.db, a.backend).hasDirtyRows(), isFalse);

      // Device B: baru install (punya seed sendiri), lalu login dan sync.
      final b = Device();
      await b.backend.signIn(email, password);
      await b.sync();

      final bWallets = await b.money.watchWallets().first;
      final bCats = await b.money.watchCategories().first;
      final bTxs = await b.money.watchTransactions().first;
      expect(bWallets.map((w) => w.id), [
        aWallet.id,
      ], reason: 'Tunai tidak dobel');
      expect(bCats, hasLength(9), reason: 'kategori bawaan tidak dobel');
      expect(bTxs.single.note, 'Kopi susu');
      expect(bTxs.single.categoryId, aFood.id);
      final bEntry = (await b.journal.watchEntries().first).single;
      expect(bEntry.entryTime, '07:30');
      expect(entryTags(bEntry), ['pagi']);
      expect((await b.money.watchBudgets().first).single.amount, 1000000);

      // B mengedit dan menghapus; A menerima perubahannya.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await b.money.saveTransaction(
        id: bTxs.single.id,
        type: 'expense',
        amount: 30000,
        walletId: aWallet.id,
        categoryId: aFood.id,
        note: 'Kopi susu besar',
        occurredAt: DateTime(2026, 10, 8, 7, 45),
      );
      await b.journal.deleteEntry(bEntry.id);
      await b.sync();
      await a.sync();

      final aTx = (await a.money.watchTransactions().first).single;
      expect(aTx.amount, 30000);
      expect(aTx.note, 'Kopi susu besar');
      expect(await a.journal.watchEntries().first, isEmpty);

      await a.db.close();
      await b.db.close();
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: backendConfigured ? false : 'SUPABASE_URL/SUPABASE_KEY tidak diatur',
  );
}
