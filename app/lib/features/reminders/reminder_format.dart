import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../domain/models/reminder_parser.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/common.dart';

/// "13.00" (id) atau "13:00" (en).
String reminderTime(BuildContext context, String time) =>
    context.localeTag.startsWith('id') ? time.replaceAll(':', '.') : time;

/// "Sab, 21 Nov"; tahun ditambahkan kalau bukan tahun ini.
String reminderDate(BuildContext context, String date) {
  final d = parseLocalDate(date);
  final pattern = d.year == DateTime.now().year ? 'EEE, d MMM' : 'EEE, d MMM y';
  return DateFormat(pattern, context.localeTag).format(d);
}

/// "Sab, 21 Nov · 13.00" atau "Sab, 21 Nov · Sepanjang hari".
String reminderWhen(BuildContext context, String date, String? time) =>
    '${reminderDate(context, date)} · '
    '${time == null ? context.l10n.remAllDay : reminderTime(context, time)}';

/// "Hari ini", "Besok", atau "6 hari lagi".
String reminderRel(BuildContext context, String date) {
  final l = context.l10n;
  final n = reminderDaysLeft(date, DateTime.now());
  return n <= 0 ? l.today : (n == 1 ? l.remTomorrow : l.remDaysLeft(n));
}

/// Acara seharian tidak punya "1 jam sebelum": dianggap pagi hari-H.
ReminderLead effectiveLead(ReminderLead lead, String? time) =>
    time == null && lead == ReminderLead.hourBefore
    ? ReminderLead.atEvent
    : lead;

String reminderLeadName(
  AppLocalizations l,
  ReminderLead lead,
  String? time, {
  bool short = false,
}) => switch (effectiveLead(lead, time)) {
  ReminderLead.dayBefore => l.remLeadDay,
  ReminderLead.hourBefore => l.remLeadHour,
  ReminderLead.atEvent =>
    time != null
        ? l.remLeadAt
        : (short ? l.remLeadMorningShort : l.remLeadMorning),
};

/// Judul dan isi notifikasi: ("Workshop menulis · 13.00",
/// "1 jam lagi · Sab, 21 Nov").
(String, String) reminderNotifTexts(
  BuildContext context, {
  required String title,
  required String date,
  required String? time,
  required ReminderLead lead,
}) {
  final l = context.l10n;
  final rel = switch (effectiveLead(lead, time)) {
    ReminderLead.dayBefore => l.remTomorrow,
    ReminderLead.hourBefore => l.remNotifHour,
    ReminderLead.atEvent => time != null ? l.remNotifNow : l.today,
  };
  return (
    time == null ? title : '$title · ${reminderTime(context, time)}',
    '$rel · ${reminderDate(context, date)}',
  );
}
