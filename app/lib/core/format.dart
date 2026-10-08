import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// "Rp 1.250.000". Selalu tanpa tanda; tanda +/− ditambahkan pemanggil.
String rupiah(int amount) => 'Rp ${thousands(amount.abs())}';

String thousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Tanggal lokal "YYYY-MM-DD", kunci penghubung jurnal ↔ transaksi.
String toLocalDate(DateTime dt) {
  final l = dt.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

/// "YYYY-MM"
String toMonthKey(DateTime dt) => toLocalDate(dt).substring(0, 7);

DateTime parseLocalDate(String ymd) {
  final p = ymd.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String hhmm(DateTime dt) => DateFormat.Hm().format(dt.toLocal());

/// Input nominal: hanya angka, otomatis diberi titik ribuan saat mengetik.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    // Batasi 15 digit supaya tetap aman di int 64-bit.
    final trimmed = digits.length > 15 ? digits.substring(0, 15) : digits;
    final text = thousands(int.parse(trimmed));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
