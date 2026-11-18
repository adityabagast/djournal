import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_providers.dart';
import 'attachment_repository.dart';

final attachmentRepositoryProvider = Provider(
  (ref) => AttachmentRepository(ref.watch(databaseProvider)),
);

/// Stream semua lampiran aktif.
final allAttachmentsProvider = StreamProvider<List<Attachment>>(
  (ref) => ref.watch(attachmentRepositoryProvider).watchAllAttachments(),
);

/// Lookup map gambar berdasarkan entryId untuk performa cepat di timeline/list.
final entryAttachmentsMapProvider = Provider<Map<String, List<Attachment>>>((
  ref,
) {
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
