# Nyawtat — aplikasi Flutter

Gambaran proyek, fitur, dan cara rilis ada di [README utama](../README.md). File ini untuk yang mengubah kode app.

## Menjalankan

```powershell
flutter run                 # HP Android lewat USB
flutter run -d chrome       # Web
```

Web butuh `web/sqlite3.wasm` dan `web/drift_worker.js` yang versinya cocok dengan package `sqlite3`/`drift`.

## Struktur kode

Feature-first: semua kode satu fitur ada di `lib/features/<fitur>/`. Bug di fitur X → mulai cari di `lib/features/X/`, tesnya di `test/features/X/`.

```
lib/
├─ main.dart, app.dart     # Inisialisasi Supabase, MaterialApp, LockGate
├─ providers.dart          # Barrel: ekspor semua provider Riverpod
├─ core/                   # Dipakai banyak fitur
│  ├─ database/            # Drift AppDatabase, tables.dart + kode generate, databaseProvider, row_json
│  ├─ storage/             # Settings key-value (tabel app_settings)
│  ├─ attachments/         # Kompresi & penyimpanan gambar/struk + provider
│  ├─ widgets/             # Komponen bersama, image viewer, maskot
│  ├─ platform/            # PlatformInfo (Android vs desktop)
│  └─ theme.dart, format.dart, config.dart  # Tema, format Rupiah/tanggal, URL + publishable key Supabase
├─ features/<fitur>/
│  ├─ data/                # Repository & service (Drift, Supabase, file, API)
│  ├─ domain/              # Logika bisnis murni, tanpa Flutter UI
│  ├─ providers/           # Provider & Notifier/controller fitur ini
│  └─ presentation/        # Screen, sheet, widget
└─ l10n/                   # app_id.arb (template) + app_en.arb, kode hasil generate
```

| Fitur | Isi |
|---|---|
| `journal` | Entri jurnal, mood, voice note |
| `money` | Transaksi, dompet, kategori, budget, tagihan, wishlist, kalender; `MoneySnapshot` (saldo dihitung dari transaksi) |
| `today` | Beranda harian, streak, kartu ringkasan |
| `report` | Grafik & insight |
| `search` | Pencarian jurnal + transaksi |
| `reminders` | Pengingat, parser teks, notifikasi |
| `backup` | Backup/restore JSON, Google Drive, ekspor Excel, impor Money Manager |
| `account` | Login + sync Supabase (push dirty → pull) |
| `lock` | PIN (hash di secure storage), layar kunci |
| `settings` | Tampilan, bahasa, warna aksen, tentang |
| `update` | Cek & unduh update dari GitHub Releases |
| `games` | Mini game |
| `home_widget` | Data widget layar utama Android |
| `shell`, `splash` | Navigasi utama, splash |

Aturan data (UUID, nominal integer, soft delete, sync last-write-wins) ada di [docs/data-model.md](../docs/data-model.md).

## Setelah mengubah…

| Yang diubah | Jalankan |
|---|---|
| `lib/core/database/tables.dart` | `dart run build_runner build` (dan naikkan `schemaVersion` + migrasi) |
| `lib/l10n/*.arb` | `flutter gen-l10n` |
| `tool/icon/*.svg` (icon app) | `flutter test tool/render_icons_test.dart` lalu `dart run flutter_launcher_icons`; batalkan perubahan `ASSETCATALOG…` yang ikut diubah di `ios/Runner.xcodeproj` |
| `assets/mascot/*.svg` yang dipakai widget | `flutter test tool/render_widget_mascots_test.dart` |
| Tampilan layar (untuk README) | `flutter test tool/screenshots_test.dart` → `docs/screenshots/*.png`, memakai data contoh |

## Test

```powershell
flutter analyze
```
```powershell
flutter test
```

`test/features/account/sync_e2e_test.dart` memakai Supabase sungguhan dan membuat akun uji `djournal.e2e.<waktu>@gmail.com`.

Widget test yang memakai database Drift sungguhan di dalam `testWidgets` bisa macet; override provider dengan data palsu seperti di `test/features/journal/journal_filter_test.dart`.

## Widget layar utama (Android)

```
lib/features/home_widget/data/home_widget_sync.dart        →  SharedPreferences (home_widget)  →  NyawtatWidgets.kt
(string siap tampil, sudah diterjemahkan)                                     (RemoteViews)
```

- Flutter menulis ulang data setiap transaksi, jurnal, status PIN, atau bahasa berubah. Saat PIN aktif, nominal ditulis sebagai `Rp •••••`.
- Kotlin (`android/app/src/main/kotlin/dev/nyawtat/app/widget/`) hanya menampilkan, ditambah satu logika: kalau data berasal dari hari sebelumnya, "keluar hari ini" dan jumlah entri jurnal dianggap 0. Widget memperbarui diri tiap 30 menit.
- Layout ada di `res/layout/widget_*.xml`, info widget di `res/xml/widget_*_info.xml`.
- Tombol di widget membuka app dengan URI `nyawtat://tx` atau `nyawtat://write`, ditangani di `features/shell/home_shell.dart`.

## Font

Poppins dibundel di `assets/fonts/` dalam 4 ketebalan (Regular 400, Medium 500, SemiBold 600, Bold 700; lisensi OFL, lihat `OFL.txt` di folder yang sama) dan didaftarkan sebagai family `Poppins` di `pubspec.yaml`. App tidak mengunduh font dari internet. Kalau butuh ketebalan lain (mis. 800), tambahkan file-nya dulu; tanpa file, Flutter membuat tebal tiruan.

Di `ButtonStyle`, `textStyle` **menggantikan** gaya teks tema, tidak digabung. Pakai `buttonTextStyle(context, …)` dari `core/theme.dart` supaya label tombol tetap Poppins.

## Catatan Android

- `android/gradle.properties` berisi `kotlin.incremental=false` karena proyek di drive D: dan pub cache di C: membuat build Kotlin incremental gagal.
- `MainActivity` adalah `FlutterFragmentActivity` (dibutuhkan `local_auth`) dan memasang `FLAG_SECURE` hanya di build rilis.
