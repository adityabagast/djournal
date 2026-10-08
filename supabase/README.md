# djournal backend (Supabase)

Login dan sinkronisasi djournal memakai [Supabase](https://supabase.com): Auth untuk akun, PostgreSQL untuk data, dan dua fungsi SQL untuk sync.

```
supabase/
├─ migrations/20261008000000_init.sql   # tabel, RLS, sync_push, sync_pull
└─ tests/
   ├─ local_harness.sql                 # tiruan skema "auth" untuk Postgres biasa
   ├─ sync_test.sql                     # 7 skenario uji
   └─ run-local.ps1                     # jalankan uji di PostgreSQL laptop
```

## Setup project Supabase baru

1. Buat project (paket Free, region Southeast Asia / Singapore).
2. **Authentication → Sign In / Providers → Email**: matikan **Confirm email** (server email bawaan paket gratis sangat dibatasi).
3. **SQL Editor → New query**: tempel isi `migrations/20261008000000_init.sql`, lalu **Run**.
4. Salin **Project URL** (tanpa `/rest/v1/`) dan **Publishable key** ke `app/lib/config.dart`, atau berikan saat build:

   ```powershell
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_KEY=sb_publishable_xxx
   ```

   **Jangan** pernah memakai Secret key / service_role di app.

## Cara kerja sync

Sama dengan `docs/data-model.md` §5:

- `sync_push(payload)`: baris baru di-insert, baris lama di-update hanya kalau `updatedAt` dari HP lebih baru (last-write-wins), selebihnya diabaikan. Setiap baris yang berubah mendapat nomor dari sequence `sync_version_seq`. Satu panggilan = satu transaksi; baris tidak valid membatalkan semuanya.
- Push per user diproses berurutan (`pg_advisory_xact_lock`), jadi urutan `server_version` sama dengan urutan commit dan pull incremental tidak melewatkan data.
- `sync_pull(since)`: semua baris milik user dengan `server_version > since`, termasuk yang terhapus (`deletedAt`), plus `cursor` baru.
- **Keamanan**: Row Level Security hanya mengizinkan user **membaca** barisnya sendiri. Menulis hanya lewat `sync_push`, yang memeriksa kepemilikan setiap id dan setiap dompet/kategori yang dirujuk. Fungsi hanya bisa dipanggil user yang sudah login.

## Uji

Di PostgreSQL laptop (tanpa akun Supabase; kredensial dari user-secrets `server/`):

```powershell
powershell -ExecutionPolicy Bypass -File supabase/tests/run-local.ps1
```

Uji dua device lewat Supabase sungguhan (membuat user tes; hapus di Dashboard → Authentication → Users):

```powershell
cd app
flutter test test/sync_e2e_test.dart
```

## Catatan paket gratis

- Project di-pause setelah 1 minggu tanpa aktivitas database; bisa di-restore dari dashboard tanpa kehilangan data.
- Tidak ada backup otomatis. Fitur ekspor data di app direncanakan.
