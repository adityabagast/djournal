# Desain: laporan Excel dengan filter, chart, dan rumus

Status: disetujui user 2026-11-24. Tampilan sudah disetujui lewat contoh `.xlsx` (2026-11-24).

## Tujuan

File Excel backup/ekspor bisa dipakai menganalisis langsung: uang habis ke mana, bulan ini surplus atau tidak, budget mana yang jebol. File juga harus bisa dibuka di Excel dan dipulihkan ke app.

- **Bukan tujuan:** perubahan angka di Excel masuk kembali ke app; chart di layar app; perbaikan "Cadangkan Otomatis".
- **Dianggap gagal bila:** pemulihan rusak, Excel meminta perbaikan file, atau angka berbeda dari app.

## Masalah yang ikut diperbaiki

1. Seluruh JSON pemulihan ditulis di satu sel `_Data_Sistem`. Di atas 32.767 karakter, Excel gagal membuka file (terbukti: salinan yang hanya dipendekkan sel itunya langsung terbuka).
2. Cadangan Drive mengikuti pilihan periode, jadi data pemulihannya bisa tidak lengkap, sedangkan Pulihkan memakai file terbaru.

## Pendekatan

| Pilihan | Untung rugi |
|---|---|
| **Tetap `excel`, XML disisipkan (dipilih)** | Pembacaan backup tidak berubah, tanpa lisensi baru; kode lebih banyak dan wajib diuji di Excel/Sheets |
| Syncfusion XlsIO | Filter dan chart tersedia; lisensi komersial/komunitas bersyarat, repo publik |
| Template `.xlsx` | Mudah didesain; `excel` tidak mengenal chart, berisiko hilang saat disimpan |

`excel` 4.0.6 menulis sel, gaya, dan rumus. Setelah `encode()`, file dibuka sebagai ZIP dan bagian yang belum didukung disisipkan memakai `archive` dan `xml` (sudah transitif, dijadikan dependensi langsung). Tidak ada izin Android baru.

## Isi file

Urutan sheet: Ringkasan, Transaksi, Jurnal, Dompet, Budget, lalu `_Hitung` dan `_Data_Sistem` (tersembunyi). Nama, label, dan kriteria rumus mengikuti bahasa app; fungsi rumus ditulis dalam bahasa Inggris di XML.

- **Ringkasan:** dropdown bulan (bulan pertama s.d. terakhir dalam data); pemasukan, pengeluaran, selisih, rata-rata per hari (hari berjalan untuk bulan terakhir), jumlah transaksi, total saldo; tabel per bulan; 5 kategori utama terbesar + Lainnya; mood. Chart: donat kategori, kolom per bulan, batang mood.
- **Transaksi:** header di baris 3, beku, filter. Kolom: Tanggal, Jam, Jenis, Kategori, Dompet, Dompet tujuan, Nominal, Masuk, Keluar, Catatan, Kategori utama. Baris 1 = `SUBTOTAL(109, …)` Masuk dan Keluar serta selisihnya; transfer tidak dihitung.
- **Jurnal:** header beku, filter, cerita dibungkus.
- **Dompet:** saldo awal + perubahan (`SUMIFS`) = saldo sekarang; baris total; batang saldo.
- **Budget:** bulan berjalan; terpakai (`SUMIFS`), sisa, persen ("-" kalau batas 0), merah kalau lewat batas; batang batas vs terpakai.

Aturan hitung:

- Saldo awal Dompet = saldo tepat sebelum periode. Untuk ekspor per periode, judul kolom menjadi "Saldo sebelum periode" dan "Saldo akhir periode", jadi periode lampau tidak tercampur transaksi sesudahnya.
- Chart per bulan menampilkan 12 bulan terakhir supaya tetap terbaca; tabelnya tetap lengkap.
- Nama dompet kembar diberi akhiran " (2)", " (3)", … yang konsisten di Transaksi dan Dompet (berdasarkan id).
- Kategori utama = label sebelum " › ". Budget kategori utama mencakup subkategori, sama seperti `MoneySnapshot.spentIn`.
- Setiap rumus disimpan bersama nilai hasil hitungan app, supaya pratinjau tanpa mesin hitung tetap berisi. `fullCalcOnLoad` aktif.
- Data kosong (tanpa transaksi, jurnal, atau budget) tetap menghasilkan file yang sah; chart tanpa data tidak dibuat.
- Teks user yang diawali `=`, `+`, `-`, `@` selalu ditulis sebagai teks, bukan rumus.
- Keterbatasan yang diterima: baris baru di bawah tabel tidak ikut terhitung.

## Data pemulihan

- `_Data_Sistem!A1` = penanda `nyawtat-backup:gzip-base64:1`; `A2` dst. = JSON yang di-gzip lalu base64, dipotong 30.000 karakter, tiap potongan diawali `z` supaya tidak terbaca sebagai angka. Base64 dipakai karena spasi dan baris baru bisa berubah saat file disimpan ulang Excel.
- Pembaca: ada penanda → gabung dan buka; tanpa penanda dan `A1` diawali `{` → format lama. Selain itu → file tidak valid seperti sekarang.
- **Cadangan Drive:** data pemulihan selalu lengkap; periode hanya membatasi tabel.
- **Ekspor lokal:** data pemulihan tetap mengikuti periode, karena file bisa dibagikan ke orang lain.
- **Konsekuensi:** app versi lama tidak bisa memulihkan file baru. Dicatat di CHANGELOG.

## Pembagian kode (`app/lib/features/backup/data/`)

- `excel_report.dart`: isi sheet dan rumus; tanda tangan `buildExcelReport` tetap.
- `excel_ooxml.dart`: menyisipkan filter, panel beku, dropdown, format bersyarat, chart, sheet tersembunyi, nilai rumus. Tidak tahu soal uang atau jurnal.
- `backup_payload.dart`: bungkus dan buka data pemulihan (dipakai `extractRawBackupJsonFromExcel`).
- `data_section.dart`: cadangan Drive memakai `exportJson()` tanpa periode.

## Pengujian (data dummy)

- Payload: kecil, >32.767 karakter, emoji, format lama, rusak; tidak ada sel di atas 32.767 karakter.
- Rumus: nilai tersimpan sama dengan `MoneySnapshot`; periode, nama dompet kembar, subkategori, transfer, data kosong, Bahasa Inggris.
- Struktur: XML sah, urutan elemen sesuai, relasi dan content type lengkap, sheet tersembunyi, jumlah chart.
- Manual: Excel membuka file dari app tanpa perbaikan dan hitung ulang penuh tidak mengubah nilai tersimpan; simpan ulang di Excel lalu pulihkan; Google Sheets (dicek user).
- `flutter analyze` bersih, semua tes lulus, CHANGELOG dan `app/assets/changelog.md` sama.

## Diserahkan ke pelaksana

Detail XML chart, ukuran dan posisi chart mengikuti contoh, nama kelas internal.
