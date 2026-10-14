import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/journal_repository.dart';
import '../data/money_repository.dart';
import '../data/settings_repository.dart';

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

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

