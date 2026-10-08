// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'djournal';

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
    return 'djournal · versi $version';
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
}
