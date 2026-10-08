import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'djournal'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get navToday;

  /// No description provided for @navJournal.
  ///
  /// In id, this message translates to:
  /// **'Jurnal'**
  String get navJournal;

  /// No description provided for @navMoney.
  ///
  /// In id, this message translates to:
  /// **'Keuangan'**
  String get navMoney;

  /// No description provided for @navReport.
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get navReport;

  /// No description provided for @add.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get add;

  /// No description provided for @back.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'Kemarin'**
  String get yesterday;

  /// No description provided for @comingSoon.
  ///
  /// In id, this message translates to:
  /// **'Segera hadir di fase berikutnya.'**
  String get comingSoon;

  /// No description provided for @todaySpent.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran hari ini'**
  String get todaySpent;

  /// No description provided for @monthSpent.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini {amount}'**
  String monthSpent(String amount);

  /// No description provided for @record.
  ///
  /// In id, this message translates to:
  /// **'Catat'**
  String get record;

  /// No description provided for @todayTimeline.
  ///
  /// In id, this message translates to:
  /// **'Timeline hari ini'**
  String get todayTimeline;

  /// No description provided for @write.
  ///
  /// In id, this message translates to:
  /// **'Tulis'**
  String get write;

  /// No description provided for @timelineEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan hari ini. Tulis jurnal atau catat transaksi pertamamu.'**
  String get timelineEmpty;

  /// No description provided for @totalBalance.
  ///
  /// In id, this message translates to:
  /// **'Total saldo'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In id, this message translates to:
  /// **'Pemasukan'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran'**
  String get expense;

  /// No description provided for @net.
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get net;

  /// No description provided for @wallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get wallets;

  /// No description provided for @addWallet.
  ///
  /// In id, this message translates to:
  /// **'Tambah dompet'**
  String get addWallet;

  /// No description provided for @filterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get filterAll;

  /// No description provided for @noTransactions.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi.'**
  String get noTransactions;

  /// No description provided for @addTxTitle.
  ///
  /// In id, this message translates to:
  /// **'Catat Transaksi'**
  String get addTxTitle;

  /// No description provided for @editTxTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Transaksi'**
  String get editTxTitle;

  /// No description provided for @amount.
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nominal dulu ya.'**
  String get amountRequired;

  /// No description provided for @category.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @wallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get wallet;

  /// No description provided for @time.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get time;

  /// No description provided for @note.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: makan siang di kantin'**
  String get noteHint;

  /// No description provided for @saveTx.
  ///
  /// In id, this message translates to:
  /// **'Simpan transaksi'**
  String get saveTx;

  /// No description provided for @deleteTxConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus transaksi ini?'**
  String get deleteTxConfirm;

  /// No description provided for @quickAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah cepat'**
  String get quickAdd;

  /// No description provided for @quickAddTx.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi'**
  String get quickAddTx;

  /// No description provided for @quickAddTxSub.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran atau pemasukan'**
  String get quickAddTxSub;

  /// No description provided for @quickAddJournal.
  ///
  /// In id, this message translates to:
  /// **'Tulis jurnal'**
  String get quickAddJournal;

  /// No description provided for @quickAddJournalSub.
  ///
  /// In id, this message translates to:
  /// **'Cerita baru, jam dan mood opsional'**
  String get quickAddJournalSub;

  /// No description provided for @reportByCategory.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaran per kategori'**
  String get reportByCategory;

  /// No description provided for @reportEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pengeluaran bulan ini.'**
  String get reportEmpty;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In id, this message translates to:
  /// **'Mata uang'**
  String get currency;

  /// No description provided for @currencyValue.
  ///
  /// In id, this message translates to:
  /// **'Rupiah (IDR)'**
  String get currencyValue;

  /// No description provided for @versionLabel.
  ///
  /// In id, this message translates to:
  /// **'djournal · versi {version}'**
  String versionLabel(String version);

  /// No description provided for @walletName.
  ///
  /// In id, this message translates to:
  /// **'Nama dompet'**
  String get walletName;

  /// No description provided for @walletNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: BCA, GoPay'**
  String get walletNameHint;

  /// No description provided for @walletType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get walletType;

  /// No description provided for @walletTypeCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get walletTypeCash;

  /// No description provided for @walletTypeBank.
  ///
  /// In id, this message translates to:
  /// **'Bank'**
  String get walletTypeBank;

  /// No description provided for @walletTypeEwallet.
  ///
  /// In id, this message translates to:
  /// **'E-wallet'**
  String get walletTypeEwallet;

  /// No description provided for @walletTypeOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get walletTypeOther;

  /// No description provided for @openingBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal'**
  String get openingBalance;

  /// No description provided for @walletNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nama dompet dulu ya.'**
  String get walletNameRequired;

  /// No description provided for @catFood.
  ///
  /// In id, this message translates to:
  /// **'Makan'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In id, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get catBills;

  /// No description provided for @catEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get catEntertainment;

  /// No description provided for @catOther.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In id, this message translates to:
  /// **'Gaji'**
  String get catSalary;

  /// No description provided for @catBonus.
  ///
  /// In id, this message translates to:
  /// **'Bonus'**
  String get catBonus;

  /// No description provided for @catOtherIncome.
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get catOtherIncome;

  /// No description provided for @moodAwful.
  ///
  /// In id, this message translates to:
  /// **'Buruk'**
  String get moodAwful;

  /// No description provided for @moodBad.
  ///
  /// In id, this message translates to:
  /// **'Kurang'**
  String get moodBad;

  /// No description provided for @moodOkay.
  ///
  /// In id, this message translates to:
  /// **'Biasa'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In id, this message translates to:
  /// **'Baik'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In id, this message translates to:
  /// **'Senang'**
  String get moodGreat;

  /// No description provided for @journalEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada entri jurnal. Mulai tulis cerita pertamamu.'**
  String get journalEmpty;

  /// No description provided for @dayMoodSummary.
  ///
  /// In id, this message translates to:
  /// **'Mood {mood}'**
  String dayMoodSummary(String mood);

  /// No description provided for @noSpending.
  ///
  /// In id, this message translates to:
  /// **'tanpa pengeluaran'**
  String get noSpending;

  /// No description provided for @untitled.
  ///
  /// In id, this message translates to:
  /// **'Tanpa judul'**
  String get untitled;

  /// No description provided for @newEntryTitle.
  ///
  /// In id, this message translates to:
  /// **'Tulis Entri'**
  String get newEntryTitle;

  /// No description provided for @editEntryTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Entri'**
  String get editEntryTitle;

  /// No description provided for @entryTime.
  ///
  /// In id, this message translates to:
  /// **'Jam kejadian'**
  String get entryTime;

  /// No description provided for @optional.
  ///
  /// In id, this message translates to:
  /// **'(opsional)'**
  String get optional;

  /// No description provided for @now.
  ///
  /// In id, this message translates to:
  /// **'Sekarang'**
  String get now;

  /// No description provided for @clearTime.
  ///
  /// In id, this message translates to:
  /// **'Hapus jam'**
  String get clearTime;

  /// No description provided for @pickTime.
  ///
  /// In id, this message translates to:
  /// **'Pilih jam'**
  String get pickTime;

  /// No description provided for @mood.
  ///
  /// In id, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @entryTitle.
  ///
  /// In id, this message translates to:
  /// **'Judul'**
  String get entryTitle;

  /// No description provided for @entryTitleHint.
  ///
  /// In id, this message translates to:
  /// **'Satu kalimat tentang kejadian ini'**
  String get entryTitleHint;

  /// No description provided for @story.
  ///
  /// In id, this message translates to:
  /// **'Cerita'**
  String get story;

  /// No description provided for @storyHint.
  ///
  /// In id, this message translates to:
  /// **'Apa yang terjadi? Apa yang kamu rasakan?'**
  String get storyHint;

  /// No description provided for @tags.
  ///
  /// In id, this message translates to:
  /// **'Tag'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In id, this message translates to:
  /// **'Pisahkan dengan koma, mis. teman, kerja'**
  String get tagsHint;

  /// No description provided for @dayTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi di hari ini'**
  String get dayTransactions;

  /// No description provided for @linkedByDate.
  ///
  /// In id, this message translates to:
  /// **'Otomatis terhubung lewat tanggal.'**
  String get linkedByDate;

  /// No description provided for @entryEmptyError.
  ///
  /// In id, this message translates to:
  /// **'Tulis judul atau cerita dulu ya.'**
  String get entryEmptyError;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus entri ini?'**
  String get deleteEntryConfirm;

  /// No description provided for @moodSpending.
  ///
  /// In id, this message translates to:
  /// **'Mood & pengeluaran'**
  String get moodSpending;

  /// No description provided for @avgGoodMood.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata saat mood baik'**
  String get avgGoodMood;

  /// No description provided for @avgLowMood.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata saat mood kurang'**
  String get avgLowMood;

  /// No description provided for @noData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get noData;

  /// No description provided for @insightNeedMore.
  ///
  /// In id, this message translates to:
  /// **'Tulis jurnal dengan mood beberapa hari lagi untuk melihat polanya.'**
  String get insightNeedMore;

  /// No description provided for @insightSpendWhenLow.
  ///
  /// In id, this message translates to:
  /// **'Kamu cenderung belanja lebih banyak saat harimu kurang baik. Coba tunda belanja impulsif di hari-hari berat.'**
  String get insightSpendWhenLow;

  /// No description provided for @insightSpendWhenGood.
  ///
  /// In id, this message translates to:
  /// **'Pengeluaranmu lebih besar di hari yang menyenangkan.'**
  String get insightSpendWhenGood;

  /// No description provided for @budget.
  ///
  /// In id, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budgetPerCategory.
  ///
  /// In id, this message translates to:
  /// **'Budget per kategori'**
  String get budgetPerCategory;

  /// No description provided for @manage.
  ///
  /// In id, this message translates to:
  /// **'Atur'**
  String get manage;

  /// No description provided for @budgetUsage.
  ///
  /// In id, this message translates to:
  /// **'Budget {month} terpakai {pct}% · sisa {left}'**
  String budgetUsage(String month, int pct, String left);

  /// No description provided for @budgetUsedPct.
  ///
  /// In id, this message translates to:
  /// **'{pct}% terpakai'**
  String budgetUsedPct(int pct);

  /// No description provided for @overBudget.
  ///
  /// In id, this message translates to:
  /// **'Lewat budget {amount}'**
  String overBudget(String amount);

  /// No description provided for @noBudget.
  ///
  /// In id, this message translates to:
  /// **'Tanpa budget'**
  String get noBudget;

  /// No description provided for @budgetLimit.
  ///
  /// In id, this message translates to:
  /// **'Batas per bulan'**
  String get budgetLimit;

  /// No description provided for @budgetHint.
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk tanpa budget'**
  String get budgetHint;

  /// No description provided for @budgetAppliesFrom.
  ///
  /// In id, this message translates to:
  /// **'Berlaku mulai {month} dan bulan-bulan berikutnya.'**
  String budgetAppliesFrom(String month);

  /// No description provided for @budgetSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Atur batas pengeluaran bulanan per kategori'**
  String get budgetSubtitle;

  /// No description provided for @budgetTotal.
  ///
  /// In id, this message translates to:
  /// **'Total budget'**
  String get budgetTotal;

  /// No description provided for @data.
  ///
  /// In id, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @account.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get account;

  /// No description provided for @signInPrompt.
  ///
  /// In id, this message translates to:
  /// **'Masuk supaya data tersimpan di server dan bisa dipakai di beberapa perangkat.'**
  String get signInPrompt;

  /// No description provided for @signIn.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get register;

  /// No description provided for @signOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In id, this message translates to:
  /// **'Minimal 8 karakter'**
  String get passwordHint;

  /// No description provided for @serverUrl.
  ///
  /// In id, this message translates to:
  /// **'Alamat server'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: http://localhost:5095'**
  String get serverUrlHint;

  /// No description provided for @haveAccount.
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? Masuk'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun? Daftar'**
  String get noAccount;

  /// No description provided for @syncNow.
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In id, this message translates to:
  /// **'Menyinkronkan…'**
  String get syncing;

  /// No description provided for @lastSynced.
  ///
  /// In id, this message translates to:
  /// **'Terakhir sinkron: {time}'**
  String lastSynced(String time);

  /// No description provided for @neverSynced.
  ///
  /// In id, this message translates to:
  /// **'Belum pernah sinkron'**
  String get neverSynced;

  /// No description provided for @signOutConfirm.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get signOutConfirm;

  /// No description provided for @signOutBody.
  ///
  /// In id, this message translates to:
  /// **'Data di perangkat ini akan dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.'**
  String get signOutBody;

  /// No description provided for @signOutUnsynced.
  ///
  /// In id, this message translates to:
  /// **'Ada perubahan yang belum tersinkron dan akan hilang kalau kamu keluar sekarang.'**
  String get signOutUnsynced;

  /// No description provided for @errNetwork.
  ///
  /// In id, this message translates to:
  /// **'Tidak bisa terhubung ke server. Cek alamat server dan koneksi.'**
  String get errNetwork;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In id, this message translates to:
  /// **'Email atau password salah.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailTaken.
  ///
  /// In id, this message translates to:
  /// **'Email ini sudah terdaftar. Coba masuk.'**
  String get errEmailTaken;

  /// No description provided for @errInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid.'**
  String get errInvalidEmail;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter.'**
  String get errPasswordTooShort;

  /// No description provided for @errSessionExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi berakhir. Silakan masuk lagi.'**
  String get errSessionExpired;

  /// No description provided for @errServer.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan di server. Coba lagi nanti.'**
  String get errServer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
