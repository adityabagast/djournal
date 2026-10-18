# Changelog

## 0.8.0 — 2026-10-18

**Baru**
- **Cadangan Google Drive Cloud & Format Excel (.xlsx)**:
  - Pencadangan cloud langsung ke Google Drive Anda dalam format spreadsheet Excel (`.xlsx`) yang dapat langsung dibuka, diedit, dan dianalisis di **Google Sheets**.
  - Spreadsheet terbagi dalam 4 lembar kerja (Sheet Tabs) rapi: `📑 Transaksi`, `📖 Jurnal Catatan`, `💵 Dompet & Saldo`, dan `🎯 Budget Bulanan`.
  - Tombol aksi cepat "Buka di Sheets" untuk membuka file cadangan langsung di aplikasi Google Sheets / Browser.
  - Data sistem cadangan tertanam secara aman di file Excel sehingga pemulihan (*restore*) dari Google Drive dapat mengembalikan 100% relasi database, foto, dan catatan tanpa kehilangan format.
- **Pilihan Rentang Waktu Pencadangan (Period Range Filter)**:
  - Fleksibilitas memilih data yang ingin dicadangkan:
    - **Semua Riwayat**: Seluruh riwayat dari awal penggunaan hingga saat ini.
    - **Tahun Ini**: Khusus transaksi dan catatan dalam 1 tahun kalender.
    - **Bulan Ini**: Khusus transaksi dan catatan bulan berjalan.
    - **Rentang Kustom**: Pemilih tanggal kustom (*date range picker*) dari tanggal A s.d. tanggal B.
- **Penyederhanaan Menu Data & Cadangan (Dari 4 Menu Menjadi 2 Pintu Ringkas)**:
  - Menggantikan 4 menu ekspor/impor terpisah yang membingungkan menjadi 2 opsi bersih:
    1. **📤 Cadangkan Data (Ekspor)**: Satu modal praktis untuk memilih format file (Excel `.xlsx` atau Backup `.json`) dan rentang waktu sebelum diekspor.
    2. **📥 Pulihkan / Impor Data**: Satu pintu pemulihan pintar dengan **deteksi format otomatis** (*auto-detection*). Cukup pilih file dari penyimpanan HP, aplikasi secara otomatis mengenali apakah itu file `.json` Nyawtat, file `.xlsx` Nyawtat, atau database Money Manager (`.mmbak`, `.sqlite`, `.db`, `.xlsx`).
- **Masuk dengan Akun Google (Google Sign-In)**:
  - Tombol "Lanjutkan dengan Google" di form Masuk untuk otentikasi cepat dan sinkronisasi Google Drive.

## 0.7.0 — 2026-10-18

**Baru**
- **Lampiran Gambar di Jurnal & Foto Struk di Transaksi Keuangan**:
  - **Lampiran Gambar Jurnal**:
    - Mendukung hingga 10 foto per entri jurnal, baik dari Kamera langsung maupun Galeri foto.
    - Grid pratinjau thumbnail 3 kolom yang responsif dengan nomor urut foto dan tombol hapus instan.
    - Kompresi gambar on-the-fly di perangkat (JPEG 80%, maks 1600px) menjaga efisiensi ruang penyimpanan dan performa ponsel.
    - Strip pratinjau thumbnail foto mini di feed daftar Jurnal.
    - Indikator `📷 X foto` pada linimasa Hari Ini.
  - **Foto Struk / Nota Transaksi Keuangan**:
    - Tombol khusus "Foto Struk Belanja" di form transaksi untuk melampirkan bukti pembayaran dari kamera atau galeri.
    - Pratinjau struk proporsional dengan opsi ganti atau hapus foto struk.
    - Ikon nota `🧾` otomatis muncul di samping nama transaksi pada daftar riwayat dan linimasa Hari Ini.
  - **Fullscreen Image Viewer**:
    - Pratinjau foto layar penuh dengan gestur *pinch-to-zoom*, geser (*swipe* antar gambar), dan tombol tutup.
  - **Optimasi Mobile & Offline-First**:
    - Penyimpanan file lokal persisten di sandbox aplikasi.
    - Skema database Drift SQLite terindeks untuk lookup instan di linimasa tanpa lag scroll.

## 0.6.0 — 2026-10-14

