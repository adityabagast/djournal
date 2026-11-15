import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../domain/models/reminder_parser.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import 'reminder_format.dart';
import 'reminder_suggestions.dart';

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
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.remUpcoming,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final e in events)
              InkWell(
                key: ValueKey('event-${e.id}'),
                onTap: () => _DetailSheet.show(context, e),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const ReminderIconDot(Icons.event_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              reminderWhen(context, e.eventDate, e.eventTime),
                              style: TextStyle(fontSize: 12.5, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      RelPill(reminderRel(context, e.eventDate)),
                    ],
                  ),
                ),
              ),
            if (denied) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.warnSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  l.remDenied,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: c.onWarnSoft,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await notifier.requestPermission();
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ReminderIconDot(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: c.muted),
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
        const SizedBox(height: 6),
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
            const SizedBox(width: 10),
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
