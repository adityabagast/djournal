/// Judul dan cuplikan yang ditampilkan untuk satu entri jurnal.
///
/// Kalau user tidak menulis judul, kalimat pertama isi dipakai sebagai judul
/// dan [preview] berisi sisa isi supaya kalimat itu tidak tampil dua kali.
class EntryHeadline {
  const EntryHeadline({this.title, this.preview, this.hasOwnTitle = false});

  /// `null` kalau judul dan isi kosong; UI memakai label cadangan.
  final String? title;

  /// Isi di bawah judul; `null` kalau tidak ada.
  final String? preview;

  /// `true` kalau [title] ditulis user sendiri (bukan diambil dari isi).
  final bool hasOwnTitle;
}

/// Panjang maksimum judul yang diambil dari isi (sebelum elipsis).
const entryTitleMaxLength = 60;

// Akhir kalimat: . ! ? … yang diikuti spasi/akhir teks, atau baris baru.
final _sentenceEnd = RegExp(r'[.!?…](?=\s|$)|\n');

EntryHeadline entryHeadline({
  String? title,
  String? body,
  int maxLength = entryTitleMaxLength,
}) {
  final ownTitle = title?.trim() ?? '';
  final text = body?.trim() ?? '';
  if (ownTitle.isNotEmpty) {
    return EntryHeadline(
      title: ownTitle,
      preview: text.isEmpty ? null : text,
      hasOwnTitle: true,
    );
  }
  if (text.isEmpty) return const EntryHeadline();

  final end = _sentenceEnd.firstMatch(text);
  var first = end == null ? text : text.substring(0, end.end).trim();
  var rest = end == null ? '' : text.substring(end.end).trim();

  if (first.length > maxLength) {
    final space = first.substring(0, maxLength).lastIndexOf(' ');
    var at = space > maxLength ~/ 2 ? space : maxLength;
    // Jangan membelah pasangan surrogate (emoji).
    final unit = first.codeUnitAt(at - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) at--;
    rest = '${first.substring(at).trim()} $rest'.trim();
    first = '${first.substring(0, at).trim()}…';
  }
  return EntryHeadline(title: first, preview: rest.isEmpty ? null : rest);
}
