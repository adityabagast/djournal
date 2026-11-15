import 'package:djournal/domain/models/reminder_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Minggu, 15 Nov 2026, 09:00 (sama dengan prototipe).
  final now = DateTime(2026, 11, 15, 9);
  ReminderSuggestion? p(String s) => parseReminderSentence(s, now);

  test('tanggal lengkap + jam siang', () {
    final r = p(
      'Aku akan ikut workshop menulis pada hari Sabtu tanggal 21 November 2026 jam 1 siang.',
    )!;
    expect(r.title, 'Workshop menulis');
    expect(r.date, '2026-11-21');
    expect(r.time, '13:00');
    expect(r.ambiguous, isFalse);
    expect(r.saidWeekday, isNull);
  });

  test('besok jam 9 pagi', () {
    final r = p('Besok jam 9 pagi servis motor.')!;
    expect(r.title, 'Servis motor');
    expect(r.date, '2026-11-16');
    expect(r.time, '09:00');
  });

  test('nama hari + jam tanpa keterangan = ambigu, hari berikutnya', () {
    final r = p('Jumat jam 7 makan malam sama ibu.')!;
    expect(r.date, '2026-11-20');
    expect(r.time, '19:00'); // "malam" di kalimat
    expect(r.ambiguous, isFalse);

    final a = p('Jumat jam 7 ketemu Budi.')!;
    expect(a.time, '07:00');
    expect(a.ambiguous, isTrue);

    final b = p('Rabu jam 3 rapat.')!;
    expect(b.time, '15:00'); // 1–6 ditebak sore dulu
    expect(b.ambiguous, isTrue);
  });

  test('tanggal tanpa tahun yang sudah lewat pindah ke tahun depan', () {
    expect(p('Tanggal 3 Desember jam 4 ambil rapor adik.')!.date, '2026-12-03');
    expect(p('5 Januari mulai kerja lagi.')!.date, '2027-01-05');
  });

  test('acara seharian tanpa jam', () {
    final r = p('25 Desember libur bareng keluarga.')!;
    expect(r.date, '2026-12-25');
    expect(r.time, isNull);
    expect(r.title, 'Libur bareng keluarga');
  });

  test('nama hari tidak cocok dengan tanggal: tanggal dipakai', () {
    final r = p('Jumat 21 November 2026 jam 10 pagi rapat RT.')!;
    expect(r.date, '2026-11-21');
    expect(r.saidWeekday, DateTime.friday);
  });

  test('format angka 21/11 dan jam 14.30', () {
    final r = p('Kontrol gigi 21/11 14.30.')!;
    expect(r.date, '2026-11-21');
    expect(r.time, '14:30');
    expect(r.title, 'Kontrol gigi');
  });

  test('bukan rencana', () {
    expect(p('Pagi ini beres-beres kamar.'), isNull);
    expect(p('Kemarin jam 9 ke pasar.'), isNull);
    expect(p('Minggu pagi beres-beres.'), isNull); // nama hari saja
    expect(p('Sudah 2 minggu tidak olahraga.'), isNull);
    expect(p('Senin lalu jam 8 rapat.'), isNull);
    expect(p('Beli kopi Rp 25.000 di warung.'), isNull);
    expect(p('Tanggal 31 Februari.'), isNull);
    expect(p('10 November 2026 jam 9 pagi rapat.'), isNull); // sudah lewat
  });

  test('jam hari ini yang sudah lewat bukan rencana', () {
    expect(p('Bangun jam 5 pagi lalu olahraga.'), isNull);
    expect(p('Sarapan 07.30 di rumah.'), isNull);
    // Jam 7 ambigu: 19.00 masih di depan.
    expect(p('Jam 7 nonton bola.')!.date, '2026-11-15');
    expect(p('Nanti malam jam 8 telepon ibu.')!.time, '20:00');
  });

  test('nama hari + kata rencana tanpa jam', () {
    final r = p('Sabtu mau ke rumah nenek.')!;
    expect(r.date, '2026-11-21');
    expect(r.time, isNull);
    expect(p('Minggu depan mulai diet.')!.date, '2026-11-22');
  });

  test('suggestReminders memecah per kalimat', () {
    final found = suggestReminders(
      'Pagi ini beres-beres kamar. Besok jam 9 pagi servis motor. Semoga lancar.\n'
      '25 Desember libur bareng keluarga',
      now,
    );
    expect(found.keys, [
      'Besok jam 9 pagi servis motor.',
      '25 Desember libur bareng keluarga',
    ]);
  });

  test('waktu notifikasi', () {
    expect(
      reminderFireAt('2026-11-21', '13:00', ReminderLead.hourBefore),
      DateTime(2026, 11, 21, 12),
    );
    expect(
      reminderFireAt('2026-11-21', '13:00', ReminderLead.dayBefore),
      DateTime(2026, 11, 20, 13),
    );
    expect(
      reminderFireAt('2026-12-01', null, ReminderLead.atEvent),
      DateTime(2026, 12, 1, 7),
    );
    expect(
      reminderFireAt('2026-12-01', null, ReminderLead.dayBefore),
      DateTime(2026, 11, 30, 7),
    );
    // Seharian tidak punya "1 jam sebelum": jatuh ke pagi hari-H.
    expect(
      reminderFireAt('2026-12-01', null, ReminderLead.hourBefore),
      DateTime(2026, 12, 1, 7),
    );
    expect(reminderDaysLeft('2026-11-21', now), 6);
    expect(reminderDaysLeft('2026-11-15', now), 0);
  });
}
