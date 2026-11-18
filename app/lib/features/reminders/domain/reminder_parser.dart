/// Mengenali rencana (tanggal/jam) di cerita jurnal berbahasa Indonesia,
/// sepenuhnya di perangkat. Murni Dart, tanpa dependensi Flutter.
library;

/// Kapan notifikasi muncul relatif terhadap acara.
/// - [atEvent]: saat acara (atau 07.00 hari-H untuk acara seharian)
/// - [hourBefore]: 1 jam sebelum (hanya kalau ada jam)
/// - [dayBefore]: 1 hari sebelum
enum ReminderLead {
  atEvent('at'),
  hourBefore('h1'),
  dayBefore('d1');

  const ReminderLead(this.code);
  final String code;

  static ReminderLead fromCode(String? code) => values.firstWhere(
    (l) => l.code == code,
    orElse: () => ReminderLead.atEvent,
  );
}

class ReminderSuggestion {
  const ReminderSuggestion({
    required this.title,
    required this.date,
    this.time,
    this.ambiguous = false,
    this.saidWeekday,
  });

  /// Tebakan judul dari kalimatnya; kosong kalau tidak ada kata yang tersisa.
  final String title;

  /// "YYYY-MM-DD".
  final String date;

  /// "HH:mm", atau null untuk acara seharian.
  final String? time;

  /// Jam disebut tanpa pagi/siang/sore/malam, jadi bisa AM atau PM.
  final bool ambiguous;

  /// Nama hari yang ditulis user (DateTime.weekday) kalau tidak cocok dengan
  /// tanggalnya; tanggal yang dipakai.
  final int? saidWeekday;
}

const _months = {
  'januari': 1, 'jan': 1, 'februari': 2, 'feb': 2, 'maret': 3, 'mar': 3,
  'april': 4, 'apr': 4, 'mei': 5, 'juni': 6, 'jun': 6, 'juli': 7, 'jul': 7,
  'agustus': 8, 'agu': 8, 'agt': 8, 'september': 9, 'sept': 9, 'sep': 9,
  'oktober': 10, 'okt': 10, 'november': 11, 'nopember': 11, 'nov': 11,
  'desember': 12, 'des': 12,
};

const _days = {
  'senin': 1, 'selasa': 2, 'rabu': 3, 'kamis': 4, 'jumat': 5, "jum'at": 5,
  'sabtu': 6, 'minggu': 7, 'ahad': 7,
};

const _stopWords = {
  'aku', 'saya', 'gue', 'gw', 'kita', 'kami', 'akan', 'mau', 'bakal', 'ada',
  'harus', 'perlu', 'ikut', 'hari', 'tanggal', 'tgl', 'nanti', 'yang', 'dan',
  'itu', 'ini', 'depan', 'lagi', 'juga', 'ya', 'nih', 'jadi', 'wib',
  'insyaallah', 'semoga',
};

final _monthAlt = (_months.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length)))
    .join('|');
const _dayAlt = "senin|selasa|rabu|kamis|jumat|jum'at|sabtu|minggu|ahad";
const _period = 'pagi|siang|sore|malam';

