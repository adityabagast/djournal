import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../domain/models/reminder_parser.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import 'reminder_format.dart';

/// Tebakan acara dari satu kalimat, setelah digabung dengan koreksi user.
class ReminderDraft {
  const ReminderDraft({
    required this.key,
    required this.title,
    required this.date,
    required this.time,
    required this.lead,
    this.ambiguous = false,
    this.saidWeekday,
    this.baseTime,
  });

  /// Kalimat asalnya.
  final String key;
  final String title;
  final String date;
  final String? time;
  final ReminderLead lead;
  final bool ambiguous;
  final int? saidWeekday;

  /// Jam tebakan awal, untuk pilihan pagi/sore saat [ambiguous].
  final String? baseTime;
}

class _Override {
  const _Override({
    this.title,
    this.date,
    this.time,
    this.timeSet = false,
    this.lead,
  });

  final String? title;
  final String? date;
  final String? time;

  /// True kalau user sudah menentukan jam (termasuk "seharian" = null).
  final bool timeSet;
  final ReminderLead? lead;
}

/// Pilihan user (terima, abaikan, koreksi) selama form jurnal terbuka.
class ReminderSuggestionController {
  final _accepted = <String>{};
  final _dismissed = <String>{};
  final _overrides = <String, _Override>{};

  /// Tebakan yang masih ditampilkan. [existing] = pengingat yang sudah
  /// dibuat dari entri ini, supaya tidak ditawarkan dua kali.
  List<ReminderDraft> drafts(
    String text,
    DateTime now, {
    List<Reminder> existing = const [],
  }) {
    final out = <ReminderDraft>[];
    suggestReminders(text, now).forEach((key, base) {
      if (_dismissed.contains(key)) return;
      if (existing.any(
        (r) => r.eventDate == base.date && r.eventTime == base.time,
      )) {
        return;
      }
      final o = _overrides[key] ?? const _Override();
      final time = o.timeSet ? o.time : base.time;
      out.add(
        ReminderDraft(
          key: key,
          title: o.title ?? base.title,
          date: o.date ?? base.date,
          time: time,
          lead:
              o.lead ??
              (time != null ? ReminderLead.hourBefore : ReminderLead.atEvent),
          ambiguous: base.ambiguous && !o.timeSet,
          saidWeekday: o.date == null ? base.saidWeekday : null,
          baseTime: base.time,
        ),
      );
    });
    return out;
  }

  bool isAccepted(String key) => _accepted.contains(key);

  /// Yang disimpan sebagai pengingat saat entri disimpan.
  List<ReminderDraft> acceptedDrafts(
    String text,
    DateTime now, {
    List<Reminder> existing = const [],
  }) => drafts(
    text,
    now,
    existing: existing,
  ).where((d) => _accepted.contains(d.key)).toList();
}

/// Kartu-kartu "Pengingat dari ceritamu" di form jurnal.
class ReminderSuggestions extends ConsumerStatefulWidget {
  const ReminderSuggestions({
    super.key,
    required this.controller,
    required this.text,
    this.existing = const [],
  });

  final ReminderSuggestionController controller;
  final String text;
  final List<Reminder> existing;

  @override
  ConsumerState<ReminderSuggestions> createState() =>
      _ReminderSuggestionsState();
}

class _ReminderSuggestionsState extends ConsumerState<ReminderSuggestions> {
  static const _askedKey = 'reminder_perm_asked';

  ReminderSuggestionController get _c => widget.controller;

  /// Izin notifikasi hanya ditanya sekali; pengingat tetap disimpan apa pun
  /// jawabannya.
  Future<void> _accept(String key) async {
    final notifier = ref.read(reminderNotifierProvider);
    final settings = ref.read(settingsRepositoryProvider);
    if (notifier.supported && !await notifier.isAllowed()) {
      final asked = await settings.watch(_askedKey).first;
      if (asked == null && mounted) {
        final allow = await _PermissionSheet.show(context);
        await settings.set(_askedKey, '1');
        if (allow == true) {
          await notifier.requestPermission();
          ref.invalidate(reminderPermissionProvider);
        }
      }
    }
    if (mounted) setState(() => _c._accepted.add(key));
  }

