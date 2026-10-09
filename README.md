# Nyawtat

Aplikasi pribadi yang menggabungkan **jurnal harian** dan **catatan keuangan** dalam satu timeline. Nama "Nyawtat" dari *nyaw* (suara kucing) + *catat*. Offline-first: semua data tersimpan di HP, lalu disinkronkan ke cloud kalau login.

> Repo ini bernama `djournal` (nama awal proyek). Versi terbaru: **0.2.0**, lihat [CHANGELOG.md](CHANGELOG.md).

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/hari-ini.png" width="240" alt="Layar Hari Ini: pengeluaran hari ini, bar budget, dan timeline jurnal + transaksi"><br><b>Hari Ini</b></td>
    <td align="center"><img src="docs/screenshots/jurnal.png" width="240" alt="Layar Jurnal: strip minggu dan entri per hari dengan mood dan tag"><br><b>Jurnal</b></td>
    <td align="center"><img src="docs/screenshots/keuangan.png" width="240" alt="Layar Keuangan: total saldo, dompet, dan daftar transaksi"><br><b>Keuangan</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/laporan.png" width="240" alt="Layar Laporan: ringkasan bulan dan budget per kategori"><br><b>Laporan</b></td>
    <td align="center"><img src="docs/screenshots/tulis-jurnal.png" width="240" alt="Form entri jurnal: jam, mood, judul, cerita, tag, dan transaksi di hari yang sama"><br><b>Tulis jurnal</b></td>
    <td align="center"><img src="docs/screenshots/kunci.png" width="240" alt="Layar kunci PIN dengan maskot kucing"><br><b>Kunci PIN</b></td>
  </tr>
</table>

<sub>Screenshot memakai data contoh dan dibuat otomatis dengan <code>flutter test tool/screenshots_test.dart</code>.</sub>

## Fitur

**Jurnal**
- Beberapa entri per hari, masing-masing dengan jam (opsional), mood 1–5 (opsional), judul, isi, dan tag
- Strip minggu yang bisa ditap untuk memfilter entri per tanggal, plus panah untuk pindah minggu
- Mood harian = rata-rata mood entri hari itu

**Keuangan**
- Dompet (tunai, bank, e-wallet, lainnya): tambah, ubah, hapus
- Transaksi pemasukan/pengeluaran per kategori; saldo selalu dihitung dari transaksi
- Budget bulanan per kategori yang berlanjut ke bulan berikutnya
- Laporan: pengeluaran per kategori, budget, serta hubungan mood dan pengeluaran

**Hari Ini**: satu timeline yang mencampur entri jurnal dan transaksi, plus bar budget bulan berjalan.

**Lainnya**
- Login dan sinkronisasi antar-device lewat Supabase (last-write-wins, soft delete)
- Kunci PIN 4 digit + sidik jari/wajah; build rilis memblokir screenshot dan pratinjau di daftar app terbaru
- Ekspor ke Excel (untuk dibaca) dan backup/impor JSON (untuk restore)
- Widget layar utama Android: **Ringkas** 2×2, **Hari ini** 4×2, **Jurnal cepat** 4×1. Nominal disembunyikan otomatis saat PIN aktif; widget jurnal tidak pernah menampilkan isi entri.
- Bahasa Indonesia dan Inggris
- Maskot kucing di layar kosong, layar PIN, dan notifikasi

Platform: **Android** (utama) dan **Web**. iOS belum diuji.

## Teknologi

| Bagian | Stack |
|---|---|
| App | Flutter 3.47, Riverpod 3, Drift (SQLite), gen-l10n |
| Backend | Supabase (Auth + PostgreSQL + fungsi SQL `sync_push`/`sync_pull`) |
| Widget Android | `home_widget` + RemoteViews (Kotlin) |
| Arsip | ASP.NET Core (.NET 10) di `server/`, tidak dipakai lagi |

## Struktur repo

```
djournal/
├─ app/        # Aplikasi Flutter, lihat app/README.md
├─ supabase/   # Migrasi SQL + uji sync, lihat supabase/README.md
├─ server/     # Backend .NET lama (diarsipkan)
└─ docs/
   ├─ data-model.md      # Skema tabel, aturan sync, keputusan cakupan
   └─ setup-windows.md   # Menyiapkan Flutter + Android SDK tanpa Android Studio
```

Desain UI dan prototipe ada di design canvas (privat): https://claude.ai/artifact/EeTer4NctCKHnJwgQujW4o

## Mulai

1. Siapkan toolchain: [docs/setup-windows.md](docs/setup-windows.md)
2. Siapkan backend Supabase (sekali saja): [supabase/README.md](supabase/README.md)
3. Jalankan app dari folder `app/`:

   ```powershell
   flutter pub get
   ```
   ```powershell
   flutter run
   ```

Detail pengembangan (struktur kode, test, alat bantu) ada di [app/README.md](app/README.md).

## Rilis Android

Kunci rilis disimpan di luar repo (`D:/keys/nyawtat-release.jks`), dibaca lewat `app/android/key.properties` yang di-gitignore. Contoh isinya: `app/android/key.properties.example`.

1. Naikkan `version` di `app/pubspec.yaml` (angka setelah `+` wajib naik setiap rilis) dan label versi di `app/lib/features/settings/settings_screen.dart`.
2. Tambahkan catatan di [CHANGELOG.md](CHANGELOG.md), lalu commit dan push.
3. Build dari folder `app/`:

   ```powershell
   flutter build apk --release --split-per-abi
   ```

   HP arm64 memakai `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
4. Buat tag dan push:

   ```powershell
   git tag -a v0.2.0 -m "Nyawtat 0.2.0"
   ```
   ```powershell
   git push origin v0.2.0
   ```
5. Buat GitHub Release dari tag itu dan lampirkan APK-nya.

Build rilis tidak bisa dipasang menimpa build debug (tanda tangan berbeda): uninstall dulu dengan `adb uninstall dev.nyawtat.app`.
