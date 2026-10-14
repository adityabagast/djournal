import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import 'database_providers.dart';

/// Semua entri jurnal aktif, tanggal terbaru dulu.
final journalEntriesProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(journalRepositoryProvider).watchEntries(),
);