  Future<void> _edit(ReminderDraft d) async {
    final result = await _EditSheet.show(context, d);
    if (result == null || !mounted) return;
    _c._overrides[d.key] = result;
    await _accept(d.key);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final drafts = _c.drafts(
      widget.text,
      DateTime.now(),
      existing: widget.existing,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.remSection,
          style: t.labelSmall?.copyWith(
            color: c.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        if (drafts.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const ReminderIconDot(Icons.notifications_none_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.remNone,
                    style: t.bodySmall?.copyWith(color: c.muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        for (final d in drafts) ...[
          _card(context, d),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: c.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.remPrivacy,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(BuildContext context, ReminderDraft d) {
    final l = context.l10n;
    final c = context.colors;
    final accepted = _c.isAccepted(d.key);
    final title = d.title.isEmpty ? l.remDefaultTitle : d.title;

    return AppCard(
      key: ValueKey('rem-${d.key}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ReminderIconDot(Icons.event_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accepted ? l.remWillRemind : l.remDetected,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      reminderWhen(context, d.date, d.time),
                      style: TextStyle(fontSize: 13, color: c.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RelPill(reminderRel(context, d.date)),
            ],
          ),
          if (d.ambiguous && d.baseTime != null) ...[
            const SizedBox(height: 10),
            Text(
              l.remAmbiguous,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 6),
            _amPm(context, d),
          ],
          if (d.saidWeekday != null) ...[
            const SizedBox(height: 10),
            _mismatchNote(context, d),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (accepted)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    l.remActive(reminderLeadName(l, d.lead, d.time)),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.income,
                    ),
                  ),
                )
              else
                FilledButton(
                  onPressed: () => _accept(d.key),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                  ),
                  child: Text(l.remAccept),
                ),
              TextButton(onPressed: () => _edit(d), child: Text(l.remEdit)),
              if (accepted)
                TextButton(
                  onPressed: () => setState(() => _c._accepted.remove(d.key)),
                  child: Text(l.cancel),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _c._dismissed.add(d.key)),
                  child: Text(l.remDismiss),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amPm(BuildContext context, ReminderDraft d) {
    final h = int.parse(d.baseTime!.substring(0, 2)) % 12;
    final mm = d.baseTime!.substring(3);
    String two(int n) => n.toString().padLeft(2, '0');
    final am = '${two(h)}:$mm';
    final pm = '${two(h + 12)}:$mm';
    void pick(String time) => setState(() {
      final o = _c._overrides[d.key] ?? const _Override();
      _c._overrides[d.key] = _Override(
        title: o.title,
        date: o.date,
        time: time,
        timeSet: true,
        lead: o.lead,
      );
    });
    return Row(
      children: [
        for (final time in [am, pm]) ...[
          if (time == pm) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => pick(time),
              child: Text(reminderTime(context, time)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _mismatchNote(BuildContext context, ReminderDraft d) {
    final c = context.colors;
    final tag = context.localeTag;
    final date = parseLocalDate(d.date);
    // 5 Jan 2026 = Senin; dipakai hanya untuk nama hari.
    String dayName(int weekday) =>
        DateFormat.EEEE(tag).format(DateTime(2026, 1, 4 + weekday));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: c.onWarnSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.remMismatch(
                DateFormat('d MMM y', tag).format(date),
                dayName(date.weekday),
                dayName(d.saidWeekday!),
              ),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: c.onWarnSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderIconDot extends StatelessWidget {
  const ReminderIconDot(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 18, color: context.colors.onPrimarySoft),
  );
}

/// Pil kecil "Besok" / "6 hari lagi".
class RelPill extends StatelessWidget {
  const RelPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: context.colors.onPrimarySoft,
      ),
    ),
  );
}

Future<T?> showReminderSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => child,
    );

class ReminderSheetBody extends StatelessWidget {
  const ReminderSheetBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet();

  /// true = user memilih Izinkan.
  static Future<bool?> show(BuildContext context) =>
      showReminderSheet<bool>(context, const _PermissionSheet());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ReminderSheetBody(
      title: l.remPermTitle,
      subtitle: l.remPermBody,
      children: [
        Row(
          children: [
            const ReminderIconDot(Icons.notifications_none_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.remPermHint,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: context.colors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.remPermLater),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.remPermAllow),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet(this.draft);

  final ReminderDraft draft;

  static Future<_Override?> show(BuildContext context, ReminderDraft draft) =>
      showReminderSheet<_Override>(context, _EditSheet(draft));

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _title = TextEditingController(text: widget.draft.title);
  late String _date = widget.draft.date;
  late String? _time = widget.draft.time;
  late ReminderLead _lead = widget.draft.lead;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parseLocalDate(_date),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) setState(() => _date = toLocalDate(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(
              hour: int.parse(_time!.substring(0, 2)),
              minute: int.parse(_time!.substring(3)),
            ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(
      () => _time =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final lead = effectiveLead(_lead, _time);
    final leads = [
      ReminderLead.atEvent,
      if (_time != null) ReminderLead.hourBefore,
      ReminderLead.dayBefore,
    ];

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
    );

    String cap(String s) => s[0].toUpperCase() + s.substring(1);

    return ReminderSheetBody(
      title: l.remEditTitle,
      subtitle: l.remEditSub,
      children: [
        label(l.remFieldTitle),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label(l.remFieldDate),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(reminderDate(context, _date)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label(l.remFieldTime),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: Text(
                      _time == null
                          ? l.remAllDay
                          : reminderTime(context, _time!),
                    ),
                  ),
                  if (_time != null)
                    TextButton(
                      onPressed: () => setState(() => _time = null),
                      child: Text(l.remAllDay),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        label(l.remFieldLead),
        SegmentedButton<ReminderLead>(
          showSelectedIcon: false,
          segments: [
            for (final v in leads)
              ButtonSegment(
                value: v,
                label: Text(
                  cap(reminderLeadName(l, v, _time, short: true)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
          selected: {lead},
          onSelectionChanged: (s) => setState(() => _lead = s.first),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _Override(
                    title: _title.text.trim(),
                    date: _date,
                    time: _time,
                    timeSet: true,
                    lead: lead,
                  ),
                ),
                child: Text(l.remSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
