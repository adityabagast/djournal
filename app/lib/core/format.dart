import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const maskedRupiah = 'Rp •••••';

/// "Rp 1.250.000" atau "Rp •••••" saat [hide] = true.
/// Selalu tanpa tanda; tanda +/− ditambahkan pemanggil.
String rupiah(int amount, {bool hide = false}) =>
    hide ? maskedRupiah : 'Rp ${thousands(amount.abs())}';

/// Format nominal dengan tanda minus/plus atau masking:
/// "Rp 1.250.000", "−Rp 25.000", "+Rp 50.000", atau "Rp •••••" saat [hide] = true.
String signedRupiah(int amount, {bool hide = false, bool explicitPlus = false}) {
  if (hide) return maskedRupiah;
  final sign = amount < 0 ? '−' : (explicitPlus && amount > 0 ? '+' : '');
  return '$sign${rupiah(amount)}';
}

String thousands(int n) {
  if (n < 0) return '-${thousands(-n)}';
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
/// [allowNegative] mengizinkan tanda minus di depan (mis. saldo dompet).
class ThousandsInputFormatter extends TextInputFormatter {
  ThousandsInputFormatter({this.allowNegative = false});

  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final negative = allowNegative && newValue.text.trimLeft().startsWith('-');
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return negative
          ? const TextEditingValue(
              text: '-',
              selection: TextSelection.collapsed(offset: 1),
            )
          : const TextEditingValue();
    }
    // Batasi 15 digit supaya tetap aman di int 64-bit.
    final trimmed = digits.length > 15 ? digits.substring(0, 15) : digits;
    final text = '${negative ? '-' : ''}${thousands(int.parse(trimmed))}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Kebalikan dari [thousands]; tanda minus di depan dipertahankan.
int parseAmount(String text) {
  final value = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return text.trimLeft().startsWith('-') ? -value : value;
}
