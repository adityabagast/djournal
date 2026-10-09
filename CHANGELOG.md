# Changelog

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
