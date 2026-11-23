import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/format.dart';
import '../data/plan_repository.dart';
import '../domain/daily_plan.dart';

final planRepositoryProvider = Provider(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);

/// Rencana 30 hari terakhir dan yang akan datang.
final plansProvider = StreamProvider<List<DailyPlan>>(
  (ref) => ref
      .watch(planRepositoryProvider)
      .watchFrom(planHistoryStart(toLocalDate(DateTime.now()))),
);

/// Sisa rencana sampai tanggal ini dibiarkan user (lokal).
const planIgnoredKey = 'plan_left_ignored';

final planIgnoredThroughProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(planIgnoredKey),
);
