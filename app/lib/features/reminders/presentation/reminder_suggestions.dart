import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../domain/reminder_parser.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/note_bar.dart';
import 'reminder_format.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

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
    this.dismissed = false,
    this.title,
    this.date,
    this.time,
    this.timeSet = false,
    this.lead,
  });

  /// User membatalkan pengingat ini dari lembar ubah.
  final bool dismissed;
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

/// Izin notifikasi hanya ditanya sekali; pengingat tetap diterima apa pun
/// jawabannya.
Future<void> _acceptReminder(
  BuildContext context,
  WidgetRef ref,
  ReminderSuggestionController controller,
  String key,
) async {
  const askedKey = 'reminder_perm_asked';
  final notifier = ref.read(reminderNotifierProvider);
  final settings = ref.read(settingsRepositoryProvider);
  try {
    if (notifier.supported && !await notifier.isAllowed()) {
      final asked = await settings.watch(askedKey).first;
      if (asked == null && context.mounted) {
        final allow = await _PermissionSheet.show(context);
        await settings.set(askedKey, '1');
        if (allow == true) {
          await notifier.requestPermission();
          ref.invalidate(reminderPermissionProvider);
        }
      }
    }
  } catch (e) {
    // Notifikasi gagal tidak boleh menghalangi pengingat; acara tetap
    // tampil di Hari Ini.
    debugPrint('Izin notifikasi gagal: ${e.runtimeType}');
  } finally {
    controller._accepted.add(key);
  }
}

Future<void> _editReminder(
  BuildContext context,
  WidgetRef ref,
  ReminderSuggestionController controller,
  ReminderDraft d,
) async {
  final result = await _EditSheet.show(
    context,
    d,
    accepted: controller.isAccepted(d.key),
  );
  if (result == null) return;
  if (result.dismissed) {
    controller._accepted.remove(d.key);
    controller._dismissed.add(d.key);
    return;
  }
  controller._overrides[d.key] = result;
  if (context.mounted) await _acceptReminder(context, ref, controller, d.key);
}

/// Bilah di atas alat catatan: menawarkan satu acara dari cerita. Kosong
/// kalau tidak ada acara yang menunggu jawaban.
class ReminderBar extends ConsumerWidget {
  const ReminderBar({
    super.key,
    required this.controller,
    required this.text,
    required this.onChanged,
    this.existing = const [],
  });

  final ReminderSuggestionController controller;
  final String text;
  final List<Reminder> existing;

  /// Dipanggil setelah user menjawab, supaya form ikut dibangun ulang.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final waiting = controller
        .drafts(text, DateTime.now(), existing: existing)
        .where((d) => !controller.isAccepted(d.key))
        .toList();
    if (waiting.isEmpty) return const SizedBox.shrink();
    final d = waiting.first;
    final ask = d.ambiguous && d.baseTime != null;
    final when = [
      reminderRel(context, d.date),
      if (ask)
        l.remAmbiguous
      else
        d.time == null ? l.remAllDay : reminderTime(context, d.time!),
      if (waiting.length > 1) l.moreCount(waiting.length - 1),
    ].join(' · ');

    return NoteBar(
      background: c.warnSoft,
      foreground: c.onWarnSoft,
      title: d.title.isEmpty ? l.remDefaultTitle : d.title,
      subtitle: when,
      note: d.saidWeekday == null ? null : _mismatch(context, d),
      onTap: () async {
        await _editReminder(context, ref, controller, d);
        onChanged();
      },
      dismissLabel: l.remDismiss,
      onDismiss: () {
        controller._dismissed.add(d.key);
        onChanged();
      },
      actions: [
        if (ask)
          for (final time in _amPm(d.baseTime!))
            FilledButton(
              onPressed: () {
                final o = controller._overrides[d.key] ?? const _Override();
                controller._overrides[d.key] = _Override(
                  title: o.title,
                  date: o.date,
                  time: time,
                  timeSet: true,
                  lead: o.lead,
                );
                onChanged();
              },
              child: Text(reminderTime(context, time)),
            )
        else
          FilledButton(
            onPressed: () async {
              await _acceptReminder(context, ref, controller, d.key);
              onChanged();
            },
            child: Text(l.remAccept),
          ),
      ],
    );
  }

  static List<String> _amPm(String baseTime) {
    final h = int.parse(baseTime.substring(0, 2)) % 12;
    final mm = baseTime.substring(3);
    String two(int n) => n.toString().padLeft(2, '0');
    return ['${two(h)}:$mm', '${two(h + 12)}:$mm'];
  }

  static String _mismatch(BuildContext context, ReminderDraft d) {
    final tag = context.localeTag;
    final date = parseLocalDate(d.date);
    // 5 Jan 2026 = Senin; dipakai hanya untuk nama hari.
    String dayName(int weekday) =>
        DateFormat.EEEE(tag).format(DateTime(2026, 1, 4 + weekday));
    return context.l10n.remMismatch(
      DateFormat('d MMM y', tag).format(date),
      dayName(date.weekday),
      dayName(d.saidWeekday!),
    );
  }
}

