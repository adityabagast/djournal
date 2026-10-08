# Setup Lingkungan Development — Windows + VS Code

Panduan menyiapkan laptop Windows untuk mengembangkan djournal: Flutter (Android + Web) dan backend ASP.NET Core. **Tanpa Android Studio.**

- Perkiraan waktu: 45–90 menit (sebagian besar menunggu download)
- Ruang disk: sekitar 15 GB
- Semua perintah dijalankan di **terminal PowerShell VS Code** (`` Ctrl+` ``)

> **Penting:** setiap kali langkah mengubah environment variable (PATH, JAVA_HOME, ANDROID_HOME), **tutup semua jendela VS Code lalu buka lagi**. Terminal di VS Code hanya membaca environment variable saat VS Code dibuka.

---

## Langkah 1 — Ekstensi VS Code

Buka Extensions (`Ctrl+Shift+X`) dan install:

| Ekstensi | Untuk apa |
|---|---|
| **Flutter** (Dart Code) | Coding Flutter. Otomatis ikut memasang ekstensi Dart. |
| **C# Dev Kit** (Microsoft) | Coding backend ASP.NET Core |
| **SQLite Viewer** (opsional) | Melihat isi database lokal |

Atau lewat terminal:

```powershell
code --install-extension Dart-Code.flutter
```
```powershell
code --install-extension ms-dotnettools.csdevkit
```

---

## Langkah 2 — Aktifkan Developer Mode Windows

Flutter butuh fitur symlink Windows untuk memakai plugin. Tanpa ini build akan gagal dengan pesan *"Building with plugins requires symlink support"*.

```powershell
start ms-settings:developers
```

Di jendela yang terbuka, nyalakan **Developer Mode** lalu pilih **Yes**.

---

## Langkah 3 — Java (JDK 17)

Dibutuhkan Gradle untuk build aplikasi Android.

```powershell
winget install Microsoft.OpenJDK.17
```

Set `JAVA_HOME` (perintah ini mencari folder JDK otomatis lalu menampilkan path-nya):

```powershell
$jdk = (Get-ChildItem "C:\Program Files\Microsoft" -Directory -Filter "jdk-17*" | Select-Object -First 1).FullName; [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk, "User"); $jdk
```

**Restart VS Code**, lalu cek:

```powershell
java -version
```

Harus muncul `openjdk version "17.…"`.

---

## Langkah 4 — Flutter SDK

Clone Flutter ke `C:\dev\flutter`. Jangan taruh di folder yang mengandung spasi atau di `Program Files`.

```powershell
git clone https://github.com/flutter/flutter.git -b stable C:\dev\flutter
```

Tambahkan ke PATH:

```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\dev\flutter\bin", "User")
```

**Restart VS Code**, lalu cek (pertama kali akan mengunduh Dart SDK, tunggu sampai selesai):

```powershell
flutter --version
```

Opsional, matikan pengiriman data analitik:

```powershell
flutter config --no-analytics
```

---

## Langkah 5 — Android SDK (tanpa Android Studio)

### 5a. Download command-line tools

1. Buka https://developer.android.com/studio
2. Scroll ke bagian **"Command line tools only"**
3. Download file **Windows** (`commandlinetools-win-…_latest.zip`) dan setujui syaratnya. File tersimpan di folder Downloads.

### 5b. Extract ke `C:\Android`

```powershell
$zip = Get-ChildItem "$env:USERPROFILE\Downloads\commandlinetools-win-*.zip" | Select-Object -First 1; Expand-Archive $zip.FullName -DestinationPath C:\Android\cmdline-tools
```

Isi zip berada di folder `cmdline-tools`. Ganti namanya menjadi `latest` (struktur ini wajib):

```powershell
Rename-Item C:\Android\cmdline-tools\cmdline-tools latest
```

Hasil akhirnya harus ada file `C:\Android\cmdline-tools\latest\bin\sdkmanager.bat`.

### 5c. Environment variable

```powershell
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android", "User")
```
```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools", "User")
```

**Restart VS Code.**

### 5d. Install komponen SDK

Ketik `y` saat diminta menyetujui lisensi.

```powershell
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

> Kalau muncul error versi tidak ditemukan, lihat versi yang tersedia dengan `sdkmanager --list`. Versi lain yang dibutuhkan project akan diunduh otomatis oleh Gradle saat build pertama.

### 5e. Hubungkan ke Flutter

```powershell
flutter config --android-sdk C:\Android
```
```powershell
flutter config --jdk-dir "$env:JAVA_HOME"
```
```powershell
flutter doctor --android-licenses
```

Ketik `y` untuk semua lisensi.

---

## Langkah 6 — .NET SDK 10 (untuk backend)

```powershell
winget install Microsoft.DotNet.SDK.10
```

Restart VS Code, lalu cek:

```powershell
dotnet --version
```

Harus muncul `10.…`.

---

## Langkah 7 — Identitas Git

Ganti dengan nama dan email akun GitHub kamu:

```powershell
git config --global user.name "Nama Kamu"
```
```powershell
git config --global user.email "email@kamu.com"
```

---

## Langkah 8 — Cek semuanya

```powershell
flutter doctor
```

Yang **harus** centang hijau:

```
[✓] Flutter
[✓] Windows Version
[✓] Android toolchain
[✓] Chrome - develop for the web
```

Yang **boleh diabaikan**:

- `[✗] Android Studio`: kita tidak memakainya
- `[✗] Visual Studio`: hanya dibutuhkan untuk build aplikasi desktop Windows (nanti)

Kalau Chrome tidak terpasang, web bisa dijalankan di Microsoft Edge.

---

## Langkah 9 — Sambungkan HP Android

### 9a. Aktifkan Developer options di HP

- **Umum:** Settings → About phone → tap **Build number** 7 kali
- **Samsung:** Settings → About phone → Software information → **Build number**
- **Xiaomi/Redmi/POCO:** Settings → About phone → tap **MIUI/HyperOS version** 7 kali

### 9b. Nyalakan USB debugging

Settings → (System →) **Developer options** → **USB debugging** ON.

Khusus Xiaomi: nyalakan juga **Install via USB** dan **USB debugging (Security settings)**.

### 9c. Colok ke laptop

1. Pakai **kabel data** (beberapa kabel hanya bisa untuk charge).
2. Di HP muncul *"Allow USB debugging?"* → centang **Always allow from this computer** → **Allow**.
3. Cek di terminal:

```powershell
adb devices
```

Harus muncul serial HP dengan status `device`. Kalau `unauthorized`, cabut lalu colok lagi dan setujui pop-up di HP.

```powershell
flutter devices
```

### Alternatif: tanpa kabel (Android 11+)

HP dan laptop harus di jaringan WiFi yang sama.

1. Developer options → **Wireless debugging** ON → **Pair device with pairing code**.
2. Di laptop (pakai IP:port dan kode yang tampil di HP):

```powershell
adb pair 192.168.1.10:37000
```

3. Lalu connect ke IP:port yang tampil di layar utama Wireless debugging (port-nya **berbeda** dari port pairing):

```powershell
adb connect 192.168.1.10:41000
```

---

## Langkah 10 — Uji coba aplikasi pertama

Buat project percobaan:

```powershell
flutter create C:\dev\coba_flutter
```
```powershell
code C:\dev\coba_flutter
```

Di jendela VS Code yang baru:

1. Klik nama device di **status bar kanan bawah** (atau `Ctrl+Shift+P` → **Flutter: Select Device**) → pilih HP kamu.
2. Buka `lib/main.dart`, tekan **F5**.
3. Build pertama butuh **5–15 menit** karena Gradle mengunduh banyak dependensi. Build berikutnya jauh lebih cepat.
4. Aplikasi counter muncul di HP.

**Coba hot reload:** di `lib/main.dart` ganti `Colors.deepPurple` menjadi `Colors.green`, lalu simpan (`Ctrl+S`). Tampilan di HP berubah dalam sekitar 1 detik tanpa restart.

**Coba versi web:** pilih **Chrome** di device selector, lalu tekan **F5**.

Kalau semuanya berhasil, folder `C:\dev\coba_flutter` boleh dihapus.

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `flutter`/`sdkmanager`/`adb` *is not recognized* | Tutup **semua** jendela VS Code lalu buka lagi. Cek PATH: `$env:Path -split ';'` |
| *Building with plugins requires symlink support* | Aktifkan Developer Mode (Langkah 2) |
| Error Gradle soal versi Java / *Unsupported class file major version* | Pastikan `java -version` = 17, lalu `flutter config --jdk-dir "$env:JAVA_HOME"` |
| *Android license status unknown* | `flutter doctor --android-licenses` |
| HP tidak muncul di `adb devices` | Ganti kabel, cek USB debugging, lalu `adb kill-server` dan `adb start-server`. HP Samsung mungkin butuh *Samsung USB Driver*. |
| Build pertama sangat lama atau seperti macet | Normal untuk build pertama. Pastikan internet stabil dan tunggu. |
