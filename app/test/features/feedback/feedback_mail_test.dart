import 'package:djournal/features/feedback/domain/feedback_mail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validasi', () {
    test('judul minimal 5 huruf, spasi tidak dihitung', () {
      expect(validFeedbackTitle('abcd '), isFalse);
      expect(validFeedbackTitle('abcde'), isTrue);
    });

    test('cerita minimal 10 huruf, spasi tidak dihitung', () {
      expect(validFeedbackBody('  pendek    '), isFalse);
      expect(validFeedbackBody('sepuluh hr'), isTrue);
    });
  });

  group('isi email', () {
    test('info perangkat di akhir dan spasi tepi dibuang', () {
      final mail = FeedbackMail.compose(
        kindLabel: 'Lapor bug',
        title: '  Grafik hilang ',
        areaLine: 'Bagian: Laporan',
        severityLine: 'Mengganggu: Cukup',
        body: ' Buka laporan lalu kosong ',
        deviceLines: const ['Nyawtat 1.2.3 (4)', 'Android 16 · HP Contoh'],
      );
      expect(mail.subject, 'Nyawtat · Lapor bug: Grafik hilang');
      expect(
        mail.body,
        'Bagian: Laporan\nMengganggu: Cukup\n\nBuka laporan lalu kosong\n\n'
        'Nyawtat 1.2.3 (4)\nAndroid 16 · HP Contoh',
      );
    });

    test('tanpa tingkat gangguan dan info perangkat', () {
      final mail = FeedbackMail.compose(
        kindLabel: 'Usul fitur',
        title: 'Widget mingguan',
        areaLine: 'Bagian: Lainnya',
        body: 'Supaya cepat dilihat',
      );
      expect(mail.body, 'Bagian: Lainnya\n\nSupaya cepat dilihat');
    });
  });

  group('tautan mailto', () {
    Uri uri(String title, String body) => FeedbackMail.compose(
      kindLabel: 'Lapor bug',
      title: title,
      areaLine: 'Bagian: Jurnal',
      body: body,
    ).uri('tes@contoh.com');

    test('spasi jadi %20 (bukan +) dan baris baru jadi CRLF', () {
      final s = uri('Dua kata', 'baris satu\nbaris dua').toString();
      expect(s, startsWith('mailto:tes@contoh.com?subject='));
      expect(s, contains('Dua%20kata'));
      expect(s, isNot(contains('+')));
      expect(s, contains('baris%20satu%0D%0Abaris%20dua'));
    });

    test('tulisan user tidak bisa menambah header email lain', () {
      final u = uri('Judul&bcc=a@b.com', 'isi&cc=c@d.com ? # 100%');
      expect(u.queryParameters.keys, ['subject', 'body']);
      expect(u.queryParameters['subject'], contains('Judul&bcc=a@b.com'));
      expect(u.queryParameters['body'], contains('isi&cc=c@d.com ? # 100%'));
    });
  });
}
