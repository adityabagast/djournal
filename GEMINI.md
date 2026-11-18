# Project Guidelines & Rules — Nyawtat (djournal)

Dokumen ini berisi aturan dan konvensi pengembangan proyek **Nyawtat** untuk diikuti oleh AI agent.

---

## 🎨 1. Aturan Wajib Fitur Baru: "Interactive Prototype First"

> **PENTING:** Setiap kali ada rencana penambahan fitur baru atau perubahan alur UI/UX:
> 1. **DILARANG langsung menulis kode Flutter / Backend.**
> 2. **Wajib membuat prototipe desain interaktif terlebih dahulu** berupa file HTML/CSS/JS (standalone atau interactive artifact/generative UI), mirip seperti contoh di `docs/accent-prototype/index.html`.
> 3. Prototipe harus bisa diinteraksikan (klik tombol, preview bodi ponsel/desktop, ganti state/tema) agar user bisa mencoba dan me-review alur secara visual.
> 4. Tunggu persetujuan atau revisi dari user sebelum mulai mengimplementasikannya ke kode Flutter/backend.
> 5. **Prototipe dilanjutkan sebagai artboard di canvas Claude Design** (https://claude.ai/artifact/XL1VqmFK6psaUQECnsgm6H), bukan file `docs/*-prototype/` baru. Baca **`docs/design-canvas/README.md`** dulu untuk format, gaya, dan cara menambah artboard.

---

## 🏗️ 2. Arsitektur Kode (Clean Architecture & Feature-First)

1. **Struktur Feature-First:** semua kode satu fitur ada di `lib/features/<fitur>/`. Bug di fitur X → mulai cari di `lib/features/X/`.
   ```
   lib/features/<fitur>/
   ├─ data/          # repository & service (Drift, Supabase, file, API)
   ├─ domain/        # logika bisnis murni, tanpa Flutter UI (mis. MoneySnapshot)
   ├─ providers/     # Riverpod provider & Notifier/controller fitur ini
   └─ presentation/  # screen, sheet, widget
   ```
   - Fitur: `journal`, `money` (dompet, kategori, budget, tagihan, wishlist), `today`, `report`, `search`, `reminders`, `backup` (backup/restore, Google Drive, ekspor Excel, impor Money Manager), `account` (login + sync Supabase), `lock` (PIN), `settings`, `update`, `games`, `home_widget`, `shell`, `splash`.
   - `lib/core/`: yang dipakai banyak fitur — `database/` (Drift `AppDatabase`, tabel, `databaseProvider`), `storage/` (settings key-value), `attachments/`, `widgets/` (common, mascot, image viewer), `platform/`, `theme.dart`, `format.dart`, `config.dart`.
   - `lib/providers.dart`: barrel yang mengekspor semua provider; provider baru tetap ditulis di folder fiturnya lalu ditambahkan ke barrel.
   - Tes mengikuti struktur yang sama: `test/features/<fitur>/`, `test/core/`.
   - `core/` tidak boleh bergantung pada UI fitur; fitur boleh memakai `core/` dan `domain`/`providers` fitur lain.

2. **Dukungan Multi-Platform (Android & Desktop):**
   - Selalu gunakan `PlatformInfo` dari `core/platform/platform_info.dart` untuk memisahkan fitur khusus platform.
   - Jangan pernah memanggil modul khusus Android (seperti `home_widget` atau RemoteViews) tanpa guard `if (PlatformInfo.isAndroid)`.

3. **Integritas Database & Offline-First:**
   - Semua id menggunakan UUID v4 yang dibuat di client.
   - Nominal uang selalu `int` (Rupiah), dilarang float/double.
   - Saldo tidak pernah disimpan di database, selalu dihitung dari transaksi.
   - Soft delete (`deleted_at`) untuk sinkronisasi last-write-wins.