final _pastRe = RegExp(r'\b(kemarin|tadi|barusan)\b');
final _dateWordsRe = RegExp(
  '(?:\\b(?:tanggal|tgl)\\.?\\s*)?\\b(\\d{1,2})\\s+($_monthAlt)\\b\\.?'
  '(?:\\s+(\\d{4}))?',
);
final _dateNumRe = RegExp(r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b');
final _weekdayRe = RegExp(
  '\\b(hari\\s+)?($_dayAlt)\\b(?:\\s+(depan|ini|lalu))?',
);
final _relativeRe = RegExp(
  r'\b(besok lusa|lusa|besok|hari ini|malam ini|nanti (?:pagi|siang|sore|malam))\b',
);
final _timeWordRe = RegExp(
  '\\b(?:jam|pukul|pkl)\\.?\\s*(\\d{1,2})(?:[.:](\\d{2}))?'
  '(?:\\s*($_period))?',
);
final _timeNumRe = RegExp(
  '\\b([01]?\\d|2[0-3])[.:]([0-5]\\d)\\b(?:\\s*($_period))?',
);
final _periodRe = RegExp('\\b($_period)\\b');
final _planRe = RegExp(r'\b(akan|mau|bakal|nanti|depan|rencana|jadwal|harus)\b');
final _digitTailRe = RegExp(r'\d\s*$');
final _sentenceRe = RegExp(r'(?<=[.!?])\s+|\n+');
final _punctRe = RegExp(r'[.,!?;:()"]');
final _spaceRe = RegExp(r'\s+');

String _two(int n) => n.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Kalimat-kalimat di [text] yang menyebut rencana. Kunci = kalimatnya
/// sendiri, supaya pilihan user tidak bergeser saat bagian lain diedit.
Map<String, ReminderSuggestion> suggestReminders(String text, DateTime now) {
  final out = <String, ReminderSuggestion>{};
  for (final raw in text.split(_sentenceRe)) {
    final s = raw.trim();
    if (s.isEmpty || out.containsKey(s)) continue;
    final p = parseReminderSentence(s, now);
    if (p != null) out[s] = p;
  }
  return out;
}

/// Tebakan acara dari satu kalimat, atau null kalau bukan rencana ke depan.
ReminderSuggestion? parseReminderSentence(String s, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final low = s.toLowerCase();
  if (_pastRe.hasMatch(low)) return null;

  final spans = <(int, int)>[];
  void take(RegExpMatch m) => spans.add((m.start, m.end));

  DateTime? date;
  var explicit = false;

  var m = _dateWordsRe.firstMatch(low);
  if (m != null) {
    take(m);
    final d = int.parse(m.group(1)!);
    final mon = _months[m.group(2)]!;
    final y = m.group(3) == null ? today.year : int.parse(m.group(3)!);
    var cand = DateTime(y, mon, d);
    if (cand.day == d) {
      if (m.group(3) == null && cand.isBefore(today)) {
        cand = DateTime(y + 1, mon, d);
      }
      date = cand;
      explicit = true;
    }
  }
  if (date == null) {
    m = _dateNumRe.firstMatch(low);
    if (m != null) {
      final d = int.parse(m.group(1)!);
      final mon = int.parse(m.group(2)!);
      if (mon >= 1 && mon <= 12 && d >= 1 && d <= 31) {
        take(m);
        final yr = m.group(3);
        final y = yr == null
            ? today.year
            : (int.parse(yr) < 100 ? 2000 + int.parse(yr) : int.parse(yr));
        var cand = DateTime(y, mon, d);
        if (yr == null && cand.isBefore(today)) cand = DateTime(y + 1, mon, d);
        date = cand;
        explicit = true;
      }
    }
  }

  int? weekday;
  final w = _weekdayRe.firstMatch(low);
  // "Senin lalu", "minggu lalu": cerita yang sudah lewat.
  if (w != null && w.group(3) == 'lalu') return null;
  if (w != null) {
    final isWeekWord = w.group(2) == 'minggu' && w.group(1) == null;
    // "2 minggu" = durasi, bukan hari Minggu.
    final afterNumber =
        isWeekWord && _digitTailRe.hasMatch(low.substring(0, w.start));
    if (!afterNumber) {
      if (isWeekWord && w.group(3) != null) {
        // "minggu depan" = pekan depan; "minggu ini" tidak menunjuk tanggal.
        if (w.group(3) == 'depan' && date == null) {
          date = today.add(const Duration(days: 7));
          take(w);
        }
      } else {
        weekday = _days[w.group(2)];
        take(w);
      }
    }
  }

  int? saidWeekday;
  if (date != null && explicit && weekday != null && date.weekday != weekday) {
    saidWeekday = weekday;
  }

  var loose = false;
  if (date == null && weekday != null) {
    final diff = (weekday - today.weekday + 7) % 7;
    date = DateTime(today.year, today.month, today.day + (diff == 0 ? 7 : diff));
    loose = true;
  }
  if (date == null) {
    m = _relativeRe.firstMatch(low);
    if (m != null) {
      take(m);
      final word = m.group(1)!;
      if (word == 'besok') {
        date = DateTime(today.year, today.month, today.day + 1);
      } else if (word.contains('lusa')) {
        date = DateTime(today.year, today.month, today.day + 2);
      }
    }
  }

  String? time;
  var ambiguous = false;
  m = _timeWordRe.firstMatch(low) ?? _timeNumRe.firstMatch(low);
  if (m != null) {
    var h = int.parse(m.group(1)!);
    final mi = m.group(2) == null ? 0 : int.parse(m.group(2)!);
    if (h <= 23 && mi <= 59) {
      take(m);
      final per = m.group(3) ?? _periodRe.firstMatch(low)?.group(1);
      switch (per) {
        case 'pagi':
          if (h == 12) h = 0;
        case 'siang':
          if (h <= 6) h += 12;
        case 'sore':
          if (h < 12) h += 12;
        case 'malam':
          if (h == 12) {
            h = 0;
          } else if (h >= 5 && h < 12) {
            h += 12;
          }
        default:
          // "07.30" (nol di depan) sudah jelas format 24 jam.
          if (h >= 1 && h <= 11 && !m.group(1)!.startsWith('0')) {
            ambiguous = true;
            if (h <= 6) h += 12;
          }
      }
      time = '${_two(h)}:${_two(mi)}';
    }
  }

  // Nama hari saja ("Minggu pagi beres-beres") belum tentu rencana: butuh
  // jam atau kata rencana.
  if (loose && time == null && !_planRe.hasMatch(low)) return null;
  if (date == null && time != null) date = today;
  if (date == null || date.isBefore(today)) return null;

  // Jurnal sering bercerita soal hari ini ("bangun jam 5 pagi"): jam yang
  // sudah lewat bukan rencana.
  if (date == today && time != null) {
    final h = int.parse(time.substring(0, 2));
    final mi = int.parse(time.substring(3));
    final latest = ambiguous && h < 12 ? h + 12 : h;
    if (!DateTime(today.year, today.month, today.day, latest, mi)
        .isAfter(now)) {
      return null;
    }
  }

  var rest = s;
  spans.sort((a, b) => b.$1.compareTo(a.$1));
  for (final (start, end) in spans) {
    rest = '${rest.substring(0, start)} ${rest.substring(end)}';
  }
  final words = <String>[];
  for (final word in rest.replaceAll(_punctRe, ' ').split(_spaceRe)) {
    if (word.isEmpty) continue;
    final k = word.toLowerCase();
    if (k == 'di' || k == 'ke' || k == 'pada') {
      if (words.isNotEmpty) break;
      continue;
    }
    if (_stopWords.contains(k)) continue;
    words.add(word);
    if (words.length == 4) break;
  }
  var title = words.join(' ');
  if (title.isNotEmpty) title = title[0].toUpperCase() + title.substring(1);

  return ReminderSuggestion(
    title: title,
    date: _iso(date),
    time: time,
    ambiguous: ambiguous,
    saidWeekday: saidWeekday,
  );
}

/// Waktu notifikasi (lokal) untuk acara [date] ("YYYY-MM-DD") jam [time]
/// ("HH:mm" atau null = seharian, diingatkan 07.00).
DateTime reminderFireAt(String date, String? time, ReminderLead lead) {
  final p = date.split('-').map(int.parse).toList();
  final h = time == null ? 7 : int.parse(time.substring(0, 2));
  final mi = time == null ? 0 : int.parse(time.substring(3));
  return switch (lead) {
    ReminderLead.dayBefore => DateTime(p[0], p[1], p[2] - 1, h, mi),
    ReminderLead.hourBefore when time != null =>
      DateTime(p[0], p[1], p[2], h - 1, mi),
    _ => DateTime(p[0], p[1], p[2], h, mi),
  };
}

/// Selisih hari dari [today] ke [date] ("YYYY-MM-DD"); 0 = hari ini.
int reminderDaysLeft(String date, DateTime today) {
  final p = date.split('-').map(int.parse).toList();
  // UTC supaya pergantian jam musim panas tidak menggeser hitungan.
  return DateTime.utc(p[0], p[1], p[2])
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
}
