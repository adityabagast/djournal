# Nyawtat

Aplikasi pribadi yang menggabungkan **jurnal harian** dan **catatan keuangan** dalam satu timeline. Nama "Nyawtat" dari *nyaw* (suara kucing) + *catat*. Offline-first: semua data tersimpan di HP, lalu disinkronkan ke cloud kalau login.

> Repo ini bernama `djournal` (nama awal proyek). Versi terbaru: **0.5.0**, lihat [CHANGELOG.md](CHANGELOG.md).

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
  <tr>
    <td align="center"><img src="docs/screenshots/hari-ini-gelap.png" width="240" alt="Layar Hari Ini dalam mode gelap"><br><b>Mode gelap</b></td>
    <td align="center"><img src="docs/screenshots/cari.png" width="240" alt="Pencarian &quot;makan&quot;: transaksi yang cocok dikelompokkan per hari, kata yang cocok disorot"><br><b>Pencarian</b></td>
    <td align="center"><img src="docs/screenshots/kelola-kategori.png" width="240" alt="Kelola kategori: daftar kategori pengeluaran dengan pegangan geser, jumlah transaksi, dan budget"><br><b>Kelola kategori</b></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/catatan-suara.png" width="240" alt="Form entri jurnal dengan pemutar rekaman suara dan transkripsi"><br><b>Catatan suara</b></td>
    <td align="center"><img src="docs/screenshots/mode-privasi.png" width="240" alt="Layar Keuangan saat mode privasi aktif: semua nominal uang disembunyikan"><br><b>Mode privasi</b></td>
    <td align="center"><img src="docs/screenshots/kelola-dompet.png" width="240" alt="Layar Kelola Dompet: daftar dompet aktif dan arsip"><br><b>Kelola dompet</b></td>
  </tr>
</table>

<sub>Screenshot memakai data contoh dan dibuat otomatis dengan <code>flutter test tool/screenshots_test.dart</code>.</sub>

## Pasang

1. Unduh **`app-arm64-v8a-release.apk`** (~24 MB) dari [Releases](../../releases/latest). HP lama yang gagal memasangnya: pakai `app-armeabi-v7a-release.apk`.
2. Buka file itu di HP lalu pilih **Instal**. Versi baru bisa langsung dipasang di atas versi lama; data tetap aman.

> Untuk membangun APK rilis sendiri dengan ukuran teroptimasi (~24 MB, hemat 67% dibanding fat APK):
> ```powershell
> cd app
> flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
> ```

> Sejak 30 September 2026, Android di Indonesia hanya mau memasang app dari developer yang terverifikasi. Nyawtat sudah terdaftar di Android Developer Console dengan distribusi terbatas, jadi HP harus **diizinkan developer dulu** (maksimal 20 HP). Tanpa itu muncul pesan "Aplikasi diblokir untuk melindungi perangkat Anda".

## Fitur

**Jurnal & Catatan Suara**
- Beberapa entri per hari, masing-masing dengan jam (opsional), mood 1–5 (opsional), judul, isi, dan tag
- **Catatan Suara (Voice Note)**: rekam suara asli (format AAC/M4A hemat ruang) dengan kartu pemutar interaktif (*seekable waveform*, tombol play/pause, dan kontrol kecepatan 1.0x, 1.5x, 2.0x)
- **Dikte Suara**: bicara langsung dan ucapan diubah menjadi teks (*speech-to-text*) secara on-device ke dalam cerita entri jurnal
- Teks transkripsi suara otomatis terindeks dan bisa dicari di Pencarian
- Strip minggu yang bisa ditap untuk memfilter entri per tanggal, plus panah untuk pindah minggu
- Mood harian = rata-rata mood entri hari itu

**Keuangan**
- Dompet (tunai, bank, e-wallet, lainnya): tambah, ubah saldo (penyesuaian otomatis), arsipkan, hapus
- **Mode Privasi**: sembunyikan semua nominal uang (`Rp •••••`) dengan ikon mata instan di kartu saldo/pengeluaran atau sakelar permanen di Pengaturan Keamanan
- Transaksi pemasukan/pengeluaran per kategori; saldo selalu dihitung dari transaksi
- Transfer antar dompet (mis. tarik tunai BCA → Tunai), tidak dihitung sebagai pemasukan/pengeluaran
- Kelola kategori: urutkan, ubah nama/warna/ikon, sembunyikan, gabungkan, hapus
- Budget bulanan per kategori yang berlanjut ke bulan berikutnya
- Laporan: pengeluaran per kategori, budget, serta hubungan mood dan pengeluaran

**Hari Ini**: satu linimasa descending (terbaru di atas) yang mencampur entri jurnal dan transaksi, plus bar budget bulan berjalan.

**Lainnya**
- Pencarian jurnal dan transaksi (teks, tag, kategori, dompet, nominal) dengan filter jenis dan periode
- Mode gelap (Sistem / Terang / Gelap), termasuk splash dan widget layar utama
- Login dan sinkronisasi antar-device lewat Supabase (last-write-wins, soft delete)
- Kunci PIN 4 digit + sidik jari/wajah; build rilis memblokir screenshot dan pratinjau di daftar app terbaru
- Ekspor ke Excel (untuk dibaca) dan backup/impor JSON (untuk restore)
- Impor riwayat dari Money Manager (Realbyte): file cadangan `.mmbak` atau ekspor `.xlsx`
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