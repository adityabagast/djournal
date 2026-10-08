# djournal server

Backend ASP.NET Core (.NET 10) + EF Core + PostgreSQL untuk login dan sinkronisasi djournal.

## Struktur

```
server/
├─ DJournal.slnx
├─ src/DJournal.Api/
│  ├─ Program.cs              # DI, auth, endpoint
│  ├─ Data/                   # Entity, AppDbContext, migration
│  └─ Sync/                   # DTO, SyncService (push/pull), endpoint
└─ tests/DJournal.Api.Tests/  # Integration test (PostgreSQL sungguhan)
```

## Setup pertama kali

Prasyarat: PostgreSQL dengan user `djournal` yang punya hak `CREATEDB` dan database `djournal` (lihat `docs/setup-windows.md`).

1. Simpan connection string di **user-secrets** (tidak ikut ke git). Ganti `PASSWORD`:

   ```powershell
   dotnet user-secrets set "ConnectionStrings:Default" "Host=localhost;Port=5432;Database=djournal;Username=djournal;Password=PASSWORD" --project src/DJournal.Api
   ```

2. Buat tabel:

   ```powershell
   dotnet ef database update --project src/DJournal.Api
   ```

3. Jalankan:

   ```powershell
   dotnet run --project src/DJournal.Api
   ```

   Cek `http://localhost:5095/api/health`.

## Menyambungkan app di HP (development)

App memakai alamat `http://localhost:5095` secara default. Dengan HP tercolok USB, teruskan port HP ke laptop:

```powershell
adb reverse tcp:5095 tcp:5095
```

Jalankan ulang perintah ini setiap kali HP dicabut-colok. Build **debug** Android mengizinkan `http://`; build release wajib `https://`.

Versi web (Chrome) bisa langsung memakai `localhost` karena CORS diizinkan di environment Development.

## Test

```powershell
dotnet test
```

Setiap run membuat database sementara `djournal_test_…` lalu menghapusnya.

Uji sync dua device dari sisi app (butuh server berjalan):

```powershell
cd ../app
flutter test test/sync_e2e_test.dart --dart-define=SERVER_URL=http://localhost:5095
```

## Endpoint

| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/health` | Cek server hidup |
| POST | `/api/auth/register` | `{ email, password }`. Password cukup min. 8 karakter, tanpa aturan huruf besar/angka/simbol. |
| POST | `/api/auth/login` | `{ email, password }` → `{ accessToken, refreshToken, expiresIn }` |
| POST | `/api/auth/refresh` | `{ refreshToken }` → token baru |
| GET | `/api/me` | Info user yang login |
| POST | `/api/sync/push` | Kirim baris yang berubah di HP |
| GET | `/api/sync/pull?since=N` | Ambil perubahan dengan `server_version > N` |

Semua endpoint `/api/sync/*` dan `/api/me` butuh header `Authorization: Bearer <accessToken>`.
Contoh request ada di [`src/DJournal.Api/DJournal.Api.http`](src/DJournal.Api/DJournal.Api.http).

## Cara kerja sync

Lihat `docs/data-model.md` §5. Ringkasnya:

- **Push**: setiap baris di-insert kalau baru, di-update kalau `updatedAt` dari HP lebih baru, diabaikan kalau versi server lebih baru (last-write-wins). Baris yang berubah mendapat `server_version` baru dari sequence `sync_version_seq`.
- Satu push per user diproses berurutan (`pg_advisory_xact_lock`). Dengan begitu urutan `server_version` milik user sama dengan urutan commit, sehingga pull incremental tidak pernah melewatkan data.
- Satu push = satu transaksi database: kalau ada baris yang tidak valid, semuanya dibatalkan (400).
- **Pull**: semua baris milik user dengan `server_version > since`, termasuk yang sudah dihapus (`deletedAt` terisi). Simpan `cursor` dari respons untuk pull berikutnya.

## Keputusan yang berbeda dari draft data model

- **Login**: memakai bearer token bawaan ASP.NET Core Identity (`MapIdentityApi`), bukan tabel `refresh_tokens` sendiri. Lebih sedikit kode keamanan yang harus dirawat. Kunci enkripsinya disimpan di tabel `data_protection_keys`.
- **Tags jurnal**: kolom `text[]` (array Postgres), bukan `jsonb`. Bentuk di API tetap array string.
