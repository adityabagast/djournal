import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/app_database.dart';
import 'data/journal_repository.dart';
import 'data/money_repository.dart';
import 'data/money_snapshot.dart';
import 'data/settings_repository.dart';

// Provider = semacam registrasi DI di .NET (services.AddSingleton<...>).
// Widget mengambilnya lewat ref.watch(...) dan otomatis rebuild saat data berubah.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final moneyRepositoryProvider = Provider(
  (ref) => MoneyRepository(ref.watch(databaseProvider)),
);

final journalRepositoryProvider = Provider(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

/// Semua entri jurnal aktif, tanggal terbaru dulu.
final journalEntriesProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(journalRepositoryProvider).watchEntries(),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final _walletsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchWallets(),
);

final _categoriesProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchCategories(),
);

final _transactionsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchTransactions(),
);

final _budgetsProvider = StreamProvider(
  (ref) => ref.watch(moneyRepositoryProvider).watchBudgets(),
);

/// Gabungan dompet + kategori + transaksi + budget. Ter-update otomatis
/// setiap ada perubahan di database.
final moneySnapshotProvider = Provider<AsyncValue<MoneySnapshot>>((ref) {
  final parts = [
    ref.watch(_walletsProvider),
    ref.watch(_categoriesProvider),
    ref.watch(_transactionsProvider),
    ref.watch(_budgetsProvider),
  ];
  for (final p in parts) {
    if (p.hasError) return AsyncValue.error(p.error!, p.stackTrace!);
  }
  final wallets = parts[0].value as List<Wallet>?;
  final categories = parts[1].value as List<Category>?;
  final txs = parts[2].value as List<MoneyTx>?;
  final budgets = parts[3].value as List<Budget>?;
  if (wallets == null || categories == null || txs == null || budgets == null) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    MoneySnapshot(
      wallets: wallets,
      categories: categories,
      transactions: txs,
      budgets: budgets,
    ),
  );
});

/// Bahasa aplikasi: 'id' (default) atau 'en'.
final localeProvider = StreamProvider<Locale>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch('language')
      .map((code) => Locale(code ?? 'id')),
);
