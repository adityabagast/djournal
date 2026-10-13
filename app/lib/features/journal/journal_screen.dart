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
import '../search/search_screen.dart';
import 'entry_form_screen.dart';
import 'entry_rows.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  /// Tanggal yang dipilih di strip minggu (YYYY-MM-DD); null = semua entri.
  String? _selected;

  /// 0 = minggu ini, -1 = minggu lalu, dst.
  int _weekOffset = 0;

  void _toggleDay(String date) =>
      setState(() => _selected = _selected == date ? null : date);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entriesAsync = ref.watch(journalEntriesProvider);
    final snap = ref.watch(moneySnapshotProvider).value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1) + 7 * _weekOffset,
    );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        // Kelompokkan per tanggal (sudah terurut terbaru dulu), lalu urutkan
        // entri di dalam hari berdasarkan jam.
        final groups = <String, List<JournalEntry>>{};
        for (final e in entries) {
          if (_selected != null && e.entryDate != _selected) continue;
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
              trailing: Row(
                spacing: 8,
                children: [
                  const SearchButton(),
                  FilledButton.icon(
                    onPressed: () =>
                        EntryFormScreen.open(context, initialDate: _selected),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.write),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _WeekStrip(
              monday: monday,
              entries: entries,
              selected: _selected,
              onSelect: _toggleDay,
              onPrev: () => setState(() => _weekOffset--),
              onNext: _weekOffset < 0
                  ? () => setState(() => _weekOffset++)
                  : null,
            ),
            const SizedBox(height: 16),
            if (_selected != null)
              _FilterBar(
                date: _selected!,
                onClear: () => setState(() => _selected = null),
              ),
            if (entries.isEmpty)
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
              )
            else if (groups.isEmpty)
              MascotEmpty(
                pose: MascotPose.mencari,
                tint: MascotTint.sky,
                title: l.journalDayEmptyTitle,
                message: l.journalDayEmptyBody,
                size: 140,
                action: FilledButton(
                  onPressed: () =>
                      EntryFormScreen.open(context, initialDate: _selected),
                  child: Text(l.writeForThisDay),
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

/// Senin–Minggu dari [monday]; titik hijau = ada entri di hari itu.
/// Tap tanggal untuk memfilter, tap lagi untuk melepas filter.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.monday,
    required this.entries,
    required this.selected,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime monday;
  final List<JournalEntry> entries;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onPrev;

  /// null = sudah di minggu ini.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final withEntries = {for (final e in entries) e.entryDate};
    final dayName = DateFormat('E', context.localeTag);
    final range =
        '${DateFormat('d MMM', context.localeTag).format(monday)} – '
        '${DateFormat('d MMM y', context.localeTag).format(sunday)}';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.prevWeek,
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.muted,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.nextWeek,
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final day = DateTime(
                      monday.year,
                      monday.month,
                      monday.day + i,
                    );
                    final date = toLocalDate(day);
                    final isToday = day == today;
                    final isFuture = day.isAfter(today);
                    final isSelected = date == selected;
                    return SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(
                            dayName.format(day),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Material(
                            color: isSelected
                                ? context.colors.primary
                                : Colors.transparent,
                            shape: CircleBorder(
                              side: isToday && !isSelected
                                  ? BorderSide(
                                      color: context.colors.primary,
                                      width: 1.5,
                                    )
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              // Entri tidak bisa bertanggal di masa depan.
                              onTap: isFuture ? null : () => onSelect(date),
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? context.colors.onPrimary
                                          : isToday
                                          ? context.colors.primary
                                          : (isFuture
                                                ? context.colors.muted
                                                : context.colors.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: withEntries.contains(date)
                                  ? context.colors.primary
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
        ],
      ),
    );
  }
}

/// "Kamis, 9 Okt · Tampilkan semua" saat daftar difilter per tanggal.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.date, required this.onClear});

  final String date;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 18, color: context.colors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              dayLabel(context, date),
              style: TextStyle(fontSize: 13, color: context.colors.muted),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(context.l10n.showAllEntries),
          ),
        ],
      ),
    );
  }
}

/// Label tanggal + ringkasan "Mood baik · Rp 192.000" (sekali per tanggal).
class _DayHeader extends ConsumerWidget {
  const _DayHeader({
    required this.date,
    required this.entries,
    required this.snapshot,
  });

  final String date;
  final List<JournalEntry> entries;
  final MoneySnapshot? snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    final mood = dayMood(entries, date);
    final out = snapshot == null
        ? 0
        : MoneySnapshot.sumOf(snapshot!.onDate(date), 'expense');
    final summary = [
      if (mood != null) l.dayMoodSummary(moodLabel(l, mood).toLowerCase()),
      out > 0 ? rupiah(out, hide: hideAmounts) : l.noSpending,
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
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
