import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/journal_repository.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../../ui/mood.dart';
import 'entry_form_screen.dart';
import 'entry_rows.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final entriesAsync = ref.watch(journalEntriesProvider);
    final snap = ref.watch(moneySnapshotProvider).value;
    final now = DateTime.now();

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        // Kelompokkan per tanggal (sudah terurut terbaru dulu), lalu urutkan
        // entri di dalam hari berdasarkan jam.
        final groups = <String, List<JournalEntry>>{};
        for (final e in entries) {
          groups.putIfAbsent(e.entryDate, () => []).add(e);
        }
        for (final list in groups.values) {
          list.sort((a, b) => entrySortKey(a).compareTo(entrySortKey(b)));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 124),
          children: [
            ScreenHeader(
              overline: DateFormat('MMMM y', context.localeTag).format(now),
              title: l.navJournal,
              trailing: FilledButton.icon(
                onPressed: () => EntryFormScreen.open(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.write),
              ),
            ),
            const SizedBox(height: 16),
            _WeekStrip(entries: entries),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              MascotEmpty(
                pose: MascotPose.menulis,
                tint: MascotTint.peach,
                title: l.mascotJournalEmptyTitle,
                message: l.mascotJournalEmptyBody,
                size: 180,
                action: FilledButton(
                  onPressed: () => EntryFormScreen.open(context),
                  child: Text(l.mascotWriteEntry),
                ),
              ),
            for (final MapEntry(key: date, value: items) in groups.entries) ...[
              _DayHeader(date: date, entries: entries, snapshot: snap),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      EntryListRow(
                        entry: items[i],
                        showDivider: i < items.length - 1,
                        onTap: () =>
                            EntryFormScreen.open(context, existing: items[i]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

/// Senin–Minggu minggu ini; titik hijau = ada entri di hari itu.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final withEntries = {for (final e in entries) e.entryDate};
    final dayName = DateFormat('E', context.localeTag);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            Builder(
              builder: (context) {
                final day = monday.add(Duration(days: i));
                final isToday = day == today;
                final isFuture = day.isAfter(today);
                return SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Text(
                        dayName.format(day),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? AppColors.primary : null,
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? Colors.white
                                : (isFuture ? AppColors.muted : AppColors.ink),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: withEntries.contains(toLocalDate(day))
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Label tanggal + ringkasan "Mood baik · Rp 192.000" (sekali per tanggal).
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.entries,
    required this.snapshot,
  });

  final String date;
  final List<JournalEntry> entries;
  final MoneySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mood = dayMood(entries, date);
    final out = snapshot == null
        ? 0
        : MoneySnapshot.sumOf(snapshot!.onDate(date), 'expense');
    final summary = [
      if (mood != null) l.dayMoodSummary(moodLabel(l, mood).toLowerCase()),
      out > 0 ? rupiah(out) : l.noSpending,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              dayLabel(context, date),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            summary,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
