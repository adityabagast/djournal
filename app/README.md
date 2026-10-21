# Nyawtat — aplikasi Flutter

Gambaran proyek, fitur, dan cara rilis ada di [README utama](../README.md). File ini untuk yang mengubah kode app.

## Menjalankan

```powershell
flutter run                 # HP Android lewat USB
flutter run -d chrome       # Web
```

Web butuh `web/sqlite3.wasm` dan `web/drift_worker.js` yang versinya cocok dengan package `sqlite3`/`drift`.

## Struktur kode

```
lib/
├─ main.dart, app.dart     # Inisialisasi Supabase, MaterialApp, LockGate
├─ providers.dart          # Semua provider Riverpod (database, repository, stream data)
├─ config.dart             # URL + publishable key Supabase (publik by design)
├─ core/                   # Format Rupiah/tanggal, tema
├─ data/
│  ├─ db/                  # Skema Drift (tables.dart) + kode hasil generate
│  ├─ money_repository.dart, journal_repository.dart, settings_repository.dart
│  ├─ wishlist_repository.dart, bill_repository.dart # Target wishlist & tagihan
│  ├─ attachment_repository.dart # Kompresi & penyimpanan gambar/struk
│  ├─ google_drive_service.dart   # Otentikasi Google & Google Drive API (.xlsx)
│  ├─ money_snapshot.dart  # Saldo, budget, ringkasan: dihitung dari transaksi
│  ├─ sync/                # Supabase backend, sync engine (push dirty → pull)
│  ├─ security/            # PIN (hash di secure storage) + status kunci
│  ├─ backup_service.dart  # Backup/impor JSON dengan filter rentang
│  ├─ excel_report.dart    # Ekspor Excel multi-sheet (Google Sheets ready)
│  └─ home_widget_sync.dart  # Data untuk widget layar utama Android
├─ domain/models/          # Model bisnis murni: MoneySnapshot, BackupPeriod, GlobalBudget, StreakInfo
├─ features/               # Satu folder per layar: today, journal, money, report, settings, lock, account, shell
├─ l10n/                   # app_id.arb (template) + app_en.arb, kode hasil generate
└─ ui/                     # Komponen bersama, image viewer, maskot, wajah mood
```

Aturan data (UUID, nominal integer, soft delete, sync last-write-wins) ada di [docs/data-model.md](../docs/data-model.md).

## Setelah mengubah…

| Yang diubah | Jalankan |
|---|---|
| `lib/data/db/tables.dart` | `dart run build_runner build` (dan naikkan `schemaVersion` + migrasi) |
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

`test/sync_e2e_test.dart` memakai Supabase sungguhan dan membuat akun uji `djournal.e2e.<waktu>@gmail.com`.

Widget test yang memakai database Drift sungguhan di dalam `testWidgets` bisa macet; override provider dengan data palsu seperti di `test/journal_filter_test.dart`.

## Widget layar utama (Android)

```
lib/data/home_widget_sync.dart        →  SharedPreferences (home_widget)  →  NyawtatWidgets.kt
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
