# Design Canvas Nyawtat — Panduan untuk AI Agent

Semua prototipe UI Nyawtat **dilanjutkan di satu canvas Claude Design**, bukan di file `docs/*-prototype/index.html` baru.
Folder `docs/*-prototype/` lama hanya arsip.

- **Canvas:** https://claude.ai/artifact/XL1VqmFK6psaUQECnsgm6H — "Nyawtat Semua Halaman"
- **Status akses:** privat (hanya pemilik). Agent tanpa akses ke artifact claude.ai **tidak bisa** membaca/menulis canvas → ikuti "Jalur B".
- Folder ini berisi salinan referensi (bukan sumber kebenaran): `project/canvas.json`, beberapa artboard contoh, dan `nyawtat-tokens.css` (CSS bersama).

## Alur wajib (lihat AGENTS.md §1)

1. Fitur baru / perubahan UI → buat atau ubah **artboard** di canvas.
2. User mencoba (Play) dan menyetujui.
3. Baru implementasi ke Flutter (`app/`).

## Jalur A — agent punya Artifact tool claude.ai (Claude Code)

1. `read` `project/canvas.json` + artboard yang mau diubah/ditiru dari canvas (selalu versi terbaru, jangan pakai salinan di folder ini).
2. Edit/buat file di satu folder `<root>/project/…`, lalu publish ke `url` canvas dengan `root`, `file_path`, `files`.
3. Kirim `canvas.json` hanya jika menambah/memindah artboard atau mengubah notes.
4. Publish ditolak karena versi baru → `read` ulang, ulangi edit, publish lagi. Jangan pakai `force`.
5. Ikuti aturan type canvas: jangan verifikasi dengan browser/screenshot kecuali user minta.

## Jalur B — agent tanpa akses canvas (Gemini, dll.)

1. Tulis artboard baru sebagai file `.dc.html` di `docs/design-canvas/project/<Nama>.dc.html` dengan format di bawah (contoh lengkap: `project/Spin.dc.html`).
2. Tambahkan entri di salinan `project/canvas.json` (boards + order) sesuai tata letak di bawah.
3. Minta user menyuruh Claude Code: *"upload artboard `docs/design-canvas/project/<Nama>.dc.html` ke canvas"*.
4. Jangan buat prototipe HTML terpisah dengan gaya lain.

## Format artboard (`.dc.html`)

- Kerangka: `<!doctype html>` → `<head>` dengan `<script src="./support.js"></script>` **persis**, lalu
  `<link rel="stylesheet" href="/_blob/dd28f63f6270c6ede0c32193cdae89b5">` (CSS bersama = `nyawtat-tokens.css`).
- `<body><x-dc><helmet>` berisi font Poppins (Google Fonts `css2`) + `<style>` khusus layar, lalu root:
  `<div class="ph {{mode}}" style="height: 844px; --hero: {{hero}}; --primary: {{primary}}; --onprimary: {{onprimary}}; --psoft: {{psoft}}; --onpsoft: {{onpsoft}}">`.
- Logika: `<script type="text/x-dc" data-dc-script data-props='…'>` dengan `class Component extends DCLogic { renderVals() { … } }`
  (JS klasik, tanpa import). Salin blok `accent` + `dark` + fungsi `m()` dari artboard mana pun agar tema & aksen konsisten.
- `{{hole}}` hanya lookup bertitik ke hasil `renderVals()`, bukan ekspresi. Loop `<sc-for list="{{x}}" as="i" hint-placeholder-count="3">`,
  kondisi `<sc-if value="{{c}}" hint-placeholder-val="{{true}}">`, event `onClick="{{fn}}"`, state via `this.state`/`setState`.
- Semua UI berupa markup, jangan `innerHTML`/`appendChild`. Tanpa emoji; ikon = SVG garis inline (`stroke` 1.8, `viewBox 0 0 24 24`).
- Pindah layar: `<a href="Today.dc.html">` (path relatif ke artboard lain).
- Aksesibilitas: `<button>`/`<a>`/`<input>`+`<label>` asli, `aria-label` di tombol ikon, target sentuh ≥ 44 px.

- **Gaya bersama ditaruh di dalam tiap artboard** (blok "Nyawtat: aturan bersama" di `<style>` helmet). Artboard baru: salin blok itu dari artboard lain, misalnya `Search.dc.html`. Jangan mengganti blob CSS: pernah dicoba 2026-11-23 dan semua layar kehilangan gaya di canvas.
- Tulis aturan khusus layar dengan awalan `.ph ` (mis. `.ph .kartu{…}`), karena reset `.ph a, .ph button` menghapus padding, latar, dan ukuran huruf kelas tanpa awalan itu.
- Gabungkan angka dan satuannya dalam satu lubang (`{{pctText}}`, bukan `{{pct}}%`): di flex/grid keduanya jadi item terpisah.

### Kelas siap pakai (dari `nyawtat-tokens.css`)

`body` `hdr` `ib` `card` `ch` `h3` `sm` `big` `btn` (`sm` `soft` `ghost` `block`) `seg` (`button.on`) `chip`/`chips` `state ok|warn|bad`
`li` `av` `tx` `amt exp|inc` `track`/`fill` `fld`/`inp` `sheet`/`grip`/`veil` `qa` `dock` `mascot` `tgl` `set` `ghostcard`.
Token warna: `--bg --surface --ink --muted --line --track --subtle --expense --income --warning --warnsoft --dangersoft --blue --flame`
(+ versi gelap otomatis lewat `.ph.dark`).

