// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Nyawtat';

  @override
  String get splashTagline => 'jurnal & catatan uang';

  @override
  String get navToday => 'Hari Ini';

  @override
  String get navJournal => 'Jurnal';

  @override
  String get navMoney => 'Keuangan';

  @override
  String get navReport => 'Laporan';

  @override
  String get add => 'Tambah';

  @override
  String get back => 'Kembali';

  @override
  String get cancel => 'Batal';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get today => 'Hari ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String get comingSoon => 'Segera hadir di fase berikutnya.';

  @override
  String get todaySpent => 'Pengeluaran hari ini';

  @override
  String monthSpent(String amount) {
    return 'Bulan ini $amount';
  }

  @override
  String get record => 'Catat';

  @override
  String get todayTimeline => 'Timeline hari ini';

  @override
  String get write => 'Tulis';

  @override
  String get timelineEmpty =>
      'Belum ada catatan hari ini. Tulis jurnal atau catat transaksi pertamamu.';

  @override
  String get totalBalance => 'Total saldo';

  @override
  String get income => 'Pemasukan';

  @override
  String get expense => 'Pengeluaran';

  @override
  String get net => 'Selisih';

  @override
  String get wallets => 'Dompet';

  @override
  String get addWallet => 'Tambah dompet';

  @override
  String get filterAll => 'Semua';

  @override
  String get noTransactions => 'Belum ada transaksi.';

  @override
  String get addTxTitle => 'Catat Transaksi';

  @override
  String get editTxTitle => 'Edit Transaksi';

  @override
  String get amount => 'Nominal';

  @override
  String get amountRequired => 'Isi nominal dulu ya.';

  @override
  String get category => 'Kategori';

  @override
  String get wallet => 'Dompet';

  @override
  String get time => 'Waktu';

  @override
  String get note => 'Catatan';

  @override
  String get noteHint => 'Contoh: makan siang di kantin';

  @override
  String get saveTx => 'Simpan transaksi';

  @override
  String get transferFrom => 'Dari';

  @override
  String get transferTo => 'Ke';

  @override
  String walletBalance(String amount) {
    return 'Saldo $amount';
  }

  @override
  String get swapWallets => 'Tukar dompet asal dan tujuan';

  @override
  String transferOverdraw(String wallet) {
    return 'Saldo $wallet kurang dari nominal. Tetap bisa disimpan.';
  }

  @override
  String get transferNeedsTwoWallets => 'Transfer butuh minimal 2 dompet.';

  @override
  String get saveTransfer => 'Simpan transfer';

  @override
  String get transferNoteHint => 'Contoh: tarik tunai di ATM';

  @override
  String get toastTransferSaved => 'Transfer tersimpan';

  @override
  String get deleteTxConfirm => 'Hapus transaksi ini?';

  @override
  String get quickAdd => 'Tambah cepat';

  @override
  String get quickAddTx => 'Catat transaksi';

  @override
  String get quickAddTxSub => 'Pengeluaran, pemasukan, atau transfer';

  @override
  String get quickAddJournal => 'Tulis jurnal';

  @override
  String get quickAddJournalSub => 'Cerita baru, jam dan mood opsional';

  @override
  String get reportByCategory => 'Pengeluaran per kategori';

  @override
  String get reportEmpty => 'Belum ada pengeluaran bulan ini.';

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get appearance => 'Tampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeSystemHint =>
      'Mengikuti mode gelap di pengaturan HP. Widget layar utama ikut juga.';

  @override
  String get themeLightHint =>
      'Selalu terang, apa pun pengaturan HP. Widget layar utama ikut juga.';

  @override
  String get themeDarkHint =>
      'Selalu gelap, apa pun pengaturan HP. Widget layar utama ikut juga.';

  @override
  String get accentTitle => 'Warna aksen';

  @override
  String get accentHint =>
      'Dipakai untuk tombol, ikon aktif, dan kartu Total saldo. Berlaku di mode terang dan gelap.';

  @override
  String get accentSage => 'Hijau sage';

  @override
  String get accentOcean => 'Biru laut';

  @override
  String get accentViolet => 'Ungu';

  @override
  String get accentRose => 'Mawar';

  @override
  String get accentPink => 'Pink';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentCustom => 'Kustom';

  @override
  String get accentCustomA11y => 'Warna kustom, pilih sendiri';

  @override
  String accentCustomHint(String hex) {
    return 'Kustom $hex · ketuk Kustom lagi untuk mengubah. Warna pemasukan dan pengeluaran tetap.';
  }

  @override
  String get accentCustomTitle => 'Warna kustom';

  @override
  String get accentCustomSub => 'Geser untuk memilih, atau ketik kode hex.';

  @override
  String get accentHue => 'Warna';

  @override
  String get accentSaturation => 'Kepekatan';

  @override
  String get accentLightness => 'Kecerahan';

  @override
  String get accentHexLabel => 'Kode hex';

  @override
  String get accentHexError => 'Format: #RRGGBB, mis. #1F5F4E';

  @override
  String get accentRecent => 'Terakhir dipakai';

  @override
  String get accentPreviewChip => 'Terpilih';

  @override
  String get accentNoteGrey =>
      'Warna ini hampir abu-abu, jadi aksen kurang menonjol dibanding warna lain.';

  @override
  String get accentNoteLight =>
      'Warna cukup terang. Di mode terang tombol dibuat sedikit lebih gelap supaya teksnya tetap terbaca.';

  @override
  String get accentNoteDark =>
      'Warna sangat gelap. Di mode terang tombol dibuat sedikit lebih terang supaya tetap terlihat berwarna.';

  @override
  String get accentApply => 'Pakai warna';

  @override
  String get currency => 'Mata uang';

  @override
  String get currencyValue => 'Rupiah (IDR)';

  @override
  String versionLabel(String version) {
    return 'Nyawtat · versi $version';
  }

  @override
  String get walletName => 'Nama dompet';

  @override
  String get walletNameHint => 'Contoh: BCA, GoPay';

  @override
  String get walletType => 'Jenis';

  @override
  String get walletTypeCash => 'Tunai';

  @override
  String get walletTypeBank => 'Bank';

  @override
  String get walletTypeEwallet => 'E-wallet';

  @override
  String get walletTypeOther => 'Lainnya';

  @override
  String get openingBalance => 'Saldo awal';

  @override
  String get walletNameRequired => 'Isi nama dompet dulu ya.';

  @override
  String get editWallet => 'Ubah dompet';

  @override
  String get deleteWallet => 'Hapus dompet';

  @override
  String deleteWalletConfirm(String name) {
    return 'Hapus dompet $name?';
  }

  @override
  String deleteWalletTxWarning(int count) {
    return '$count transaksi di dompet ini juga ikut terhapus.';
  }

  @override
  String get lastWalletCantDelete => 'Dompet terakhir tidak bisa dihapus.';

  @override
  String get catFood => 'Makan';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Belanja';

  @override
  String get catBills => 'Tagihan';

  @override
  String get catEntertainment => 'Hiburan';

  @override
  String get catOther => 'Lainnya';

  @override
  String get catSalary => 'Gaji';

  @override
  String get catBonus => 'Bonus';

  @override
  String get catOtherIncome => 'Lainnya';

  @override
  String get moodAwful => 'Buruk';

  @override
  String get moodBad => 'Kurang';

  @override
  String get moodOkay => 'Biasa';

  @override
  String get moodGood => 'Baik';

  @override
  String get moodGreat => 'Senang';

  @override
  String get journalEmpty =>
      'Belum ada entri jurnal. Mulai tulis cerita pertamamu.';

  @override
  String get showAllEntries => 'Tampilkan semua';

  @override
  String get journalDayEmptyTitle => 'Belum ada entri';

  @override
  String get journalDayEmptyBody => 'Tidak ada catatan di tanggal ini.';

  @override
  String get writeForThisDay => 'Tulis di tanggal ini';

  @override
  String get prevWeek => 'Minggu sebelumnya';

  @override
  String get nextWeek => 'Minggu berikutnya';

  @override
  String dayMoodSummary(String mood) {
    return 'Mood $mood';
  }

  @override
  String get noSpending => 'tanpa pengeluaran';

  @override
  String get untitled => 'Tanpa judul';

  @override
  String get newEntryTitle => 'Tulis Entri';

  @override
  String get editEntryTitle => 'Edit Entri';

  @override
  String get entryTime => 'Jam kejadian';

  @override
  String get optional => '(opsional)';

  @override
  String get now => 'Sekarang';

  @override
  String get clearTime => 'Hapus jam';

  @override
  String get pickTime => 'Pilih jam';

  @override
  String get mood => 'Mood';

  @override
  String get entryTitle => 'Judul';

  @override
  String get entryTitleHint => 'Satu kalimat tentang kejadian ini';

  @override
  String get story => 'Cerita';

  @override
  String get storyHint => 'Apa yang terjadi? Apa yang kamu rasakan?';

  @override
  String get tags => 'Tag';

  @override
  String get tagsHint => 'Pisahkan dengan koma, mis. teman, kerja';

  @override
  String get dayTransactions => 'Transaksi di hari ini';

  @override
  String get linkedByDate => 'Otomatis terhubung lewat tanggal.';

  @override
  String get entryEmptyError => 'Tulis judul atau cerita dulu ya.';

  @override
  String get deleteEntryConfirm => 'Hapus entri ini?';

  @override
  String get moodSpending => 'Mood & pengeluaran';

  @override
  String get avgGoodMood => 'Rata-rata saat mood baik';

  @override
  String get avgLowMood => 'Rata-rata saat mood kurang';

  @override
  String get noData => 'Belum ada data';

  @override
  String get insightNeedMore =>
      'Tulis jurnal dengan mood beberapa hari lagi untuk melihat polanya.';

  @override
  String get insightSpendWhenLow =>
      'Kamu cenderung belanja lebih banyak saat harimu kurang baik. Coba tunda belanja impulsif di hari-hari berat.';

  @override
  String get insightSpendWhenGood =>
      'Pengeluaranmu lebih besar di hari yang menyenangkan.';

  @override
  String get budget => 'Budget';

  @override
  String get budgetPerCategory => 'Budget per kategori';

  @override
  String get manage => 'Atur';

  @override
  String budgetUsage(String month, int pct, String left) {
    return 'Budget $month terpakai $pct% · sisa $left';
  }

  @override
  String budgetUsedPct(int pct) {
    return '$pct% terpakai';
  }

  @override
  String get widgetBalance => 'Saldo';

  @override
  String get widgetTodayOut => 'Keluar hari ini';

  @override
  String get widgetTodaySuffix => 'keluar hari ini';

  @override
  String get widgetJournalTitle => 'Jurnal hari ini';

  @override
  String widgetJournalSummary(int count, String time) {
    return '$count entri · terakhir $time';
  }

  @override
  String get widgetJournalEmptyTitle => 'Gimana harimu?';

  @override
  String get widgetJournalEmptySub => 'Belum ada cerita hari ini';

  @override
  String widgetBudgetOver(String month, String amount) {
    return 'Budget $month lewat $amount';
  }

  @override
  String overBudget(String amount) {
    return 'Lewat budget $amount';
  }

  @override
  String get noBudget => 'Tanpa budget';

  @override
  String get budgetLimit => 'Batas per bulan';

  @override
  String get budgetHint => 'Kosongkan untuk tanpa budget';

  @override
  String budgetAppliesFrom(String month) {
    return 'Berlaku mulai $month dan bulan-bulan berikutnya.';
  }

  @override
  String get budgetSubtitle => 'Atur batas pengeluaran bulanan per kategori';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get data => 'Data';

  @override
  String get account => 'Akun';

  @override
  String get signInPrompt =>
      'Masuk supaya data tersimpan di server dan bisa dipakai di beberapa perangkat.';

  @override
  String get signIn => 'Masuk';

  @override
  String get register => 'Daftar';

  @override
  String get signOut => 'Keluar';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Minimal 8 karakter';

  @override
  String get errConfirmEmail =>
      'Cek email kamu dan klik link konfirmasi, lalu masuk.';

  @override
  String get backendNotConfigured => 'Sinkronisasi belum diatur di build ini.';

  @override
  String get exportBackup => 'Ekspor backup';

  @override
  String get exportBackupSub => 'Semua data dalam satu file JSON';

  @override
  String get exportExcel => 'Ekspor ke Excel';

  @override
  String get exportExcelSub =>
      'Transaksi, jurnal, dompet, dan budget dalam satu file .xlsx';

  @override
  String get sheetTransactions => 'Transaksi';

  @override
  String get currentBalance => 'Saldo sekarang';

  @override
  String get spent => 'Terpakai';

  @override
  String get remaining => 'Sisa';

  @override
  String get importBackup => 'Impor backup';

  @override
  String get importBackupSub => 'Pulihkan data dari file backup';

  @override
  String importConfirm(String file) {
    return 'Impor $file?';
  }

  @override
  String get importConfirmBody =>
      'Isi file digabung dengan data yang ada. Tidak ada yang dihapus; kalau ada data yang sama, versi yang lebih baru yang dipakai.';

  @override
  String get importAction => 'Impor';

  @override
  String importDone(int imported, int skipped) {
    return '$imported data diimpor, $skipped sudah ada';
  }

  @override
  String get importInvalid => 'File ini bukan backup Nyawtat yang valid.';

  @override
  String get exportFailed => 'Gagal mengekspor data.';

  @override
  String get security => 'Keamanan';

  @override
  String get lockWithPin => 'Kunci dengan PIN';

  @override
  String get lockWithPinSub => 'Minta PIN saat app dibuka';

  @override
  String get unlockWithBiometric => 'Buka dengan biometrik';

  @override
  String get unlockWithBiometricSub => 'Sidik jari atau wajah';

  @override
  String get biometricUnavailable => 'Tidak tersedia di perangkat ini';

  @override
  String get lockNow => 'Kunci aplikasi sekarang';

  @override
  String get hideAmounts => 'Sembunyikan nominal';

  @override
  String get hideAmountsSub =>
      'Samarkan saldo dan nominal uang di seluruh aplikasi';

  @override
  String get enterPin => 'Masukkan PIN untuk membuka';

  @override
  String get wrongPin => 'PIN salah';

  @override
  String tooManyAttempts(int seconds) {
    return 'Terlalu banyak percobaan. Coba lagi dalam $seconds detik.';
  }

  @override
  String get useBiometric => 'Pakai biometrik';

  @override
  String get biometricReason => 'Buka Nyawtat';

  @override
  String get forgotPin => 'Lupa PIN?';

  @override
  String get forgotPinTitle => 'Reset PIN?';

  @override
  String get forgotPinBody =>
      'Kamu akan keluar dari akun dan data di HP ini dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.';

  @override
  String get forgotPinBodyLocal =>
      'Semua data di HP ini akan dihapus permanen karena kamu belum masuk ke akun (belum ada salinan di server).';

  @override
  String get resetPin => 'Reset';

  @override
  String get createPin => 'Buat PIN';

  @override
  String get createPinHint => 'Pilih 4 angka yang mudah kamu ingat';

  @override
  String get confirmPin => 'Ulangi PIN';

  @override
  String get confirmPinHint => 'Ketik PIN yang sama sekali lagi';

  @override
  String get pinMismatch => 'PIN tidak sama. Ulangi dari awal.';

  @override
  String get currentPin => 'PIN saat ini';

  @override
  String get currentPinHint => 'Masukkan PIN untuk melanjutkan';

  @override
  String get deleteDigit => 'Hapus digit';

  @override
  String get transfer => 'Transfer';

  @override
  String get csvDate => 'Tanggal';

  @override
  String get csvTime => 'Jam';

  @override
  String get csvType => 'Jenis';

  @override
  String get csvToWallet => 'Dompet tujuan';

  @override
  String get haveAccount => 'Sudah punya akun? Masuk';

  @override
  String get noAccount => 'Belum punya akun? Daftar';

  @override
  String get syncNow => 'Sinkronkan';

  @override
  String get syncing => 'Menyinkronkan…';

  @override
  String lastSynced(String time) {
    return 'Terakhir sinkron: $time';
  }

  @override
  String get neverSynced => 'Belum pernah sinkron';

  @override
  String get signOutBody =>
      'Data di perangkat ini akan dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.';

  @override
  String get signOutUnsynced =>
      'Ada perubahan yang belum tersinkron dan akan hilang kalau kamu keluar sekarang.';

  @override
  String get errNetwork =>
      'Tidak bisa terhubung ke server. Cek alamat server dan koneksi.';

  @override
  String get errInvalidCredentials => 'Email atau password salah.';

  @override
  String get errEmailTaken => 'Email ini sudah terdaftar. Coba masuk.';

  @override
  String get errInvalidEmail => 'Format email tidak valid.';

  @override
  String get errPasswordTooShort => 'Password minimal 8 karakter.';

  @override
  String get errSessionExpired => 'Sesi berakhir. Silakan masuk lagi.';

  @override
  String get errServer => 'Terjadi kesalahan di server. Coba lagi nanti.';

  @override
  String get mascotTodayEmptyTitle => 'Hai! Hari ini masih kosong';

  @override
  String get mascotJournalEmptyTitle => 'Belum ada catatan';

  @override
  String get mascotJournalEmptyBody =>
      'Tulis sedikit tentang harimu: mood, cerita, atau pengeluaran.';

  @override
  String get mascotWriteEntry => 'Tulis catatan';

  @override
  String get mascotTxEmptyTitle => 'Belum ada transaksi';

  @override
  String get mascotTxEmptyBody => 'Catat pemasukan atau pengeluaran pertamamu.';

  @override
  String get mascotRecordTx => 'Catat transaksi';

  @override
  String get mascotFilterEmptyTitle => 'Tidak ketemu';

  @override
  String get mascotFilterEmptyBody => 'Belum ada transaksi untuk filter ini.';

  @override
  String get mascotReportEmptyTitle => 'Belum ada data bulan ini';

  @override
  String get mascotReportEmptyBody =>
      'Laporan muncul setelah kamu mencatat pengeluaran.';

  @override
  String get mascotNoBudgetTitle => 'Belum ada budget';

  @override
  String get mascotNoBudgetBody =>
      'Atur budget supaya pengeluaranmu terpantau.';

  @override
  String get mascotBudgetOkTitle => 'Semua budget masih aman';

  @override
  String get mascotBudgetOkBody => 'Pertahankan sampai akhir bulan!';

  @override
  String mascotBudgetOverTitle(int count) {
    return '$count kategori lewat budget';
  }

  @override
  String mascotBudgetOverBody(String names) {
    return '$names. Coba rem sedikit, ya.';
  }

  @override
  String get toastEntrySaved => 'Catatan tersimpan';

  @override
  String get toastEntryUpdated => 'Catatan diperbarui';

  @override
  String get toastTxSaved => 'Transaksi tersimpan';

  @override
  String toastBudgetOver(String category) {
    return 'Budget $category terlewati';
  }

  @override
  String get toastSynced => 'Sinkron selesai';

  @override
  String get importMm => 'Impor dari Money Manager';

  @override
  String get importMmSub =>
      'File cadangan .mmbak atau ekspor .xlsx dari Money Manager (Realbyte)';

  @override
  String get importMmReading => 'Membaca file…';

  @override
  String importMmNew(int count) {
    return '$count transaksi baru';
  }

  @override
  String importMmBreakdown(int expense, int income, int transfer) {
    return '$expense pengeluaran · $income pemasukan · $transfer transfer';
  }

  @override
  String importMmPeriod(String from, String to) {
    return 'Periode: $from – $to';
  }

  @override
  String importMmAlready(int count) {
    return '$count transaksi sudah pernah diimpor, dilewati.';
  }

  @override
  String importMmSkipped(int count) {
    return '$count transfer ke dompet yang sama dilewati.';
  }

  @override
  String importMmAdjust(int count) {
    return '$count baris \"Edit saldo\" dimasukkan ke saldo awal dompet.';
  }

  @override
  String get importMmWallets => 'Dompet';

  @override
  String get importMmNewWallet => 'dompet baru';

  @override
  String importMmNewCategories(int count) {
    return 'Kategori baru ($count)';
  }

  @override
  String get importMmOverlap =>
      'Transaksi yang kamu catat sendiri di Nyawtat tidak dicocokkan. Setelah impor, cek tanggal yang tumpang tindih supaya tidak dobel.';

  @override
  String get importMmNothing => 'Tidak ada data baru di file ini.';

  @override
  String importMmDone(int count) {
    return '$count transaksi diimpor';
  }

  @override
  String get importMmInvalid =>
      'File tidak dikenali sebagai data Money Manager.';

  @override
  String get archiveWallet => 'Arsipkan dompet';

  @override
  String get unarchiveWallet => 'Keluarkan dari arsip';

  @override
  String get archiveWalletHint =>
      'Dompet arsip tidak tampil di daftar dan total saldo, tapi transaksinya tetap ada di riwayat dan laporan.';

  @override
  String archivedWalletsCard(int count) {
    return 'Arsip ($count)';
  }

  @override
  String get archivedWalletsTitle => 'Dompet diarsipkan';

  @override
  String get walletArchivedBadge => 'Diarsipkan';

  @override
  String get toastWalletArchived => 'Dompet diarsipkan';

  @override
  String get toastWalletUnarchived => 'Dompet dikeluarkan dari arsip';

  @override
  String get importMmArchived => 'diarsipkan';

  @override
  String importMmMoved(int count) {
    return '$count transaksi yang sudah diimpor dipindah ke dompet yang benar.';
  }

  @override
  String get currentBalanceHint =>
      'Kalau saldo diubah, selisihnya dicatat sebagai transaksi Lainnya.';

  @override
  String get balanceAdjustmentNote => 'Penyesuaian saldo';

  @override
  String get manageWallets => 'Kelola dompet';

  @override
  String get manageAction => 'Kelola';

  @override
  String get activeWallets => 'Aktif';

  @override
  String walletsTotal(int count) {
    return 'Total saldo $count dompet aktif';
  }

  @override
  String walletTxCount(int count) {
    return '$count transaksi';
  }

  @override
  String archivedWalletLine(int count, String amount) {
    return '$count transaksi · saldo $amount';
  }

  @override
  String get unarchiveShort => 'Keluarkan';

  @override
  String get manageCategories => 'Kelola kategori';

  @override
  String get categoriesSub => 'Urutkan, sembunyikan, atau gabungkan kategori';

  @override
  String get categoryReorderHint =>
      'Tahan pegangan di kiri lalu geser untuk mengubah urutan. Urutan ini juga dipakai di form catat transaksi.';

  @override
  String get categorySystemBadge => 'bawaan';

  @override
  String categoryBudgetMeta(String amount) {
    return 'budget $amount';
  }

  @override
  String hiddenCategoriesTitle(int count) {
    return 'Disembunyikan ($count)';
  }

  @override
  String get hiddenCategoriesHint =>
      'Tidak muncul di form catat transaksi. Transaksi lamanya tetap memakai kategori ini.';

  @override
  String get noHiddenCategories => 'Belum ada kategori yang disembunyikan.';

  @override
  String get showCategory => 'Tampilkan';

  @override
  String get newExpenseCategory => 'Kategori pengeluaran baru';

  @override
  String get newIncomeCategory => 'Kategori pemasukan baru';

  @override
  String get editCategory => 'Ubah kategori';

  @override
  String get categoryName => 'Nama kategori';

  @override
  String get categoryNameHint => 'Contoh: Kuota, Admin bank';

  @override
  String get categoryNameRequired => 'Isi nama kategori dulu ya.';

  @override
  String get systemCategoryNameNote =>
      'Nama kategori bawaan mengikuti bahasa app.';

  @override
  String get categoryColor => 'Warna';

  @override
  String get hideFromForm => 'Sembunyikan dari form';

  @override
  String get showInForm => 'Tampilkan lagi di form';

  @override
  String get mergeCategory => 'Gabungkan ke kategori lain…';

  @override
  String mergeCategoryTitle(String name) {
    return 'Gabungkan $name ke…';
  }

  @override
  String mergeCategoryHint(int count, String name) {
    return '$count transaksi akan dipindah, lalu kategori $name dihapus.';
  }

  @override
  String get mergeConfirmTitle => 'Gabungkan kategori?';

  @override
  String mergeConfirmBody(int count, String from, String to) {
    return '$count transaksi di $from akan dipindah ke $to, lalu $from dihapus. Ini tidak bisa dibatalkan.';
  }

  @override
  String get mergeAction => 'Gabungkan';

  @override
  String get deleteCategory => 'Hapus kategori';

  @override
  String get deleteSystemCategoryHint =>
      'Kategori bawaan tidak bisa dihapus, tapi bisa disembunyikan.';

  @override
  String deleteUsedCategoryHint(int count) {
    return 'Masih dipakai $count transaksi. Gabungkan dulu ke kategori lain.';
  }

  @override
  String get toastCategorySaved => 'Kategori tersimpan';

  @override
  String toastCategoryHidden(String name) {
    return '$name disembunyikan';
  }

  @override
  String toastCategoryShown(String name) {
    return '$name ditampilkan lagi';
  }

  @override
  String toastCategoryMerged(String from, String to) {
    return '$from digabung ke $to';
  }

  @override
  String get toastCategoryDeleted => 'Kategori dihapus';

  @override
  String get categoryIcon => 'Ikon';

  @override
  String get categoryIconNone => 'Tanpa ikon (huruf awal)';

  @override
  String get iconFood => 'Makan';

  @override
  String get iconCoffee => 'Kopi';

  @override
  String get iconCar => 'Mobil';

  @override
  String get iconMotorbike => 'Motor';

  @override
  String get iconShopping => 'Belanja';

  @override
  String get iconBills => 'Tagihan';

  @override
  String get iconData => 'Kuota';

  @override
  String get iconEntertainment => 'Hiburan';

  @override
  String get iconHealth => 'Kesehatan';

  @override
  String get iconEducation => 'Pendidikan';

  @override
  String get iconGift => 'Hadiah';

  @override
  String get iconClothes => 'Pakaian';

  @override
  String get iconHome => 'Rumah';

  @override
  String get iconFriends => 'Teman';

  @override
  String get iconCharity => 'Sedekah';

  @override
  String get iconSalary => 'Gaji';

  @override
  String get iconSavings => 'Tabungan';

  @override
  String get iconInvestment => 'Investasi';

  @override
  String get iconTravel => 'Perjalanan';

  @override
  String get search => 'Cari';

  @override
  String get searchHint => 'Cari jurnal, catatan, kategori, nominal…';

  @override
  String get clearText => 'Hapus teks';

  @override
  String get searchScopeAll => 'Semua';

  @override
  String get searchScopeTx => 'Transaksi';

  @override
  String get periodAll => 'Semua waktu';

  @override
  String get periodThisMonth => 'Bulan ini';

  @override
  String get periodThreeMonths => '3 bulan';

  @override
  String get recentSearches => 'Pencarian terakhir';

  @override
  String get clearRecentSearches => 'Hapus';

  @override
  String get trySearching => 'Coba cari';

  @override
  String searchCountEntries(int count) {
    return '$count jurnal';
  }

  @override
  String searchSumOut(String amount) {
    return 'keluar $amount';
  }

  @override
  String searchSumIn(String amount) {
    return 'masuk $amount';
  }

  @override
  String get searchNotFound => 'Tidak ketemu';

  @override
  String searchNotFoundBody(String query) {
    return 'Tidak ada jurnal atau transaksi yang cocok dengan \"$query\".';
  }

  @override
  String searchNotFoundPeriodBody(String query) {
    return 'Tidak ada jurnal atau transaksi yang cocok dengan \"$query\" di periode ini.';
  }

  @override
  String get voiceNote => 'Catatan suara';

  @override
  String get recordVoice => 'Rekam suara';

  @override
  String get recordAgain => 'Rekam ulang';

  @override
  String get recordingVoice => 'Merekam suara...';

  @override
  String get transcription => 'Transkripsi suara';

  @override
  String get copyToStory => 'Salin ke cerita';

  @override
  String get copiedToStory => 'Transkripsi disalin ke cerita';

  @override
  String get deleteVoiceConfirm => 'Hapus rekaman suara ini?';

  @override
  String get quickAddVoice => 'Catatan suara';

  @override
  String get quickAddVoiceSub => 'Rekam cerita & transkripsi otomatis';

  @override
  String get micPermissionRequired =>
      'Izin mikrofon diperlukan untuk merekam suara.';

  @override
  String get chartDistribution => 'Kategori';

  @override
  String get chartWeekly => 'Mingguan';

  @override
  String get chartExpenseAnalysis => 'Analisis Pengeluaran';

  @override
  String get chartExpenseByCategory => 'Distribusi Kategori';

  @override
  String get chartWeeklyTrend => 'Tren Mingguan';

  @override
  String chartAllCategories(int count) {
    return 'Semua kategori ($count)';
  }

  @override
  String get chartShowLess => 'Sembunyikan';

  @override
  String get chartAvgWeekly => 'Rata-rata/minggu';

  @override
  String chartHighestWeek(int week) {
    return 'Tertinggi: M$week';
  }

  @override
  String get prevMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get thisMonth => 'Bulan ini';

  @override
  String get totalExpense => 'Total Pengeluaran';

  @override
  String categoryCount(int count) {
    return '$count kategori';
  }

  @override
  String get googleDriveConnected => 'Terhubung';

  @override
  String get googleDriveNotConnected => 'Belum terhubung';

  @override
  String googleDriveLastBackup(String time) {
    return 'Cadangan terakhir: $time';
  }

  @override
  String get googleDriveNever => 'Belum pernah dicadangkan';

  @override
  String get googleDriveSheetsPreview => 'Pratinjau Sheets';

  @override
  String get googleSignIn => 'Masuk dengan Google';

  @override
  String get googleSignInPrompt =>
      'Masuk dengan akun Google untuk sinkronisasi otomatis ke Google Drive.';

  @override
  String get guestMode => 'Mode Tamu (Offline)';

  @override
  String get guestModePrompt =>
      'Masuk dengan Google atau Email server untuk mencadangkan data.';

  @override
  String get settingsApp => 'Aplikasi';

  @override
  String get settingsAppearance => 'Tampilan & bahasa';

  @override
  String get settingsFinanceSub => 'Dompet, kategori, budget';

  @override
  String get manageWalletsSub => 'Tambah, ubah saldo, arsip';

  @override
  String get settingsBackup => 'Cadangan & pemulihan';

  @override
  String get settingsBackupDriveSub => 'Google Drive, ekspor, impor';

  @override
  String get settingsBackupLocalSub => 'Ekspor dan impor file';

  @override
  String get settingsPinOn => 'PIN aktif';

  @override
  String get settingsPinBioOn => 'PIN dan biometrik aktif';

  @override
  String get settingsPinOff => 'PIN tidak aktif';

  @override
  String get settingsVersion => 'Versi & update';

  @override
  String get changePin => 'Ganti PIN';

  @override
  String get openBackup => 'Buka cadangan';

  @override
  String get serverTagOff => 'Belum masuk';

  @override
  String get driveNotConnected => 'Google Drive belum terhubung';

  @override
  String get backupRangeHint =>
      'Periode tabel yang tampil. Data pemulihan selalu lengkap.';

  @override
  String get disconnectDriveConfirm => 'Putuskan Google Drive?';

  @override
  String get disconnectDriveBody =>
      'Data di perangkat dan cadangan di Drive tetap ada. Login server tidak berubah.';

  @override
  String get stayConnected => 'Tetap terhubung';

  @override
  String get disconnect => 'Putuskan';

  @override
  String get backupFirst => 'Cadangkan dulu';

  @override
  String get signOutAck => 'Saya mengerti data di perangkat ini akan dihapus';

  @override
  String get signOutAndDelete => 'Keluar dan hapus data';

  @override
  String get serverName => 'Server Nyawtat';

  @override
  String get serverNotSignedIn => 'Belum masuk, data belum tersinkron';

  @override
  String serverAutoSynced(String time) {
    return 'Sinkron otomatis · terakhir $time';
  }

  @override
  String get connect => 'Hubungkan';

  @override
  String get retry => 'Coba lagi';

  @override
  String get serverSignInTitle => 'Masuk ke server';

  @override
  String get serverRegisterTitle => 'Daftar akun server';

  @override
  String get serverDriveStays =>
      'Google Drive tetap terhubung. Akun server terpisah dari akun Google.';

  @override
  String get serverDataScope =>
      'Dikirim ke server: jurnal (teks), transaksi, dompet, kategori, dan budget. Tagihan, impian, rencana, pengingat, lampiran, dan rekaman suara tetap hanya di perangkat ini.';

  @override
  String get googleDriveOnlyHint =>
      'Google hanya untuk cadangan Drive. Atau pakai server:';

  @override
  String get disconnectDrive => 'Putuskan Google Drive';

  @override
  String get disconnectDriveSub => 'Data di perangkat ini tetap ada';

  @override
  String get signOutServer => 'Keluar dari server';

  @override
  String get signOutServerSub => 'Data di perangkat ini akan dihapus';

  @override
  String get signOutServerConfirm => 'Keluar dari server?';

  @override
  String get signOutLocalOnly =>
      'Tagihan, impian, rencana, pengingat, lampiran, dan rekaman suara tidak ada di server dan akan hilang. Cadangkan dulu kalau masih dipakai.';

  @override
  String get rangeAll => 'Semua Riwayat';

  @override
  String get rangeThisYear => 'Tahun Ini';

  @override
  String get rangeThisMonth => 'Bulan Ini';

  @override
  String get rangeCustom => 'Rentang Kustom';

  @override
  String get rangeCustomFrom => 'Dari';

  @override
  String get rangeCustomTo => 'Sampai';

  @override
  String get backupNow => 'Cadangkan ke Drive';

  @override
  String get backupNowSuccess => 'Berhasil dicadangkan ke Google Drive!';

  @override
  String get backupNowLoading => 'Mengunggah ke Drive...';

  @override
  String get openInSheets => 'Buka di Sheets';

  @override
  String get restoreFromDrive => 'Pulihkan dari Drive';

  @override
  String get restoreFromDriveConfirm =>
      'Cadangan digabung ke data di perangkat. Catatan yang lebih baru di perangkat tidak ditimpa, dan akunmu tetap masuk.';

  @override
  String get restoreFromDriveSuccess =>
      'Data berhasil dipulihkan dari Google Drive!';

  @override
  String get localDataTitle => 'Penyimpanan Lokal';

  @override
  String get localBackup => 'Cadangkan Data (Ekspor)';

  @override
  String get localBackupSub =>
      'Simpan file Excel (.xlsx) atau Cadangan (.json) ke HP';

  @override
  String get localRestore => 'Pulihkan / Impor Data';

  @override
  String get localRestoreSub =>
      'Deteksi otomatis file Nyawtat atau Money Manager';

  @override
  String get formatExcel => 'Laporan Excel (.xlsx)';

  @override
  String get formatExcelDesc =>
      'Bisa dibuka, dianalisis, dan dicetak di Google Sheets / Microsoft Excel.';

  @override
  String get formatJson => 'File Cadangan Nyawtat (.json)';

  @override
  String get formatJsonDesc =>
      'Cadangan lengkap dengan relasi data untuk dipulihkan ke HP lain.';

  @override
  String get exportAction => 'Ekspor & Bagikan File';

  @override
  String get selectBackupFile => 'Pilih File Cadangan';

  @override
  String get selectBackupFileHint =>
      'Mendukung .json (Nyawtat) atau .mmbak / .sqlite / .xlsx (Money Manager)';

  @override
  String get unsupportedFileFormat =>
      'Format file tidak dikenali. Pilih file backup .json atau file Money Manager.';

  @override
  String get addSubcategory => 'Subkategori';

  @override
  String allOfCategory(String name) {
    return 'Semua $name';
  }

  @override
  String subcategoryCount(int count) {
    return '$count subkategori';
  }

  @override
  String newSubcategory(String parent) {
    return 'Subkategori baru di $parent';
  }

  @override
  String get editSubcategory => 'Ubah subkategori';

  @override
  String subcategoryColorNote(String parent) {
    return 'Warna mengikuti kategori $parent.';
  }

  @override
  String get greetingMorning => 'Selamat pagi!';

  @override
  String get greetingNoon => 'Selamat siang!';

  @override
  String get greetingAfternoon => 'Selamat sore!';

  @override
  String get greetingEvening => 'Selamat malam!';

  @override
  String greetingCount(int count) {
    return 'Sudah $count catatan hari ini. Mantap!';
  }

  @override
  String get greetingEmpty => 'Belum ada catatan hari ini. Yuk mulai!';

  @override
  String get journalPromptTitle => 'Pertanyaan hari ini';

  @override
  String get journalPromptAction => 'Tulis jawaban ›';

  @override
  String get journalPrompt1 => 'Apa hal kecil yang bikin kamu senyum hari ini?';

  @override
  String get journalPrompt2 => 'Apa yang paling kamu syukuri hari ini?';

  @override
  String get journalPrompt3 => 'Pengeluaran apa hari ini yang paling worth it?';

  @override
  String get journalPrompt4 => 'Apa yang ingin kamu lakukan lebih baik besok?';

  @override
  String get journalPrompt5 => 'Siapa yang membuat harimu lebih ringan?';

  @override
  String get updateAvailableTitle => 'Ada versi baru!';

  @override
  String updateAvailableBody(String version, String size) {
    return 'Nyawtat $version sudah tersedia$size. Datamu tetap aman saat update.';
  }

  @override
  String get updateDownload => 'Unduh';

  @override
  String get updateWhatsNew => 'Apa yang baru?';

  @override
  String get updateLater => 'Nanti saja';

  @override
  String updateDownloading(String version) {
    return 'Mengunduh $version…';
  }

  @override
  String updateDownloadProgress(String done, String total) {
    return '$done / $total · app tetap bisa dipakai';
  }

  @override
  String get updateCancel => 'Batalkan';

  @override
  String get updateReadyTitle => 'Siap dipasang!';

  @override
  String get updateReadyBody =>
      'File sudah dicek keasliannya. Pemasangan cuma butuh beberapa detik.';

  @override
  String get updateInstallNow => 'Pasang sekarang';

  @override
  String updateWhatsNewTitle(String version) {
    return 'Apa yang baru di $version';
  }

  @override
  String updateReleased(String date) {
    return 'Dirilis $date';
  }

  @override
  String get updateInstallHint =>
      'Diunduh di dalam app, lalu Android akan minta konfirmasi pemasangan. Pemasangan pertama minta izin \"Instal aplikasi tak dikenal\" untuk Nyawtat. Datamu tetap aman.';

  @override
  String get updateDownloadAndInstall => 'Unduh & pasang';

  @override
  String get updateOpenRelease => 'Buka halaman rilis';

  @override
  String get updateRemindLater => 'Ingatkan nanti';

  @override
  String get updateErrorNetwork =>
      'Gagal mengunduh. Periksa internet lalu coba lagi.';

  @override
  String get updateErrorChecksum =>
      'File update tidak cocok dengan rilis resmi, jadi tidak dipasang.';

  @override
  String get updateErrorPermission =>
      'Izinkan Nyawtat memasang aplikasi, lalu ketuk Pasang sekarang lagi.';

  @override
  String get updateErrorSource => 'File update bukan dari rilis resmi Nyawtat.';

  @override
  String get aboutTitle => 'Tentang';

  @override
  String aboutVersion(String version, String build) {
    return 'Versi $version ($build)';
  }

  @override
  String updateLastChecked(String when) {
    return 'Terakhir dicek: $when';
  }

  @override
  String get updateCheckNow => 'Cek update';

  @override
  String get updateChecking => 'Nyaw sedang mengecek…';

  @override
  String updateVersionAvailable(String version) {
    return 'Versi $version tersedia';
  }

  @override
  String get updateUpToDate => 'Sudah versi terbaru';

  @override
  String get updateCheckFailed => 'Gagal mengecek. Periksa koneksi internet.';

  @override
  String get updateAuto => 'Cek update otomatis';

  @override
  String get updateAutoSub => 'Sekali sehari saat ada internet';

  @override
  String get updatePrivacyNote =>
      'Nyawtat hanya membaca daftar rilis di GitHub. Tidak ada data pribadi yang dikirim.';

  @override
  String get aboutReleases => 'Riwayat versi';

  @override
  String get aboutReleasesSub => 'Apa yang berubah di tiap versi';

  @override
  String get historyMine => 'Versi kamu';

  @override
  String get historyUpdateHint => 'Perbarui untuk dapat fitur baru';

  @override
  String get historyView => 'Lihat';

  @override
  String get historyOffline =>
      'Riwayat ini tersimpan di dalam app dan bisa dibuka tanpa internet.';

  @override
  String get aboutTester => 'Jadi tester';

  @override
  String get aboutTesterSub => 'Dapat versi baru lebih dulu';

  @override
  String get updateSnoozed => 'Oke! Nyaw ingatkan lagi besok.';

  @override
  String get games => 'Permainan';

  @override
  String get gamesSub => 'Lagi penat? Rehat sebentar bareng Nyaw.';

  @override
  String get gameWheel => 'Roda putar';

  @override
  String get gameRps => 'Batu gunting kertas';

  @override
  String get gameWheelFood => 'Makan apa?';

  @override
  String get gameWheelDrink => 'Minum apa?';

  @override
  String get gameWheelYesNo => 'Ya / Tidak';

  @override
  String get gameWheelActivity => 'Mau ngapain?';

  @override
  String get gameWheelFoodDefaults =>
      'Nasi padang|Bakso|Mie ayam|Soto|Ayam geprek|Gado-gado';

  @override
  String get gameWheelDrinkDefaults => 'Kopi susu|Es teh|Jus alpukat|Air putih';

  @override
  String get gameWheelYesNoDefaults => 'Ya|Tidak';

  @override
  String get gameWheelActivityDefaults =>
      'Baca buku|Jalan sore|Nonton film|Tidur siang|Beres-beres';

  @override
  String get gameSpin => 'Putar';

  @override
  String get gameSpinAgain => 'Putar lagi';

  @override
  String get gameReady => 'Siap?';

  @override
  String get gameTapSpin => 'Ketuk Putar';

  @override
  String get gameSpinning => 'Muter… muter…';

  @override
  String get gameWait => 'Tunggu ya';

  @override
  String get gameNyawPicks => 'Nyaw pilih';

  @override
  String get gameRecordExpense => 'Catat pengeluaran';

  @override
  String get gameWheelItems => 'Isi roda';

  @override
  String gameWheelCount(int count, int max) {
    return '$count dari maks $max';
  }

  @override
  String get gameWheelAddHint => 'Tambah pilihan, mis. Bakso';

  @override
  String gameRemoveOption(String name) {
    return 'Hapus $name';
  }

  @override
  String get gameWheelColors => 'Warna roda';

  @override
  String get gameWheelPaletteRainbow => 'Pelangi';

  @override
  String get gameWheelPaletteAccent => 'Aksen';

  @override
  String get gameWheelPalettePastel => 'Pastel';

  @override
  String get gameWheelPaletteSunset => 'Senja';

  @override
  String get gameWheelPaletteOcean => 'Laut';

  @override
  String get gameWheelPaletteForest => 'Hutan';

  @override
  String get gameWheelPaletteCustom => 'Kustom';

  @override
  String get gameWheelCustomHint =>
      'Ketuk nomor irisan, lalu pilih warnanya. Warna berulang tiap 6 irisan.';

  @override
  String gameWheelSlot(int n) {
    return 'Warna irisan $n';
  }

  @override
  String gameWheelUseColor(String hex) {
    return 'Pakai warna $hex';
  }

  @override
  String get gameWheelOtherColor => 'Warna lain';

  @override
  String get gameWheelResetColors => 'Atur ulang';

  @override
  String get gameWheelColorsNote =>
      'Berlaku untuk semua roda. Di warna kustom, tulisan otomatis hitam/putih agar tetap terbaca.';

  @override
  String get gameYou => 'Kamu';

  @override
  String get gameRock => 'Batu';

  @override
  String get gameScissors => 'Gunting';

  @override
  String get gamePaper => 'Kertas';

  @override
  String get gamePickHand => 'Pilih tanganmu';

  @override
  String get gameCounting => 'Batu… gunting… kertas!';

  @override
  String get gameWin => 'Kamu menang!';

  @override
  String get gameLose => 'Nyaw menang';

  @override
  String get gameTie => 'Seri, coba lagi';

  @override
  String get gameTieLabel => 'Seri';

  @override
  String get gameScore => 'Skor';

  @override
  String get gameResetScore => 'Ulang';

  @override
  String get gameHubTitle => 'Rehat dulu, yuk';

  @override
  String get gameHubHint =>
      'Lagi penat? Main sebentar bareng Nyaw, nanti lanjut lagi.';

  @override
  String get gameHubFootnote =>
      'Skor dan rekor tersimpan di HP-mu saja, tidak ikut tersinkron.';

  @override
  String get gameRest => 'Rehat sebentar';

  @override
  String get gameRestAll => 'Semua permainan';

  @override
  String get gameShortWheel => 'Roda';

  @override
  String get gameShortRps => 'Suit';

  @override
  String get gameShortMemory => 'Kartu';

  @override
  String get gameShortPrompt => 'Kocok ide';

  @override
  String get gameWheelDesc => 'Bingung mau makan apa? Biar roda yang pilih.';

  @override
  String get gameRpsDesc => 'Adu hoki lawan Nyaw, skor dihitung.';

  @override
  String get gameMemory => 'Memory kartu';

  @override
  String get gameMemoryDesc => 'Cocokkan pasangan pose Nyaw.';

  @override
  String get gameMemorySub => 'Cocokkan 6 pasang pose Nyaw.';

  @override
  String gameMemoryRecord(int moves) {
    return 'Rekor $moves langkah';
  }

  @override
  String get gameMoves => 'Langkah';

  @override
  String get gamePairs => 'Pasangan';

  @override
  String get gameBest => 'Rekor';

  @override
  String gameMemoryDone(int moves) {
    return 'Selesai dalam $moves langkah';
  }

  @override
  String gameMemoryNewBest(int moves) {
    return 'Rekor baru: $moves langkah!';
  }

  @override
  String gameMemoryBestLine(int moves) {
    return 'Rekor terbaikmu $moves langkah.';
  }

  @override
  String get gamePlayAgain => 'Main lagi';

  @override
  String get gameReshuffle => 'Acak ulang';

  @override
  String gameCardClosed(int n) {
    return 'Kartu tertutup $n';
  }

  @override
  String get gameCardOpen => 'Kartu terbuka';

  @override
  String get gamePrompt => 'Kocok pertanyaan';

  @override
  String get gamePromptDesc => 'Bingung mau nulis apa? Ambil satu ide.';

  @override
  String get gamePromptLabel => 'Pertanyaan untukmu';

  @override
  String get gamePromptShuffle => 'Kocok lagi';

  @override
  String get gamePromptWrite => 'Tulis jawabannya';

  @override
  String get gamePromptNote =>
      'Pertanyaan dipakai sebagai judul jurnal baru, yang bisa kamu ubah. Tidak ada yang tersimpan sebelum kamu menekan Simpan.';

  @override
  String get gamePromptGratitude => 'Syukur';

  @override
  String get gamePromptReflection => 'Refleksi';

  @override
  String get gamePromptRelax => 'Santai';

  @override
  String get gamePromptDreams => 'Mimpi';

  @override
  String get gamePromptGratitudeList =>
      'Hal kecil apa yang bikin kamu senyum hari ini?|Siapa yang ingin kamu ucapkan terima kasih hari ini, dan kenapa?|Apa hal sederhana yang kamu syukuri minggu ini?|Makanan apa yang paling enak hari ini?|Siapa orang yang kehadirannya bikin harimu lebih ringan?|Apa yang tubuhmu bisa lakukan hari ini dan layak disyukuri?|Kejadian tak terduga apa yang ternyata menyenangkan hari ini?|Barang apa di sekitarmu yang diam-diam sangat membantu hidupmu?|Kebaikan kecil apa yang kamu terima dari orang lain baru-baru ini?|Tempat mana yang membuatmu merasa tenang, dan kenapa kamu bersyukur punya itu?|Apa satu hal dari pagi tadi yang berjalan lebih baik dari dugaanmu?|Siapa guru atau teman yang pelajarannya masih kamu bawa sampai sekarang?|Kenangan lama apa yang masih membuatmu hangat saat diingat?|Masalah apa yang dulu terasa berat, tapi sekarang sudah lewat?|Apa yang kamu punya sekarang yang dulu hanya angan-angan?|Suara, aroma, atau pemandangan apa yang paling kamu nikmati hari ini?|Kesempatan apa yang datang minggu ini dan ingin kamu hargai?|Apa kemudahan kecil yang sering kamu lupakan, seperti air bersih atau kasur empuk?|Siapa yang diam-diam mendukungmu tanpa kamu minta?|Apa yang kamu pelajari dari kesalahan terakhirmu dan layak disyukuri?|Apa bagian dari rutinitasmu yang sebenarnya kamu sukai?|Pujian atau kata baik apa yang terakhir kamu dengar?|Apa yang membuatmu merasa cukup hari ini?|Kalau harus menulis surat terima kasih untuk dirimu sendiri, apa isinya?';

  @override
  String get gamePromptReflectionList =>
      'Apa yang kamu pelajari hari ini?|Kalau diulang, apa yang ingin kamu lakukan beda hari ini?|Apa yang paling menguras energimu minggu ini?|Apa satu hal yang ingin kamu lepaskan?|Kapan terakhir kali kamu merasa benar-benar jadi dirimu sendiri?|Keputusan apa yang kamu tunda, dan apa yang membuatmu ragu?|Apa yang kamu hindari belakangan ini, dan kenapa?|Hal apa yang kamu lakukan hanya karena kebiasaan, bukan karena mau?|Apa yang sebenarnya kamu butuhkan sekarang, bukan sekadar inginkan?|Kata apa yang paling menggambarkan minggu ini, dan kenapa?|Kebiasaan kecil apa yang paling berpengaruh pada suasana hatimu?|Kapan kamu merasa paling bertenaga hari ini?|Percakapan apa yang masih terngiang di kepalamu?|Apa yang kamu sesali dan apa yang bisa kamu lakukan soal itu?|Batas apa yang perlu kamu tegaskan pada orang lain atau dirimu sendiri?|Apa yang membuatmu bangga bulan ini, sekecil apa pun?|Pekerjaan atau tugas apa yang terasa paling bermakna akhir-akhir ini?|Apa yang kamu cemaskan, dan seberapa besar kemungkinannya terjadi?|Kalau kamu menasihati dirimu setahun lalu, apa katamu?|Apa yang membuatmu merasa terburu-buru, dan apakah itu perlu?|Siapa yang perlu kamu hubungi atau mintai maaf?|Apa yang ingin kamu lakukan lebih sedikit mulai besok?|Pola apa yang kamu lihat saat uangmu terasa cepat habis?|Apa satu langkah kecil yang bisa kamu ambil minggu ini?';

  @override
  String get gamePromptRelaxList =>
      'Kalau hari ini sebuah lagu, judulnya apa?|Ceritakan satu obrolan lucu hari ini.|Kalau besok libur, kamu mau ke mana?|Apa yang bikin kamu tertawa terakhir kali?|Kalau hari ini sebuah film, genre dan judulnya apa?|Camilan apa yang paling pas menemani hari ini?|Kalau kamu punya satu jam kosong tanpa gangguan, mau diapakan?|Hewan apa yang paling menggambarkan suasana hatimu sekarang?|Warna apa yang cocok untuk harimu, dan kenapa?|Kalau bisa makan siang bersama siapa pun, kamu pilih siapa?|Apa kebiasaan anehmu yang diam-diam kamu sukai?|Lagu apa yang akhir-akhir ini sering kamu putar ulang?|Kalau kamu punya kekuatan super kecil tapi berguna, apa itu?|Tempat jajan favoritmu apa, dan pesananmu biasanya apa?|Ceritakan hal paling absurd yang kamu lihat minggu ini.|Kalau Nyaw bisa menemanimu seharian, kalian akan ngapain?|Apa hal paling nyaman yang bisa kamu lakukan saat hujan?|Kalau hidupmu punya soundtrack, lagu pembukanya apa?|Apa tontonan atau bacaan yang ingin kamu selesaikan?|Kalau kamu buka kedai kecil, kamu jual apa?|Kalau hari ini bebas anggaran tapi hanya boleh beli satu hal, apa yang kamu pilih?|Apa permainan masa kecil yang paling kamu rindukan?|Kalau besok bisa tidur sampai siang, mimpi apa yang kamu harap?|Apa yang membuat akhir pekan terasa seperti akhir pekan bagimu?';

  @override
  String get gamePromptDreamsList =>
      'Apa satu hal yang ingin kamu capai bulan ini?|Kalau uang bukan masalah, apa yang pertama kamu beli?|Kamu ingin jadi apa lima tahun lagi?|Apa kebiasaan baik yang ingin kamu mulai?|Keterampilan apa yang ingin kamu kuasai tahun ini?|Kota atau negara mana yang ingin kamu kunjungi, dan kenapa?|Seperti apa hari yang sempurna menurutmu, dari bangun sampai tidur?|Apa yang ingin kamu tabung, dan berapa lama kamu rela menunggu?|Kalau kamu bisa mengganti satu hal di hidupmu sekarang, apa itu?|Rumah seperti apa yang kamu impikan?|Proyek kecil apa yang ingin kamu mulai sebelum akhir tahun?|Siapa yang ingin kamu temui atau hubungi lagi?|Apa yang ingin kamu ajarkan pada orang lain suatu hari nanti?|Kalau gagal itu mustahil, apa yang akan kamu coba?|Pengalaman apa yang ingin kamu rasakan sekali seumur hidup?|Apa yang ingin kamu ingat tentang tahun ini?|Buku apa yang ingin kamu baca atau tulis?|Seperti apa pekerjaan idealmu dalam satu kalimat?|Apa satu ketakutan yang ingin kamu taklukkan?|Kebiasaan buruk apa yang ingin kamu ganti dengan yang lebih baik?|Apa tujuan keuanganmu yang paling dekat?|Hal apa yang ingin kamu lakukan bersama keluarga atau teman tahun ini?|Apa yang ingin kamu katakan pada dirimu lima tahun lagi?|Apa satu mimpi lama yang masih ingin kamu hidupkan?';

  @override
  String get updateCheckNotFound =>
      'Rilis belum ditemukan di GitHub. Coba lagi nanti.';

  @override
  String get updateCheckRateLimited =>
      'Terlalu sering mengecek. Coba lagi beberapa menit lagi.';

  @override
  String get updateCheckServer =>
      'Server GitHub sedang bermasalah. Coba lagi nanti.';

  @override
  String get calPrevMonth => 'Bulan sebelumnya';

  @override
  String get calNextMonth => 'Bulan berikutnya';

  @override
  String get calHint => 'Ketuk tanggal untuk melihat transaksi hari itu.';

  @override
  String get calShowAllDays => 'Tampilkan semua hari';

  @override
  String get calOut => 'Keluar';

  @override
  String get calIn => 'Masuk';

  @override
  String get calDayEmpty => 'Tidak ada transaksi di tanggal ini.';

  @override
  String get calRecord => 'Catat';

  @override
  String get calNoData => 'belum ada data';

  @override
  String get remSection => 'PENGINGAT DARI CERITAMU';

  @override
  String get remNone =>
      'Belum ada tanggal atau jam di ceritamu. Kalau kamu menyebut rencana, Nyaw menawarkan pengingat di sini.';

  @override
  String get remDetected => 'Terdeteksi acara';

  @override
  String get remWillRemind => 'Akan diingatkan';

  @override
  String get remAllDay => 'Sepanjang hari';

  @override
  String get remTomorrow => 'Besok';

  @override
  String remDaysLeft(int days) {
    return '$days hari lagi';
  }

  @override
  String get remAmbiguous => 'Jamnya belum jelas. Maksudmu yang mana?';

  @override
  String remMismatch(String date, String actual, String said) {
    return '$date jatuh hari $actual, bukan $said. Nyaw memakai tanggalnya.';
  }

  @override
  String get remAccept => 'Ingatkan aku';

  @override
  String get remEdit => 'Ubah';

  @override
  String get remDismiss => 'Abaikan';

  @override
  String remActive(String lead) {
    return 'Pengingat aktif · $lead';
  }

  @override
  String get remLeadAt => 'saat acara';

  @override
  String get remLeadHour => '1 jam sebelum';

  @override
  String get remLeadDay => '1 hari sebelum';

  @override
  String get remLeadMorning => 'pagi hari-H, 07.00';

  @override
  String get remLeadMorningShort => 'pagi hari-H';

  @override
  String get remPrivacy => 'Dikenali di HP-mu sendiri, tanpa internet.';

  @override
  String get remEditTitle => 'Ubah pengingat';

  @override
  String get remEditSub => 'Perbaiki kalau tebakan Nyaw kurang pas.';

  @override
  String get remFieldTitle => 'Judul acara';

  @override
  String get remFieldDate => 'Tanggal';

  @override
  String get remFieldTime => 'Jam';

  @override
  String get remFieldLead => 'Ingatkan';

  @override
  String get remSave => 'Simpan pengingat';

  @override
  String get remDefaultTitle => 'Acara';

  @override
  String get remPermTitle => 'Izinkan notifikasi?';

  @override
  String get remPermBody =>
      'Supaya Nyawtat bisa mengingatkanmu tepat waktu. Hanya ditanya sekali.';

  @override
  String get remPermHint =>
      'Tanpa izin, acara tetap tersimpan dan tampil di Hari Ini, tapi tidak ada notifikasi.';

  @override
  String get remPermLater => 'Nanti saja';

  @override
  String get remPermAllow => 'Izinkan';

  @override
  String get remUpcoming => 'Acara mendatang';

  @override
  String get remDenied =>
      'Notifikasi belum diizinkan, jadi acara hanya tampil di daftar ini.';

  @override
  String get remAllowButton => 'Izinkan notifikasi';

  @override
  String remLeadLine(String lead) {
    return 'Diingatkan $lead';
  }

  @override
  String remFrom(String date) {
    return 'Dari catatan $date';
  }

  @override
  String get remDelete => 'Hapus pengingat';

  @override
  String get remClose => 'Tutup';

  @override
  String get remNotifHour => '1 jam lagi';

  @override
  String get remNotifNow => 'Sekarang';

  @override
  String remCreated(int count) {
    return '$count pengingat dibuat';
  }

  @override
  String get fbTitle => 'Kirim masukan';

  @override
  String get fbSub => 'Lapor bug atau usul fitur';

  @override
  String get fbBug => 'Lapor bug';

  @override
  String get fbFeature => 'Usul fitur';

  @override
  String get fbArea => 'Bagian app';

  @override
  String get fbAreaReminders => 'Pengingat';

  @override
  String get fbAreaBackup => 'Backup & sync';

  @override
  String get fbAreaOther => 'Lainnya';

  @override
  String get fbBugTitle => 'Apa yang bermasalah?';

  @override
  String get fbBugTitleHint => 'mis. Grafik laporan tidak muncul';

  @override
  String get fbBugBody => 'Ceritakan langkahnya';

  @override
  String get fbBugBodyHint =>
      'Buka halaman apa, tekan apa, lalu apa yang terjadi';

  @override
  String get fbFeatureTitle => 'Fitur apa yang kamu mau?';

  @override
  String get fbFeatureTitleHint => 'mis. Widget ringkasan mingguan';

  @override
  String get fbFeatureBody => 'Kenapa berguna buatmu?';

  @override
  String get fbFeatureBodyHint => 'Ceritakan kapan kamu butuh fitur ini';

  @override
  String get fbTitleError => 'Isi minimal 5 huruf.';

  @override
  String get fbBodyError => 'Isi minimal 10 huruf.';

  @override
  String get fbSeverity => 'Seberapa mengganggu?';

  @override
  String get fbSevLow => 'Sedikit';

  @override
  String get fbSevMedium => 'Cukup';

  @override
  String get fbSevHigh => 'Parah';

  @override
  String get fbDevice => 'Sertakan info perangkat';

  @override
  String get fbDeviceSub => 'Versi app, versi sistem, dan tipe perangkat';

  @override
  String get fbPrivacy =>
      'Dikirim dari email kamu, jadi alamatmu terlihat oleh pembuat Nyawtat. Jurnal dan data keuanganmu tidak ikut. Jangan tulis nominal atau PIN di sini.';

  @override
  String get fbOpenMail => 'Buka aplikasi email';

  @override
  String get fbPreview => 'Lihat yang akan dikirim';

  @override
  String get fbPreviewTitle => 'Yang akan dikirim';

  @override
  String get fbNoTitle => '(judul belum diisi)';

  @override
  String get fbNoBody => '(cerita belum diisi)';

  @override
  String get fbPreviewSub =>
      'Hanya teks ini. Masih bisa diubah di aplikasi email.';

  @override
  String get fbTo => 'Ke';

  @override
  String get fbSubject => 'Subjek';

  @override
  String get fbClose => 'Tutup';

  @override
  String get fbNoMail => 'Aplikasi email tidak ditemukan';

  @override
  String get fbNoMailSub =>
      'Salin teksnya, lalu kirim dari email mana pun ke alamat ini.';

  @override
  String get fbCopyAddress => 'Salin alamat';

  @override
  String get fbCopyText => 'Salin teks';

  @override
  String get fbCopied => 'Tersalin';

  @override
  String get fbDoneTitle => 'Sudah tekan kirim di email?';

  @override
  String get fbDoneBody =>
      'Kalau sudah, makasih ya! Kalau belum, tulisanmu masih ada di sini.';

  @override
  String get fbDoneSent => 'Sudah dikirim';

  @override
  String get fbDoneAgain => 'Buka email lagi';

  @override
  String get fbDoneEdit => 'Ubah tulisan';

  @override
  String get fbDiscardTitle => 'Buang masukan ini?';

  @override
  String get fbDiscardBody => 'Tulisanmu belum dikirim dan akan hilang.';

  @override
  String get fbDiscard => 'Buang';

  @override
  String get fbKeep => 'Lanjut menulis';

  @override
  String fbMailArea(String area) {
    return 'Bagian: $area';
  }

  @override
  String fbMailSeverity(String level) {
    return 'Mengganggu: $level';
  }

  @override
  String get planTitle => 'Rencana harian';

  @override
  String get planTomorrow => 'Besok';

  @override
  String get planTodayTitle => 'Rencana hari ini';

  @override
  String planSummary(int done, int total) {
    return '$done dari $total selesai';
  }

  @override
  String get planNone => 'Belum ada rencana';

  @override
  String get planAll => 'Semua';

  @override
  String planMore(int count) {
    return '+$count lainnya';
  }

  @override
  String get planAllDone => 'Semua rencana hari ini selesai. Keren!';

  @override
  String planPercent(int percent) {
    return '$percent persen selesai';
  }

  @override
  String get planTomorrowAsk => 'Mau ngapain besok?';

  @override
  String get planTomorrowTitle => 'Rencana besok';

  @override
  String get planTomorrowNone => 'Belum ada rencana untuk besok';

  @override
  String planTomorrowCount(int count, String day) {
    return '$count rencana · $day';
  }

  @override
  String get planHint => 'mis. Olahraga pagi';

  @override
  String get planAddToday => 'Tambah rencana hari ini';

  @override
  String get planAddTomorrow => 'Tambah rencana besok';

  @override
  String planLeft(int count) {
    return '$count rencana sebelumnya belum selesai';
  }

  @override
  String get planLeftKeep => 'Biarkan';

  @override
  String get planMoveToday => 'Pindahkan ke hari ini';

  @override
  String get planMoveTomorrow => 'Pindahkan ke besok';

  @override
  String planCount(int count) {
    return '$count rencana';
  }

  @override
  String planDoneCount(int done, int total) {
    return '$done/$total selesai';
  }

  @override
  String get planEmptyToday => 'Belum ada rencana untuk hari ini.';

  @override
  String get planEmptyTomorrow =>
      'Tulis hal yang ingin kamu lakukan besok. Besok daftarnya muncul di Hari Ini.';

  @override
  String get planWeek => 'Progres 7 hari';

  @override
  String planWeekDone(int count) {
    return '$count hari tuntas';
  }

  @override
  String get planEdit => 'Atur rencana';

  @override
  String get planField => 'Isi rencana';

  @override
  String planMenu(String title) {
    return 'Atur $title';
  }

  @override
  String get planCard => 'Rencana';

  @override
  String get planCardEmpty =>
      'Mau ngapain hari ini atau besok? Tulis satu hal kecil dulu.';

  @override
  String get planCreate => 'Buat rencana';

  @override
  String get planWhen => 'Untuk kapan?';

  @override
  String get planTodayAsk => 'Mau ngapain hari ini?';

  @override
  String get planAddToList => 'Tambahkan ke daftar';

  @override
  String planUndo(String title) {
    return 'Batalkan $title';
  }

  @override
  String get planDone => 'Selesai';

  @override
  String get planSwipeTomorrow => 'Geser: besok';

  @override
  String get planSwipeToday => 'Geser: hari ini';

  @override
  String get planSeeToday => 'Lihat rencana hari ini';

  @override
  String get planSeeTomorrow => 'Lihat rencana besok';

  @override
  String get xlSheetSummary => 'Ringkasan';

  @override
  String get xlTitle => 'Ringkasan Nyawtat';

  @override
  String get xlAsOf => 'Data sampai';

  @override
  String get xlPickMonth => 'Pilih bulan';

  @override
  String get xlPickMonthHint => '‹ ubah lewat dropdown';

  @override
  String get xlSelectedMonth => 'Bulan dipilih';

  @override
  String get xlValue => 'Nilai';

  @override
  String get xlNet => 'Selisih';

  @override
  String get xlAvgPerDay => 'Rata-rata pengeluaran per hari';

  @override
  String get xlTxCount => 'Jumlah transaksi';

  @override
  String get xlTotalBalance => 'Total saldo dompet';

  @override
  String get xlPerMonth => 'Per bulan';

  @override
  String get xlByCategory => 'Pengeluaran per kategori';

  @override
  String get xlShare => 'Porsi';

  @override
  String get xlOthers => 'Lainnya (gabungan)';

  @override
  String get xlMoodOfMonth => 'Mood jurnal (bulan dipilih)';

  @override
  String get xlEntryCount => 'Jumlah entri';

  @override
  String get xlFilterTotal =>
      'Total mengikuti filter (Nominal = masuk − keluar, transfer tidak dihitung)';

  @override
  String get xlIn => 'Masuk';

  @override
  String get xlOut => 'Keluar';

  @override
  String get xlMainCategory => 'Kategori utama';

  @override
  String get xlChange => 'Perubahan';

  @override
  String get xlBalanceBefore => 'Saldo sebelum periode';

  @override
  String get xlBalanceEnd => 'Saldo akhir periode';

  @override
  String get xlTotal => 'Total';

  @override
  String get xlBudgetMonth => 'Budget bulan';

  @override
  String get xlUsedPercent => 'Terpakai %';

  @override
  String get xlChartCategory => 'Pengeluaran bulan dipilih';

  @override
  String get xlChartMonthly => 'Pemasukan dan pengeluaran per bulan';

  @override
  String get xlChartMood => 'Mood jurnal';

  @override
  String get xlChartWallet => 'Saldo per dompet';

  @override
  String get xlChartBudget => 'Batas dan terpakai';

  @override
  String get xlMillion => 'jt';

  @override
  String get xlLimit => 'Batas';

  @override
  String moreCount(int count) {
    return '+$count lagi';
  }

  @override
  String get noteEditAction => 'Edit catatan';

  @override
  String get noteKeyboard => 'Ketik';

  @override
  String get noteToolMoney => 'Uang';

  @override
  String get noteToolPhoto => 'Foto';

  @override
  String get noteToolRecord => 'Rekam';

  @override
  String get noteToolRecordAgain => 'Ulang';

  @override
  String get noteToolDictate => 'Dikte';

  @override
  String get noteToolTag => 'Tag';

  @override
  String get noteAddTime => '+ Jam';

  @override
  String get noteMoodAsk => 'Bagaimana perasaanmu?';

  @override
  String get noteMoodUndo => 'Ketuk lagi untuk membatalkan pilihan.';

  @override
  String get noteTagHint => 'mis. teman, kerja';

  @override
  String get noteTagLabel => 'Tag (pisahkan dengan koma)';

  @override
  String get noteTagEmpty => 'Belum ada tag.';

  @override
  String noteTagRemove(String tag) {
    return 'Hapus tag $tag';
  }

  @override
  String notePhotoLabel(int n) {
    return 'Lihat foto $n';
  }

  @override
  String get notePhotoRemove => 'Hapus foto';

  @override
  String get notePhotoMax => 'Maksimal 10 gambar';

  @override
  String get noteDiscardTitle => 'Simpan catatan ini?';

  @override
  String get noteDiscardBody => 'Ada tulisan yang belum disimpan.';

  @override
  String get noteKeepWriting => 'Lanjut menulis';

  @override
  String get noteDiscard => 'Buang';

  @override
  String get noteTxPanel => 'Transaksi dari catatan';

  @override
  String get noteTxEmpty =>
      'Tulis nominal di ceritamu, misalnya “kopi 25rb pakai GoPay”. Nyaw menawarkannya jadi transaksi, jadi tidak perlu dicatat dua kali.';

  @override
  String get noteTxRecord => 'Catat';

  @override
  String get noteTxRecordAll => 'Catat semua';

  @override
  String get noteTxRecorded => 'Dicatat';

  @override
  String get noteTxExists => 'Sudah ada';

  @override
  String get noteTxDismiss => 'Jangan catat';

  @override
  String noteTxCount(int count) {
    return '$count transaksi';
  }

  @override
  String noteTxSaved(int count) {
    return '$count transaksi dicatat';
  }

  @override
  String get noteTxNew => 'Baru';

  @override
  String get noteTxWithSave => 'ikut Simpan';

  @override
  String get noteTxAdd => 'Tambah transaksi';

  @override
  String get noteTxEdit => 'Ubah transaksi';

  @override
  String get noteTxWhen =>
      'Tanggal dan jam ikut catatan ini. Dicatat saat catatan disimpan.';

  @override
  String get noteTxNone => 'Belum ada';

  @override
  String get noteTxReceipt => 'Nota belanja (opsional)';

  @override
  String get noteTxReceiptFromNote => 'Pakai foto dari catatan ini';

  @override
  String noteTxPhotoN(int n) {
    return 'Foto $n';
  }

  @override
  String get noteTxPhotoFree => 'Belum dipakai';

  @override
  String noteTxPhotoUsed(String name) {
    return 'Dipakai $name';
  }

  @override
  String noteTxPhotoPick(int n) {
    return 'Pakai foto $n sebagai nota';
  }

  @override
  String get noteTxCamera => 'Kamera';

  @override
  String get noteTxGallery => 'Galeri';

  @override
  String noteTxReceiptFromPhoto(int n) {
    return 'Foto $n dari catatan ini. Foto tetap ada di catatan.';
  }

  @override
  String get noteTxReceiptOwn => 'Hanya tersimpan di transaksi.';

  @override
  String get noteTxReceiptView => 'Lihat nota';

  @override
  String get noteTxReceiptRemove => 'Hapus nota';

  @override
  String noteTxReceiptTag(int n) {
    return 'nota foto $n';
  }

  @override
  String get noteTxReceiptAny => 'ada nota';

  @override
  String get noteNoWallet =>
      'Buat dompet dulu di Keuangan untuk mencatat transaksi.';
}
