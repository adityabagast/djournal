import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/database/app_database.dart';
import '../data/reminder_notifier.dart';
import '../data/reminder_repository.dart';
import '../data/reminder_service.dart';
import '../../../core/database/database_providers.dart';

final reminderRepositoryProvider = Provider(
  (ref) => ReminderRepository(ref.watch(databaseProvider)),
);

final reminderNotifierProvider = Provider<ReminderNotifier>(
  (ref) => PlatformInfo.isAndroid
      ? AndroidReminderNotifier()
      : const NoopReminderNotifier(),
);

final reminderServiceProvider = Provider(
  (ref) => ReminderService(
    ref.watch(reminderRepositoryProvider),
    ref.watch(reminderNotifierProvider),
  ),
);

/// Acara mendatang (hari ini dan seterusnya), terdekat dulu.
final upcomingRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final today = toLocalDate(DateTime.now());
  // Acara yang sudah lewat tidak dipakai lagi; bersihkan sambil lalu.
  repo.pruneBefore(today).ignore();
  return repo.watchUpcoming(today);
});

/// Apakah notifikasi diizinkan. Invalidate setelah meminta izin.
final reminderPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderNotifierProvider).isAllowed(),
);
