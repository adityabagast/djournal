import 'dart:math';

import 'package:djournal/features/backup/data/backup_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Teks acak: sulit dikompres, jadi pasti terpotong ke beberapa sel.
  String bigJson() {
    final r = Random(1);
    final s = String.fromCharCodes(
      List.generate(200000, (_) => 97 + r.nextInt(26)),
    );
    return '{"a":"$s"}';
  }

  test('bolak-balik: kecil, emoji, baris baru, dan besar', () {
    for (final json in ['{}', '{"t":"kopi ☕😺\\n  dua"}\n  ', bigJson()]) {
      expect(decodeBackupPayload(encodeBackupPayload(json)), json);
    }
  });

  test('tidak ada sel yang melewati batas Excel 32.767 karakter', () {
    final cells = encodeBackupPayload(bigJson());
    expect(cells.length, greaterThan(3));
    expect(cells.every((c) => c.length <= 32767), isTrue);
  });

  test('potongan tidak bisa terbaca sebagai angka atau rumus', () {
    for (final c in encodeBackupPayload(bigJson()).skip(1)) {
      expect(c, startsWith('z'));
    }
  });

  test('format lama (JSON utuh di satu sel) tetap terbaca', () {
    expect(decodeBackupPayload(['{"format":"djournal-backup"}']),
        '{"format":"djournal-backup"}');
  });

  test('kosong, asing, terpotong, atau rusak: null, bukan error', () {
    final ok = encodeBackupPayload(bigJson());
    expect(decodeBackupPayload([]), isNull);
    expect(decodeBackupPayload(['halo']), isNull);
    expect(decodeBackupPayload([ok.first]), isNull);
    expect(decodeBackupPayload(ok.sublist(0, ok.length - 1)), isNull);
    expect(decodeBackupPayload([ok.first, 'z!!!']), isNull);
    expect(decodeBackupPayload([ok[0], ok[2], ok[1], ...ok.skip(3)]), isNull);
  });
}
