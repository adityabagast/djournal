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

- Ukuran layar ponsel: lebar **390**, tinggi 844 (boleh lebih untuk halaman panjang). Jarak antar frame 80 px (x += 470), antar baris 120 px + judul.
- Penomoran judul: `"NN Nama layar"` melanjutkan nomor terakhir (saat ini terakhir **33 Pengaturan › Warna aksen kustom**).
- Baris (y frame): Pembuka 0 · Tab utama 1244 · Sub-halaman 3204 · Form & sheet 5164 · Cek update 6564 · Permainan 7808 · Desktop (Windows) 9228, frame 1280 lebar.
  Judul baris = note `kind: "title1"`; perbarui `maxW` bila baris bertambah panjang.
- Artboard yang bisa diklik diberi `"is_interactive": true`.

## Daftar artboard (per 2026-11-03)

00 Maskot, 00 Design system · 01 Splash, 02 Kunci PIN, 03 Atur PIN · 04 Hari Ini, 05 Jurnal, 06 Keuangan, 07 Laporan ·
08 Pencarian, 09 Pengaturan, 10 Masuk Akun, 11 Kelola dompet, 12 Kelola kategori, 13 Budget,
33 Pengaturan › Warna aksen kustom (`AccentCustom.dc.html`, x 2820 di baris Sub-halaman — sudah diimplementasi di `app/lib/features/settings/presentation/custom_accent_sheet.dart`) ·
14 Tambah cepat, 15 Catat transaksi, 16 Tulis jurnal, 17 Catatan suara, 18 Detail tagihan, 19 Tagihan baru, 20 Impian baru,
21 Tambah tabungan, 22 Target budget global, 23 Ubah dompet, 24 Streak, 27 Permainan (hub, `Games.dc.html`), 28 Roda putar & suit (`Spin.dc.html`), 29 Memory kartu, 30 Kocok pertanyaan (semua sudah diimplementasi di `app/lib/features/games/`) ·
25 Banner versi baru, 26 Pengaturan › Tentang ·
31 Desktop · aplikasi penuh (`Desktop.dc.html`, 1280×820), 32 Desktop · jendela mini vs widget (`DesktopMini.dc.html`) — belum diimplementasi.

## Aturan data di prototipe

Pakai data dummy saja (lihat AGENTS.md §3) — jangan memasukkan isi jurnal, nominal, atau email asli user ke artboard.
