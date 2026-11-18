import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../domain/reminder_parser.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import 'reminder_format.dart';
import 'reminder_suggestions.dart';
import '../../../core/tokens.dart';

/// Kartu "Acara mendatang" di Hari Ini: pengingat yang dibuat dari jurnal.
/// Tidak tampil kalau belum ada acara.
class UpcomingEventsCard extends ConsumerWidget {
  const UpcomingEventsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingRemindersProvider).value ?? const [];
    if (events.isEmpty) return const SizedBox.shrink();

    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final notifier = ref.watch(reminderNotifierProvider);
    final denied =
        notifier.supported &&
        ref.watch(reminderPermissionProvider).value == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.remUpcoming,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpace.sm),
            for (final e in events)
              InkWell(
                key: ValueKey('event-${e.id}'),
                onTap: () => _DetailSheet.show(context, e),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Row(
                    children: [
                      const ReminderIconDot(Icons.event_outlined),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppFontSize.bodyLg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              reminderWhen(context, e.eventDate, e.eventTime),
                              style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      RelPill(reminderRel(context, e.eventDate)),
                    ],
                  ),
                ),
              ),
            if (denied) ...[
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.md,
                ),
                decoration: BoxDecoration(
                  color: c.warnSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  l.remDenied,
                  style: TextStyle(
                    fontSize: AppFontSize.meta,
                    height: 1.45,
                    color: c.onWarnSoft,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: () async {
                    try {
                      await notifier.requestPermission();
                    } catch (e) {
                      debugPrint('Izin notifikasi gagal: ${e.runtimeType}');
                    }
                    ref.invalidate(reminderPermissionProvider);
                  },
                  child: Text(l.remAllowButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends ConsumerWidget {
  const _DetailSheet(this.event);

  final Reminder event;

  static Future<void> show(BuildContext context, Reminder event) =>
      showReminderSheet<void>(context, _DetailSheet(event));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final notifier = ref.watch(reminderNotifierProvider);
    final denied =
        notifier.supported &&
        ref.watch(reminderPermissionProvider).value == false;
    final lead = ReminderLead.fromCode(event.lead);

    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          ReminderIconDot(icon),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppFontSize.meta, height: 1.5, color: c.muted),
            ),
          ),
        ],
      ),
    );

    return ReminderSheetBody(
      title: event.title,
      subtitle:
          '${reminderWhen(context, event.eventDate, event.eventTime)} · '
          '${reminderRel(context, event.eventDate)}',
      children: [
        row(
          Icons.notifications_none_rounded,
          denied
              ? l.remDenied
              : l.remLeadLine(reminderLeadName(l, lead, event.eventTime)),
        ),
        row(
          Icons.menu_book_outlined,
          l.remFrom(
            DateFormat(
              'd MMM',
              context.localeTag,
            ).format(event.createdAt.toLocal()),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(reminderServiceProvider).delete(event);
                  if (context.mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(foregroundColor: c.expense),
                child: Text(l.remDelete),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.remClose),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
