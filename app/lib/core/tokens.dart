/// Token desain Nyawtat: spasi, radius, ukuran font, dan durasi animasi.
///
/// Skala Fase 2 (disetujui di design canvas, artboard "00 Usulan token
/// Fase 2"). Pakai token ini, bukan angka langsung. Angka di luar skala
/// hanya untuk ukuran elemen (lebar ikon, tinggi tombol), bukan jarak.
///
/// Warna ada di [AppPalette] (`theme.dart`), bukan di sini.
library;

/// Jarak: padding, margin, dan celah `SizedBox`. Kelipatan 4 (kecuali [xxs]).
abstract final class AppSpace {
  /// Garis rambut: jarak judul–subjudul yang sangat rapat.
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;

  /// Tepi layar.
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Radius sudut untuk `BorderRadius.circular` / `Radius.circular`.
abstract final class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;

  /// Input, ikon kategori.
  static const md = 12.0;
  static const lg = 16.0;

  /// Kartu, bottom sheet (sudut atas).
  static const xl = 24.0;

  /// Bentuk kapsul penuh: tombol, chip, dock, pegangan sheet.
  static const pill = 999.0;
}

/// Ukuran font (Poppins).
abstract final class AppFontSize {
  /// Label kecil, badge, keterangan grafik.
  static const caption = 11.0;

  /// Meta: kategori · dompet · jam.
  static const meta = 12.0;
  static const body = 13.0;
  static const bodyLg = 14.0;

  /// Judul kartu.
  static const title = 16.0;

  /// Judul sheet.
  static const heading = 18.0;
  static const display = 22.0;
}

/// Durasi animasi.
abstract final class AppMotion {
  /// Transisi kecil: ganti state, fade, warna.
  static const short = Duration(milliseconds: 150);

  /// Pindah halaman di dalam kartu (geser).
  static const page = Duration(milliseconds: 250);

  /// Umpan balik instan.
  static const instant = Duration(milliseconds: 100);
}