/// Pengingat dari catatan ini: yang baru diterima (bisa diubah) dan yang
/// sudah tersimpan.
class NoteReminders extends ConsumerWidget {
  const NoteReminders({
    super.key,
    required this.controller,
    required this.text,
    required this.onChanged,
    this.existing = const [],
  });

  final ReminderSuggestionController controller;
  final String text;
  final List<Reminder> existing;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accepted = controller.acceptedDrafts(
      text,
      DateTime.now(),
      existing: existing,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in accepted)
          _NoteReminderRow(
            title: d.title.isEmpty ? l.remDefaultTitle : d.title,
            when: reminderWhen(context, d.date, d.time),
            status: l.remActive(reminderLeadName(l, d.lead, d.time)),
            onTap: () async {
              await _editReminder(context, ref, controller, d);
              onChanged();
            },
          ),
        for (final r in existing)
          _NoteReminderRow(
            title: r.title,
            when: reminderWhen(context, r.eventDate, r.eventTime),
            status: l.remActive(
              reminderLeadName(l, ReminderLead.fromCode(r.lead), r.eventTime),
            ),
          ),
      ],
    );
  }
}

class _NoteReminderRow extends StatelessWidget {
  const _NoteReminderRow({
    required this.title,
    required this.when,
    required this.status,
    this.onTap,
  });

  final String title;
  final String when;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Material(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: c.onWarnSoft,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w600,
                          color: c.onWarnSoft,
                        ),
                      ),
                      Text(
                        when,
                        style: TextStyle(
                          fontSize: AppFontSize.meta,
                          color: c.onWarnSoft,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: AppFontSize.meta,
                          color: c.onWarnSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: AppSpace.xxs),
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: AppFontSize.caption,
        fontWeight: FontWeight.w600,
        color: context.colors.onPrimarySoft,
      ),
    ),
  );
}

Future<T?> showReminderSheet<T>(BuildContext context, Widget child) =>
    showAppSheet<T>(
      context: context,
      isScrollControlled: true,
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
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            subtitle,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: AppSpace.lg),
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
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                l.remPermHint,
                style: TextStyle(
                  fontSize: AppFontSize.meta,
                  height: 1.5,
                  color: context.colors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.remPermLater),
              ),
            ),
            const SizedBox(width: AppSpace.md),
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
  const _EditSheet(this.draft, {required this.accepted});

  final ReminderDraft draft;

  /// Sudah diterima: tombol kiri membatalkan pengingatnya.
  final bool accepted;

  static Future<_Override?> show(
    BuildContext context,
    ReminderDraft draft, {
    required bool accepted,
  }) => showReminderSheet<_Override>(
    context,
    _EditSheet(draft, accepted: accepted),
  );

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
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSize.body,
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
        const SizedBox(height: AppSpace.lg),
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
            const SizedBox(width: AppSpace.md),
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
        const SizedBox(height: AppSpace.lg),
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
                  style: const TextStyle(fontSize: AppFontSize.meta),
                ),
              ),
          ],
          selected: {lead},
          onSelectionChanged: (s) => setState(() => _lead = s.first),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: c.muted),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                l.remPrivacy,
                style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.accepted ? const _Override(dismissed: true) : null,
                ),
                child: Text(widget.accepted ? l.remDismiss : l.cancel),
              ),
            ),
            const SizedBox(width: AppSpace.md),
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