**Baru**
- **Grafik Analisis Pengeluaran interaktif di Laporan**:
  - **Donut Chart (Distribusi Kategori)**: Diagram lingkaran modern yang memvisualisasikan proporsi belanja per kategori secara proporsional dengan warna khas tiap kategori.
    - Bagian tengah menampilkan total pengeluaran dan jumlah kategori; saat kategori atau diagram disentuh, menampilkan nama, nominal, dan persentase belanja kategori tersebut.
    - Daftar peringkat kategori di bawah diagram dilengkapi ikon kategori, persentase, *progress bar* proporsional, nominal, dan penyorotan interaktif.
  - **Bar Chart (Tren Mingguan)**: Diagram batang vertikal yang membagi pengeluaran sebulan ke dalam 4–5 minggu kalender.
    - Memvisualisasikan perbandingan minggu hemat vs minggu boros dengan indikator minggu tertinggi.
    - Dilengkapi ringkasan rata-rata pengeluaran per minggu dan nominal minggu tertinggi.
  - **Navigasi Bulan di Laporan**: Tombol panah bulan sebelumnya (`<`) dan berikutnya (`>`) untuk melihat riwayat laporan dan grafik di bulan-bulan yang lalu, plus tombol pintas "Bulan ini" untuk kembali dengan cepat.

**Perbaikan**
- **Label versi Pengaturan**: Memperbaiki label versi di Pengaturan yang sebelumnya tertinggal.
- **Mode Privasi**: Memperbaiki kebocoran nominal pada subtotal harian di layar Keuangan dan saldo dompet pada form Transfer saat mode privasi aktif.

## 0.5.0 — 2026-10-14

**Baru**
- **Catatan suara (Voice Note & Transkripsi Suara)**: Merekam audio suara asli dan dikte ucapan menjadi teks (*speech-to-text*) secara on-device di entri jurnal.
  - Pilihan 2 mode terdedikasi untuk kualitas maksimal dan mencegah konflik mikrofon Android: **🎙️ Catatan Suara** (rekam audio M4A/AAC jernih hemat ruang dengan kartu pemutar) dan **✍️ Dikte Suara** (ucapan langsung diubah jadi teks ke cerita jurnal secara *real-time*).
  - Dilengkapi animasi detak mikrofon, visualisasi gelombang suara (*waveform*), dan transkripsi *real-time* saat berbicara.
  - Kartu pemutar audio (*VoicePlayerCard*) dengan tombol play/pause, visual *waveform scrubber*, durasi, kontrol kecepatan (1.0x, 1.5x, 2.0x), serta tombol salin transkripsi ke cerita.
  - Pemutar audio ringkas langsung di feed Jurnal dan badge `🎙️ Catatan suara` di timeline Hari Ini.
  - Tombol aksi cepat Catatan Suara di menu tambah cepat (+) dock utama.
  - Teks transkripsi suara otomatis terindeks dan bisa dicari lewat fitur Pencarian.
- **Sembunyikan nominal (Mode privasi)**: Opsi untuk menyembunyikan semua angka nominal uang (`Rp •••••`) di seluruh aplikasi demi privasi saat membuka aplikasi di tempat umum.
  - Ikon mata (buka/tutup) di kartu **Total saldo** (Keuangan) dan kartu **Hari ini** (pengeluaran harian) untuk menyembunyikan/menampilkan nominal secara instan.
  - Sakelar permanen di **Pengaturan › Keamanan › Sembunyikan nominal**.
  - Mencakup total saldo, saldo tiap dompet, riwayat transaksi, laporan (pemasukan, pengeluaran, per kategori, budget), hasil pencarian, header pengeluaran di jurnal, dan otomatis disinkronkan ke widget layar utama Android.
- **Warna aksen** (prototipe): Pengaturan › Tampilan › Warna aksen — pilih dari tujuh warna (Hijau sage bawaan, Biru laut, Ungu, Mawar, Pink, Amber, Teal). Tombol, ikon aktif, kartu Total saldo, layar PIN, dan splash ikut berubah, di mode terang maupun gelap. Pilihan tersimpan di app_settings ('accent_color') dan pratinjaunya ada di docs/screenshots/accent-preview.png.

**Perbaikan**
- **Formulir dompet (Penyesuaian saldo)**: Menambahkan scroll otomatis pada lembar tambah/ubah dompet agar tidak terjadi *bottom overflow* saat keyboard angka muncul.
- **Urutan linimasa & entri (Descending)**: Linimasa aktivitas di tab **Hari Ini** dan daftar catatan dalam satu hari di tab **Jurnal** kini diurutkan menurun (*descending*) dengan jam terbaru tampil di paling atas, sehingga aktivitas/catatan yang baru saja dibuat langsung terlihat di atas.

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
