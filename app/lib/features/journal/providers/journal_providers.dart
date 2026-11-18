import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../data/journal_repository.dart';

final journalRepositoryProvider = Provider(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

/// Semua entri jurnal aktif, tanggal terbaru dulu.
final journalEntriesProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(journalRepositoryProvider).watchEntries(),
);

