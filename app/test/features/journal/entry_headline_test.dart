import 'package:djournal/features/journal/domain/entry_headline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entryHeadline', () {
    test('judul dari user dipakai apa adanya, isi jadi cuplikan', () {
      final h = entryHeadline(title: '  Rapat panjang ', body: 'Capek. Besok libur.');
      expect(h.title, 'Rapat panjang');
      expect(h.preview, 'Capek. Besok libur.');
      expect(h.hasOwnTitle, isTrue);
    });

    test('judul kosong: kalimat pertama jadi judul, sisanya cuplikan', () {
      final h = entryHeadline(
        title: '   ',
        body: 'Ketemu teman lama di stasiun! Kami ngobrol hampir sejam.',
      );
      expect(h.title, 'Ketemu teman lama di stasiun!');
      expect(h.preview, 'Kami ngobrol hampir sejam.');
      expect(h.hasOwnTitle, isFalse);
    });

    test('baris baru juga memisahkan kalimat', () {
      final h = entryHeadline(body: 'Daftar belanja\ntelur, beras, minyak');
      expect(h.title, 'Daftar belanja');
      expect(h.preview, 'telur, beras, minyak');
    });

    test('titik di angka tidak dianggap akhir kalimat', () {
      final h = entryHeadline(body: 'Lari 3.5 km pagi ini. Lumayan.');
      expect(h.title, 'Lari 3.5 km pagi ini.');
      expect(h.preview, 'Lumayan.');
    });

    test('satu kalimat saja: tanpa cuplikan', () {
      final h = entryHeadline(body: 'Hari yang tenang.');
      expect(h.title, 'Hari yang tenang.');
      expect(h.preview, isNull);
    });

    test('kalimat panjang dipotong di spasi + elipsis, lanjutan jadi cuplikan', () {
      const body =
          'hari ini rasanya campur aduk banget dari pagi sampai siang ada aja '
          'yang bikin kepikiran';
      final h = entryHeadline(body: body);
      expect(h.title, 'hari ini rasanya campur aduk banget dari pagi sampai siang…');
      expect(h.title!.length, lessThanOrEqualTo(entryTitleMaxLength + 1));
      expect(h.preview, 'ada aja yang bikin kepikiran');
    });

    test('kata tanpa spasi dipotong tanpa membelah emoji', () {
      final body = '${'a' * (entryTitleMaxLength - 1)}😀sisa';
      final h = entryHeadline(body: body);
      expect(h.title, '${'a' * (entryTitleMaxLength - 1)}…');
      expect(h.preview, '😀sisa');
    });

    test('judul dan isi kosong: title null (UI pakai label cadangan)', () {
      final h = entryHeadline(title: null, body: '  ');
      expect(h.title, isNull);
      expect(h.preview, isNull);
      expect(h.hasOwnTitle, isFalse);
    });
  });
}
