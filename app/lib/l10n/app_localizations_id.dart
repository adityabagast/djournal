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
  String get deleteTxConfirm => 'Hapus transaksi ini?';

  @override
  String get quickAdd => 'Tambah cepat';

  @override
  String get quickAddTx => 'Catat transaksi';

  @override
  String get quickAddTxSub => 'Pengeluaran atau pemasukan';

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
  String get signOutConfirm => 'Keluar dari akun?';

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
}
