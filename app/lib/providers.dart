// Barrel semua provider Riverpod. Tiap provider tinggal di fiturnya
// (lib/features/<fitur>/providers/) atau di lib/core/ untuk yang dipakai bersama.

// core
export 'core/attachments/attachment_providers.dart';
export 'core/database/database_providers.dart';

// features
export 'features/backup/providers/google_drive_providers.dart';
export 'features/feedback/providers/feedback_providers.dart';
export 'features/journal/providers/journal_providers.dart';
export 'features/money/providers/bill_providers.dart';
export 'features/money/providers/global_budget_providers.dart';
export 'features/money/providers/money_providers.dart';
export 'features/money/providers/wishlist_providers.dart';
export 'features/plan/providers/plan_providers.dart';
export 'features/reminders/providers/reminder_providers.dart';
export 'features/settings/providers/settings_providers.dart';
export 'features/today/providers/streak_providers.dart';
export 'features/update/providers/update_controller.dart'
    show
        appVersionProvider,
        updateAutoProvider,
        updateLastCheckProvider,
        updateProvider,
        UpdatePhase;
