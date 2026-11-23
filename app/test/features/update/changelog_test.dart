import 'dart:io';

import 'package:djournal/features/update/domain/changelog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sample = '''
# Changelog

## Belum dirilis

**Baru**
- Belum boleh tampil

## 0.17.0 — 2026-11-20

**Baru**
- **Judul otomatis**: tampil di `Jurnal`, lihat [panduan](https://x.y)
- Widget:
  - **Ringkas** (2×2)
    1. *Bertingkat* tiga

**Perbaikan**
- Streak aman

**Di balik layar**
- Refactor

**Teknis**
- Schema v6

## 0.1.0 — 2026-10-09

Rilis pertama.

- Jurnal harian
''';

  test('hanya versi yang sudah rilis, urut seperti di file', () {
    final entries = parseChangelog(sample);
    expect(entries.map((e) => e.version), ['0.17.0', '0.1.0']);
    expect(entries.first.date, DateTime(2026, 11, 20));
  });

  test('bagian teknis disembunyikan, markdown dibuang', () {
    final e = parseChangelog(sample).first;
    expect(e.sections.map((s) => s.title), ['Baru', 'Perbaikan']);
    expect(e.sections.first.lines.map((l) => l.text), [
      'Judul otomatis: tampil di Jurnal, lihat panduan',
      'Widget:',
      'Ringkas (2×2)',
      'Bertingkat tiga',
    ]);
    expect(e.sections.first.lines.map((l) => l.depth), [0, 0, 1, 2]);
  });

  test('judul ringkas dari kata tebal pertama atau paragraf pembuka', () {
    final entries = parseChangelog(sample);
    expect(entries.first.headline, 'Judul otomatis');
    expect(entries.last.headline, 'Rilis pertama');
    expect(entries.last.sections.single.title, isNull);
  });

  test('judul ringkas tanpa kata tebal memakai baris pertama', () {
    final e = parseChangelog(
      '## 1.0.0 — 2026-01-02\r\n\r\n**Perbaikan**\r\n- Lebih **cepat** dibuka\r\n',
    ).single;
    expect(e.headline, 'Lebih cepat dibuka');
  });

  group('CHANGELOG asli', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');

    test('salinan di assets sama dengan CHANGELOG.md di root', () {
      expect(
        read('assets/changelog.md') == read('../CHANGELOG.md'),
        isTrue,
        reason: 'Salin CHANGELOG.md ke app/assets/changelog.md',
      );
    });

    test('semua versi terbaca dan punya isi', () {
      final text = read('assets/changelog.md');
      final entries = parseChangelog(text);
      final headers = RegExp(r'^## \d', multiLine: true).allMatches(text);
      expect(entries, hasLength(headers.length));
      for (final e in entries) {
        expect(e.headline, isNotEmpty, reason: e.version);
        expect(e.sections, isNotEmpty, reason: e.version);
        for (final s in e.sections) {
          expect(s.lines, isNotEmpty, reason: '${e.version} ${s.title}');
          for (final l in s.lines) {
            expect(l.text, isNot(contains('**')), reason: e.version);
            expect(l.text, isNot(contains('`')), reason: e.version);
          }
        }
      }
    });
  });
}
