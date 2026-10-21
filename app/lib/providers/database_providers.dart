import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attachment_repository.dart';
import '../data/bill_repository.dart';
import '../data/db/app_database.dart';
import '../data/journal_repository.dart';
import '../data/money_repository.dart';
import '../data/settings_repository.dart';
import '../data/wishlist_repository.dart';

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

final wishlistRepositoryProvider = Provider(
  (ref) => WishlistRepository(ref.watch(databaseProvider)),
);

final billRepositoryProvider = Provider(
  (ref) => BillRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final attachmentRepositoryProvider = Provider(
  (ref) => AttachmentRepository(ref.watch(databaseProvider)),
);

/// Stream semua lampiran aktif.
final allAttachmentsProvider = StreamProvider<List<Attachment>>(
  (ref) => ref.watch(attachmentRepositoryProvider).watchAllAttachments(),
);

/// Lookup map gambar berdasarkan entryId untuk performa cepat di timeline/list.
final entryAttachmentsMapProvider = Provider<Map<String, List<Attachment>>>((ref) {
  final all = ref.watch(allAttachmentsProvider).value ?? const [];
  final map = <String, List<Attachment>>{};
  for (final att in all) {
    if (att.entryId != null) {
      map.putIfAbsent(att.entryId!, () => []).add(att);
    }
  }
  return map;
});

/// Lookup map struk berdasarkan transactionId untuk performa cepat di timeline/list.
final txAttachmentMapProvider = Provider<Map<String, Attachment>>((ref) {
  final all = ref.watch(allAttachmentsProvider).value ?? const [];
  final map = <String, Attachment>{};
  for (final att in all) {
    if (att.transactionId != null) {
      map[att.transactionId!] = att;
    }
  }
  return map;
});
