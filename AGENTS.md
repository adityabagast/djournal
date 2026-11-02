# Project Guidelines & Rules — Nyawtat (djournal)

Dokumen ini berisi aturan dan konvensi pengembangan proyek **Nyawtat** untuk diikuti oleh AI agent.

---

## 🎨 1. Aturan Wajib Fitur Baru: "Interactive Prototype First"

> **PENTING:** Setiap kali ada rencana penambahan fitur baru atau perubahan alur UI/UX:
> 1. **DILARANG langsung menulis kode Flutter / Backend.**
> 2. **Wajib membuat prototipe desain interaktif terlebih dahulu** berupa file HTML/CSS/JS (standalone atau interactive artifact/generative UI), mirip seperti contoh di `docs/accent-prototype/index.html`.
> 3. Prototipe harus bisa diinteraksikan (klik tombol, preview bodi ponsel/desktop, ganti state/tema) agar user bisa mencoba dan me-review alur secara visual.
> 4. Tunggu persetujuan atau revisi dari user sebelum mulai mengimplementasikannya ke kode Flutter/backend.

---

## 🏗️ 2. Arsitektur Kode (Clean Architecture & Feature-First)

1. **Struktur Multi-Layer:**
   - `lib/domain/models/`: Logika bisnis murni (misal `MoneySnapshot`, kalkulasi saldo & budget). Bebas dependensi Flutter UI.
   - `lib/data/`: Akses data (Drift SQLite lokal, sinkronisasi backend, secure storage, export service).
   - `lib/providers/`: Registrasi Riverpod providers yang terbagi modular (`database_providers`, `money_providers`, `journal_providers`, `settings_providers`).
   - `lib/features/`: Tampilan layar per fitur (Today, Journal, Money, Report, Settings, Lock, Shell).
   - `lib/core/`: Format rupiah/tanggal, tema aplikasi, dan `PlatformInfo`.

2. **Dukungan Multi-Platform (Android & Desktop):**
   - Selalu gunakan `PlatformInfo` dari `core/platform/platform_info.dart` untuk memisahkan fitur khusus platform.
   - Jangan pernah memanggil modul khusus Android (seperti `home_widget` atau RemoteViews) tanpa guard `if (PlatformInfo.isAndroid)`.

3. **Integritas Database & Offline-First:**
   - Semua id menggunakan UUID v4 yang dibuat di client.
   - Nominal uang selalu `int` (Rupiah), dilarang float/double.
   - Saldo tidak pernah disimpan di database, selalu dihitung dari transaksi.
   - Soft delete (`deleted_at`) untuk sinkronisasi last-write-wins.


---

## 🔐 3. Security Awareness (Testing → Analyze → Commit → Rilis)

Nyawtat menyimpan jurnal pribadi dan data keuangan. Setiap tahap wajib dicek:

1. **Testing**
   - Pakai data dummy saja. Jangan memakai isi jurnal, nominal, email, atau file backup asli user di tes, screenshot, atau log.
   - Tes e2e Supabase memakai akun tes khusus (mis. `djournal.e2e.<ts>@gmail.com`), bukan akun user.
   - Jangan menambah `print`/log yang memuat isi jurnal, nominal, token, atau PIN.
   - Saat mencoba app di browser/HP user: jangan mengubah pengaturan, akun, atau data di luar yang sedang dites; laporkan kalau tidak sengaja terubah.

2. **Analyze**
   - `flutter analyze` wajib bersih (tidak ada issue baru); jangan mematikan lint untuk "meluluskan" kode.
   - Cek dependensi baru: sumbernya pub.dev resmi, aktif dirawat, izin Android yang ditambahkan jelas alasannya. Catat izin baru di CHANGELOG.
   - Semua request jaringan wajib HTTPS dan tidak mengirim data pribadi (mis. cek update hanya membaca rilis GitHub).
   - File yang diunduh (mis. APK update) wajib diverifikasi (sha256 + tanda tangan Android) sebelum dipakai.

3. **Commit**
   - Periksa `git diff --cached` sebelum commit: tidak boleh ada `key.properties`, `*.jks`, password, token, connection string, service-role key Supabase, atau file backup/ekspor user.
   - Kunci publik yang memang aman (Supabase publishable key, `google-services.json`) boleh, kunci rahasia tidak pernah.
   - Jangan commit perubahan yang melemahkan keamanan (mis. menghapus `FLAG_SECURE` di rilis, cleartext di manifest rilis, RLS dimatikan) tanpa persetujuan eksplisit user.

4. **Rilis**
   - Build rilis wajib memakai release key (bukan debug key); cek dengan `apksigner verify --print-certs` bahwa SHA-256 sertifikat sama dengan yang terdaftar di Android Developer Console.
   - Cantumkan sha256 tiap APK di catatan rilis GitHub (`Get-FileHash <apk> -Algorithm SHA256`) supaya user dan fitur update di app bisa memverifikasi file.
   - Migration Supabase direview dulu: RLS tetap aktif, fungsi `security definer` memakai `set search_path = ''`, dan menolak data milik user lain. Jalankan tes SQL lokal sebelum diterapkan ke server.
   - Distribusi Firebase hanya ke grup tester yang dimaksud; catatan rilis tidak boleh memuat data pribadi.
