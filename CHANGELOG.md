# Changelog

## Belum dirilis

**Baru**
- **Sembunyikan nominal (Mode privasi)**: Opsi untuk menyembunyikan semua angka nominal uang (`Rp •••••`) di seluruh aplikasi demi privasi saat membuka aplikasi di tempat umum.
  - Ikon mata (buka/tutup) di kartu **Total saldo** (Keuangan) dan kartu **Hari ini** (pengeluaran harian) untuk menyembunyikan/menampilkan nominal secara instan.
  - Sakelar permanen di **Pengaturan › Keamanan › Sembunyikan nominal**.
  - Mencakup total saldo, saldo tiap dompet, riwayat transaksi, laporan (pemasukan, pengeluaran, per kategori, budget), hasil pencarian, header pengeluaran di jurnal, dan otomatis disinkronkan ke widget layar utama Android.
- **Warna aksen** (prototipe): Pengaturan › Tampilan › Warna aksen — pilih dari tujuh warna (Hijau sage bawaan, Biru laut, Ungu, Mawar, Pink, Amber, Teal). Tombol, ikon aktif, kartu Total saldo, layar PIN, dan splash ikut berubah, di mode terang maupun gelap. Pilihan tersimpan di app_settings ('accent_color') dan pratinjaunya ada di docs/screenshots/accent-preview.png.

## 0.4.0 — 2026-10-11

**Baru**
- **Mode gelap**: Pengaturan › Tampilan › Sistem / Terang / Gelap. Bawaannya "Sistem" (ikut pengaturan HP). Semua layar, warna kategori, dan maskot punya versi gelap; kartu Total saldo dan layar PIN tetap hijau tua.
  - Splash saat app dibuka ikut gelap (latar gelap, kucing sama). Di Android 12 ke atas splash mengikuti pilihan di app; di versi lebih lama mengikuti pengaturan HP.
  - Widget layar utama (Ringkas, Hari ini, Jurnal cepat) ikut tema yang dipilih.
- **Pencarian** (ikon cari di Hari Ini, Jurnal, Keuangan): cari jurnal dan transaksi (judul, isi, tag, catatan, kategori, dompet, nominal), saring jenis dan periode, kata yang cocok disorot, ringkasan total, dan pencarian terakhir.
- Halaman **Kelola kategori** (Pengaturan › Data › Kelola kategori, atau "Atur" di form catat transaksi): urutkan kategori dengan tahan & geser (urutan ini dipakai di form), ubah nama dan warna, **sembunyikan** kategori dari form (transaksi lamanya tetap), **gabungkan** ke kategori lain (transaksi dan budget ikut pindah), hapus kategori yang belum dipakai, dan tambah kategori baru.
- **Ikon kategori** (opsional): pilih dari 19 ikon saat membuat atau mengubah kategori; dipakai di semua badge kategori.

**Lainnya**
- Nama paket `dev.nyawtat.app` dan kunci rilisnya sudah didaftarkan di Android Developer Console. Sejak aturan verifikasi developer Android berlaku di Indonesia (30 September 2026), APK Nyawtat bisa dipasang di HP yang sudah diizinkan, tanpa diblokir Play Protect.

## 0.3.0 — 2026-10-11

**Baru**
- Splash screen: latar mint dengan kucing Nyawtat saat app dibuka (bukan layar putih lagi), lalu kucing melompat, berkedip, dan memudar ke app. Animasi dilewati kalau animasi dimatikan di pengaturan HP. Tawaran sidik jari/wajah baru muncul setelah animasi selesai.
- Geser kiri/kanan untuk pindah antar-tab (Hari Ini, Jurnal, Keuangan, Laporan). Posisi scroll tiap tab tetap tersimpan.
- Transfer antar dompet: pilih **Transfer** di Catat Transaksi, lalu dompet asal dan tujuan (tombol ⇅ untuk menukar). Transfer tidak dihitung sebagai pemasukan/pengeluaran di laporan dan budget; ada peringatan kalau saldo asal kurang. Di Keuangan ada filter **Transfer** baru.
- Halaman **Kelola dompet** (Keuangan › Kelola): daftar dompet aktif dan arsip, tambah dompet. Dompet bisa **diarsipkan**: tidak tampil di daftar dan total saldo, tapi transaksinya tetap ada di riwayat dan laporan.
- Saat mengubah dompet, isi **Saldo sekarang** (boleh negatif). Selisihnya dicatat sebagai transaksi **Lainnya** dengan catatan "Penyesuaian saldo" (pemasukan kalau naik, pengeluaran kalau turun).
- Impor dari **Money Manager (Realbyte)**: Pengaturan › Data › Impor dari Money Manager, pilih file cadangan `.mmbak` atau ekspor `.xlsx`, periksa pratinjaunya, lalu impor.
  - Akun jadi dompet; akun tunai utama masuk ke Tunai; akun yang sudah dihapus di Money Manager jadi dompet arsip.
  - Kategori yang cocok memakai kategori bawaan, sisanya dibuat baru; sub kategori masuk ke catatan.
  - "Edit saldo" masuk ke saldo awal dompet, jadi laporan tidak tercampur angka koreksi.
  - Impor ulang, atau impor `.xlsx` yang lebih baru setelah `.mmbak`, tidak membuat transaksi dobel; impor ulang `.mmbak` juga memperbaiki hasil impor sebelumnya.

**Perbaikan**
- Font Poppins dibundel lengkap (Regular, Medium, SemiBold, Bold): tampil benar tanpa internet, teks tebal memakai huruf tebal asli, dan app tidak lagi menghubungi server Google Fonts.
- Label beberapa tombol ("Tulis" di Hari Ini, "Atur" di Laporan, tombol di form jurnal, "Pakai biometrik"/"Lupa PIN?") memakai font bawaan sistem, bukan Poppins.
- Saldo dompet yang negatif tetap bertanda minus saat dompet diubah.
- README: screenshot aplikasi.

## 0.2.0 — 2026-10-09

**Baru**
- Jurnal: tap tanggal di strip minggu untuk memfilter entri; tap lagi atau "Tampilkan semua" untuk melepas filter. Panah untuk pindah ke minggu sebelumnya. Tanggal tanpa entri menampilkan tombol "Tulis di tanggal ini".
- Keuangan: dompet bisa diubah (nama, jenis, saldo awal) dan dihapus dengan tap kartu dompet. Menghapus dompet ikut menghapus transaksinya; dompet terakhir tidak bisa dihapus.
- Widget layar utama Android:
  - **Ringkas** (2×2): saldo, keluar hari ini, tombol Catat
  - **Hari ini** (4×2): keluar hari ini, budget bulan ini, tombol Catat dan Tulis
  - **Jurnal cepat** (4×1): jumlah entri hari ini dan jam terakhir, tombol Tulis
  - Nominal disembunyikan otomatis saat PIN aktif; isi jurnal tidak pernah tampil di widget.

**Perbaikan**
- Sinkronisasi pertama tidak lagi menggabungkan dompet "Tunai" bawaan ke dompet yang sudah dihapus di device lain.

## 0.1.0 — 2026-10-09

Rilis pertama.

- Jurnal harian: beberapa entri per hari, jam dan mood opsional, tag
- Keuangan: dompet, kategori, transaksi, budget bulanan, laporan
- Timeline "Hari Ini" yang mencampur jurnal dan transaksi
- Login dan sinkronisasi lewat Supabase
- Ekspor Excel, backup dan impor JSON
- Kunci PIN dan biometrik; build rilis memblokir screenshot
- Bahasa Indonesia dan Inggris, maskot kucing, icon Nyawtat