### Gambar maskot (blob di canvas)

| Pose | URL |
|---|---|
| Halo / melambai | `/_blob/ba41d0d5a61f52bdac32a385f520f688` |
| Senang | `/_blob/f54a42e79eddb361c11f6f6e9324cbf6` |

Pose lain (menulis, koin, sedih, tidur, gembok, mencari, sinkron) ada di artboard `Mascot.dc.html`; sumber SVG di `app/assets/mascot/`.
Blob hanya tampil di dalam canvas.

## Tata letak canvas

Canvas punya 4 halaman (`pages`). Hanya halaman **Alur aplikasi** (`alur`) yang ikut Play.

| Halaman | Isi |
|---|---|
| `alur` · Alur aplikasi | semua layar app yang berlaku sekarang, urut sesuai pemakaian |
| `desktop` · Desktop | layar Windows (belum diimplementasi) |
| `sistem` · Sistem desain | maskot, design system, token UI |
| `arsip` · Arsip & usulan | prototipe lama, perbandingan sebelum/sesudah, dan usulan yang ditunda |

Aturan halaman `alur`:

- **Play dimulai dari 1.1 Splash.** Setiap layar harus bisa dicapai dari Splash dan bisa kembali ke Hari Ini lewat tautan; jangan menautkan ke halaman `arsip`.
- Semua layar **390 × 844** (`radius` 36) seperti HP; isi panjang digulir di dalam `.body`, dock tetap di bawah. Salin 4 baris CSS ini ke akhir `<style>` artboard:
  `.ph .body{height:844px;overflow-y:auto;scrollbar-width:none}` · `.ph .body::-webkit-scrollbar{display:none}` · `.ph .body>*{flex-shrink:0}` · `.ph .sheet{max-height:92%;overflow-y:auto}`
- Satu baris per bagian app; jarak antar frame 80 px (x += 470), antar baris y += 1264. Judul baris = note `title1` (y baris − 300, `page: "alur"`).
- Judul artboard = `"<baris>.<urutan> <nama>"`. Layar baru masuk di baris bagiannya, di urutan paling kanan.
- Layar yang perlu berbagi state (mis. centang rencana) digabung dalam **satu** artboard, karena state tiap artboard terpisah.
- Prototipe usulan baru boleh mulai di `arsip`; setelah disetujui, pindahkan atau gabungkan ke `alur`.

## Daftar artboard (per 2026-11-25)

1. **Buka aplikasi:** 1.1 Splash (`Main`), 1.2 Kunci PIN (`Lock`)
2. **Hari Ini:** 2.1 Hari Ini + rencana harian (`Today`), 2.2 Streak, 2.3 Pencarian (`Search`), 2.4 Target budget (`GlobalBudget`), 2.5 Detail tagihan (`BillDetail`), 2.6 Tagihan baru (`BillForm`), 2.7 Impian baru (`WishForm`), 2.8 Tambah tabungan (`Deposit`)
3. **Tambah cepat:** 3.1 Tambah cepat (`Quick`), 3.2 Catat transaksi (`TxForm`), 3.3 Catatan jurnal, baca + tulis + transaksi (`EntryForm`), 3.4 Catatan suara (`Voice`), 3.5 Pengingat dari jurnal (`Reminder`)
4. **Jurnal:** 4.1 Jurnal (`Journal`)
5. **Keuangan:** 5.1 Keuangan + kalender (`MoneyCalendar`), 5.2 Kelola dompet (`Wallets`), 5.3 Ubah dompet (`WalletForm`)
6. **Laporan:** 6.1 Laporan (`Report`), 6.2 Budget per kategori (`Budget`)
7. **Permainan:** 7.1 Permainan (`Games`), 7.2 Roda putar & suit (`Spin`), 7.3 Memory kartu (`Memory`), 7.4 Kocok pertanyaan (`Prompt`)
8. **Pengaturan:** 8.1 Pengaturan (`Settings`), 8.2 Warna aksen kustom (`AccentCustom`), 8.3 Atur PIN (`PinSetup`), 8.4 Kelola kategori (`Categories`), 8.5 Masuk akun (`SignIn`), 8.6 Tentang & cek update (`UpdateSettings`), 8.7 Banner versi baru (`UpdateBanner`), 8.8 Kirim masukan (`Feedback`), 8.9 Riwayat versi (`VersionHistory`)

- **Desktop:** D.1 Aplikasi penuh (`Desktop`, 1280×820), D.2 Jendela mini vs widget (`DesktopMini`) — belum diimplementasi
- **Sistem desain:** S.1 Maskot, S.2 Design system, S.3 Token UI Fase 1, S.4 Usulan token Fase 2
- **Arsip:** A.1 Rencana besok (`DailyPlan`, prototipe awal), A.2 Keuangan lama (`Money`), A.3 Judul otomatis (`JournalAutoTitle`), A.4 Kirim masukan dalam app (`FeedbackInApp`, ditunda), A.5 Jurnal gaya buku notes (`JournalBook`, tidak dipilih), A.6 Tulis jurnal lama (`EntryFormOld`)

Semua layar 1–8 sudah diimplementasi di `app/`.

## Aturan data di prototipe

Pakai data dummy saja (lihat AGENTS.md §3) — jangan memasukkan isi jurnal, nominal, atau email asli user ke artboard.
