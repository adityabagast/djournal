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

