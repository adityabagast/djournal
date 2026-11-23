/// Riwayat versi dari CHANGELOG.md yang dibawa di dalam app.
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.headline,
    required this.sections,
  });

  final String version;
  final DateTime date;

  /// Satu baris ringkas, mis. nama fitur pertama.
  final String headline;
  final List<ChangelogSection> sections;
}

class ChangelogSection {
  const ChangelogSection({required this.title, required this.lines});

  /// null = butir tanpa judul bagian.
  final String? title;
  final List<ChangelogLine> lines;
}

class ChangelogLine {
  const ChangelogLine(this.text, {this.depth = 0});

  final String text;

  /// Tingkat butir: 0 = utama, 1 = di bawahnya, dst.
  final int depth;
}

/// Bagian untuk pengembang, tidak ditampilkan ke user.
const _hiddenSections = {'di balik layar', 'teknis'};

final _header = RegExp(r'^## (\d+\.\d+\.\d+)\s+[—–-]\s+(\d{4}-\d{2}-\d{2})');
final _section = RegExp(r'^\*\*([^*]+)\*\*$');
final _bullet = RegExp(r'^(\s*)(?:[-*]|\d+\.)\s+(.*)$');
final _leadingBold = RegExp(r'^\*\*([^*]+)\*\*');

String _plain(String s) => s
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
    .replaceAll('**', '')
    .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1]!)
    .replaceAll('`', '')
    .trim();

/// Membaca versi yang sudah rilis (ada nomor dan tanggalnya), urut seperti di
/// file: terbaru dulu. "Belum dirilis" dan bagian teknis dilewati.
List<ChangelogEntry> parseChangelog(String markdown) {
  final entries = <ChangelogEntry>[];
  String? version;
  DateTime? date;
  String? intro, headline, title;
  var lines = <ChangelogLine>[];
  var sections = <ChangelogSection>[];

  void closeSection() {
    if (lines.isNotEmpty && !_hiddenSections.contains(title?.toLowerCase())) {
      sections.add(ChangelogSection(title: title, lines: lines));
    }
    lines = [];
    title = null;
  }

  void closeEntry() {
    closeSection();
    if (version != null && sections.isNotEmpty) {
      entries.add(
        ChangelogEntry(
          version: version!,
          date: date!,
          headline: intro ?? headline ?? '',
          sections: sections,
        ),
      );
    }
    version = date = intro = headline = null;
    sections = [];
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.startsWith('## ')) {
      closeEntry();
      final m = _header.firstMatch(line);
      if (m != null) {
        version = m[1];
        date = DateTime.parse(m[2]!);
      }
      continue;
    }
    if (version == null || line.isEmpty) continue;

    final sec = _section.firstMatch(line);
    if (sec != null) {
      closeSection();
      title = sec[1]!.trim();
      continue;
    }
    final b = _bullet.firstMatch(line);
    if (b != null) {
      final text = b[2]!;
      lines.add(ChangelogLine(_plain(text), depth: b[1]!.length ~/ 2));
      headline ??= _plain(_leadingBold.firstMatch(text)?[1] ?? text);
      continue;
    }
    // Paragraf pembuka sebelum butir pertama.
    if (lines.isEmpty && sections.isEmpty) {
      intro ??= _plain(line).replaceFirst(RegExp(r'\.$'), '');
    }
  }
  closeEntry();
  return entries;
}
