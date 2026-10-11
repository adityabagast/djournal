# Changelog

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
