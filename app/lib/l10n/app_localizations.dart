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
  /// **'Nyawtat'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In id, this message translates to:
  /// **'jurnal & catatan uang'**
  String get splashTagline;

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

  /// No description provided for @transferFrom.
  ///
  /// In id, this message translates to:
  /// **'Dari'**
  String get transferFrom;

  /// No description provided for @transferTo.
  ///
  /// In id, this message translates to:
  /// **'Ke'**
  String get transferTo;

  /// No description provided for @walletBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo {amount}'**
  String walletBalance(String amount);

  /// No description provided for @swapWallets.
  ///
  /// In id, this message translates to:
  /// **'Tukar dompet asal dan tujuan'**
  String get swapWallets;

  /// No description provided for @transferOverdraw.
  ///
  /// In id, this message translates to:
  /// **'Saldo {wallet} kurang dari nominal. Tetap bisa disimpan.'**
  String transferOverdraw(String wallet);

  /// No description provided for @transferNeedsTwoWallets.
  ///
  /// In id, this message translates to:
  /// **'Transfer butuh minimal 2 dompet.'**
  String get transferNeedsTwoWallets;

  /// No description provided for @saveTransfer.
  ///
  /// In id, this message translates to:
  /// **'Simpan transfer'**
  String get saveTransfer;

  /// No description provided for @transferNoteHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: tarik tunai di ATM'**
  String get transferNoteHint;

  /// No description provided for @toastTransferSaved.
  ///
  /// In id, this message translates to:
  /// **'Transfer tersimpan'**
  String get toastTransferSaved;

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
  /// **'Pengeluaran, pemasukan, atau transfer'**
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

  /// No description provided for @appearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @themeSystemHint.
  ///
  /// In id, this message translates to:
  /// **'Mengikuti mode gelap di pengaturan HP. Widget layar utama ikut juga.'**
  String get themeSystemHint;

  /// No description provided for @themeLightHint.
  ///
  /// In id, this message translates to:
  /// **'Selalu terang, apa pun pengaturan HP. Widget layar utama ikut juga.'**
  String get themeLightHint;

  /// No description provided for @themeDarkHint.
  ///
  /// In id, this message translates to:
  /// **'Selalu gelap, apa pun pengaturan HP. Widget layar utama ikut juga.'**
  String get themeDarkHint;

  /// No description provided for @accentTitle.
  ///
  /// In id, this message translates to:
  /// **'Warna aksen'**
  String get accentTitle;

  /// No description provided for @accentHint.
  ///
  /// In id, this message translates to:
  /// **'Dipakai untuk tombol, ikon aktif, dan kartu Total saldo. Berlaku di mode terang dan gelap.'**
  String get accentHint;

  /// No description provided for @accentSage.
  ///
  /// In id, this message translates to:
  /// **'Hijau sage'**
  String get accentSage;

  /// No description provided for @accentOcean.
  ///
  /// In id, this message translates to:
  /// **'Biru laut'**
  String get accentOcean;

  /// No description provided for @accentViolet.
  ///
  /// In id, this message translates to:
  /// **'Ungu'**
  String get accentViolet;

  /// No description provided for @accentRose.
  ///
  /// In id, this message translates to:
  /// **'Mawar'**
  String get accentRose;

  /// No description provided for @accentPink.
  ///
  /// In id, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @accentAmber.
  ///
  /// In id, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentTeal.
  ///
  /// In id, this message translates to:
  /// **'Teal'**
  String get accentTeal;

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
  /// **'Nyawtat · versi {version}'**
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

  /// No description provided for @editWallet.
  ///
  /// In id, this message translates to:
  /// **'Ubah dompet'**
  String get editWallet;

  /// No description provided for @deleteWallet.
  ///
  /// In id, this message translates to:
  /// **'Hapus dompet'**
  String get deleteWallet;

  /// No description provided for @deleteWalletConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus dompet {name}?'**
  String deleteWalletConfirm(String name);

  /// No description provided for @deleteWalletTxWarning.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi di dompet ini juga ikut terhapus.'**
  String deleteWalletTxWarning(int count);

  /// No description provided for @lastWalletCantDelete.
  ///
  /// In id, this message translates to:
  /// **'Dompet terakhir tidak bisa dihapus.'**
  String get lastWalletCantDelete;

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

  /// No description provided for @showAllEntries.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan semua'**
  String get showAllEntries;

  /// No description provided for @journalDayEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada entri'**
  String get journalDayEmptyTitle;

  /// No description provided for @journalDayEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada catatan di tanggal ini.'**
  String get journalDayEmptyBody;

  /// No description provided for @writeForThisDay.
  ///
  /// In id, this message translates to:
  /// **'Tulis di tanggal ini'**
  String get writeForThisDay;

  /// No description provided for @prevWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu sebelumnya'**
  String get prevWeek;

  /// No description provided for @nextWeek.
  ///
  /// In id, this message translates to:
  /// **'Minggu berikutnya'**
  String get nextWeek;

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

  /// No description provided for @widgetBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo'**
  String get widgetBalance;

  /// No description provided for @widgetTodayOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar hari ini'**
  String get widgetTodayOut;

  /// No description provided for @widgetTodaySuffix.
  ///
  /// In id, this message translates to:
  /// **'keluar hari ini'**
  String get widgetTodaySuffix;

  /// No description provided for @widgetJournalTitle.
  ///
  /// In id, this message translates to:
  /// **'Jurnal hari ini'**
  String get widgetJournalTitle;

  /// No description provided for @widgetJournalSummary.
  ///
  /// In id, this message translates to:
  /// **'{count} entri · terakhir {time}'**
  String widgetJournalSummary(int count, String time);

  /// No description provided for @widgetJournalEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Gimana harimu?'**
  String get widgetJournalEmptyTitle;

  /// No description provided for @widgetJournalEmptySub.
  ///
  /// In id, this message translates to:
  /// **'Belum ada cerita hari ini'**
  String get widgetJournalEmptySub;

  /// No description provided for @widgetBudgetOver.
  ///
  /// In id, this message translates to:
  /// **'Budget {month} lewat {amount}'**
  String widgetBudgetOver(String month, String amount);

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

  /// No description provided for @errConfirmEmail.
  ///
  /// In id, this message translates to:
  /// **'Cek email kamu dan klik link konfirmasi, lalu masuk.'**
  String get errConfirmEmail;

  /// No description provided for @backendNotConfigured.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi belum diatur di build ini.'**
  String get backendNotConfigured;

  /// No description provided for @exportBackup.
  ///
  /// In id, this message translates to:
  /// **'Ekspor backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Semua data dalam satu file JSON'**
  String get exportBackupSub;

  /// No description provided for @exportExcel.
  ///
  /// In id, this message translates to:
  /// **'Ekspor ke Excel'**
  String get exportExcel;

  /// No description provided for @exportExcelSub.
  ///
  /// In id, this message translates to:
  /// **'Transaksi, jurnal, dompet, dan budget dalam satu file .xlsx'**
  String get exportExcelSub;

  /// No description provided for @sheetTransactions.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get sheetTransactions;

  /// No description provided for @currentBalance.
  ///
  /// In id, this message translates to:
  /// **'Saldo sekarang'**
  String get currentBalance;

  /// No description provided for @spent.
  ///
  /// In id, this message translates to:
  /// **'Terpakai'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get remaining;

  /// No description provided for @importBackup.
  ///
  /// In id, this message translates to:
  /// **'Impor backup'**
  String get importBackup;

  /// No description provided for @importBackupSub.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan data dari file backup'**
  String get importBackupSub;

  /// No description provided for @importConfirm.
  ///
  /// In id, this message translates to:
  /// **'Impor {file}?'**
  String importConfirm(String file);

  /// No description provided for @importConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Isi file digabung dengan data yang ada. Tidak ada yang dihapus; kalau ada data yang sama, versi yang lebih baru yang dipakai.'**
  String get importConfirmBody;

  /// No description provided for @importAction.
  ///
  /// In id, this message translates to:
  /// **'Impor'**
  String get importAction;

  /// No description provided for @importDone.
  ///
  /// In id, this message translates to:
  /// **'{imported} data diimpor, {skipped} sudah ada'**
  String importDone(int imported, int skipped);

  /// No description provided for @importInvalid.
  ///
  /// In id, this message translates to:
  /// **'File ini bukan backup Nyawtat yang valid.'**
  String get importInvalid;

  /// No description provided for @exportFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengekspor data.'**
  String get exportFailed;

  /// No description provided for @security.
  ///
  /// In id, this message translates to:
  /// **'Keamanan'**
  String get security;

  /// No description provided for @lockWithPin.
  ///
  /// In id, this message translates to:
  /// **'Kunci dengan PIN'**
  String get lockWithPin;

  /// No description provided for @lockWithPinSub.
  ///
  /// In id, this message translates to:
  /// **'Minta PIN saat app dibuka'**
  String get lockWithPinSub;

  /// No description provided for @unlockWithBiometric.
  ///
  /// In id, this message translates to:
  /// **'Buka dengan biometrik'**
  String get unlockWithBiometric;

  /// No description provided for @unlockWithBiometricSub.
  ///
  /// In id, this message translates to:
  /// **'Sidik jari atau wajah'**
  String get unlockWithBiometricSub;

  /// No description provided for @biometricUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Tidak tersedia di perangkat ini'**
  String get biometricUnavailable;

  /// No description provided for @lockNow.
  ///
  /// In id, this message translates to:
  /// **'Kunci aplikasi sekarang'**
  String get lockNow;

  /// No description provided for @enterPin.
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN untuk membuka'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In id, this message translates to:
  /// **'PIN salah'**
  String get wrongPin;

  /// No description provided for @tooManyAttempts.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Coba lagi dalam {seconds} detik.'**
  String tooManyAttempts(int seconds);

  /// No description provided for @useBiometric.
  ///
  /// In id, this message translates to:
  /// **'Pakai biometrik'**
  String get useBiometric;

  /// No description provided for @biometricReason.
  ///
  /// In id, this message translates to:
  /// **'Buka Nyawtat'**
  String get biometricReason;

  /// No description provided for @forgotPin.
  ///
  /// In id, this message translates to:
  /// **'Lupa PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset PIN?'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinBody.
  ///
  /// In id, this message translates to:
  /// **'Kamu akan keluar dari akun dan data di HP ini dihapus. Data yang sudah tersinkron tetap aman di server dan kembali saat kamu masuk lagi.'**
  String get forgotPinBody;

  /// No description provided for @forgotPinBodyLocal.
  ///
  /// In id, this message translates to:
  /// **'Semua data di HP ini akan dihapus permanen karena kamu belum masuk ke akun (belum ada salinan di server).'**
  String get forgotPinBodyLocal;

  /// No description provided for @resetPin.
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get resetPin;

  /// No description provided for @createPin.
  ///
  /// In id, this message translates to:
  /// **'Buat PIN'**
  String get createPin;

  /// No description provided for @createPinHint.
  ///
  /// In id, this message translates to:
  /// **'Pilih 4 angka yang mudah kamu ingat'**
  String get createPinHint;

  /// No description provided for @confirmPin.
  ///
  /// In id, this message translates to:
  /// **'Ulangi PIN'**
  String get confirmPin;

  /// No description provided for @confirmPinHint.
  ///
  /// In id, this message translates to:
  /// **'Ketik PIN yang sama sekali lagi'**
  String get confirmPinHint;

  /// No description provided for @pinMismatch.
  ///
  /// In id, this message translates to:
  /// **'PIN tidak sama. Ulangi dari awal.'**
  String get pinMismatch;

  /// No description provided for @currentPin.
  ///
  /// In id, this message translates to:
  /// **'PIN saat ini'**
  String get currentPin;

  /// No description provided for @currentPinHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN untuk melanjutkan'**
  String get currentPinHint;

  /// No description provided for @deleteDigit.
  ///
  /// In id, this message translates to:
  /// **'Hapus digit'**
  String get deleteDigit;

  /// No description provided for @transfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @csvDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get csvDate;

  /// No description provided for @csvTime.
  ///
  /// In id, this message translates to:
  /// **'Jam'**
  String get csvTime;

  /// No description provided for @csvType.
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get csvType;

  /// No description provided for @csvToWallet.
  ///
  /// In id, this message translates to:
  /// **'Dompet tujuan'**
  String get csvToWallet;

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

  /// No description provided for @mascotTodayEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Hai! Hari ini masih kosong'**
  String get mascotTodayEmptyTitle;

  /// No description provided for @mascotJournalEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada catatan'**
  String get mascotJournalEmptyTitle;

  /// No description provided for @mascotJournalEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Tulis sedikit tentang harimu: mood, cerita, atau pengeluaran.'**
  String get mascotJournalEmptyBody;

  /// No description provided for @mascotWriteEntry.
  ///
  /// In id, this message translates to:
  /// **'Tulis catatan'**
  String get mascotWriteEntry;

  /// No description provided for @mascotTxEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get mascotTxEmptyTitle;

  /// No description provided for @mascotTxEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Catat pemasukan atau pengeluaran pertamamu.'**
  String get mascotTxEmptyBody;

  /// No description provided for @mascotRecordTx.
  ///
  /// In id, this message translates to:
  /// **'Catat transaksi'**
  String get mascotRecordTx;

  /// No description provided for @mascotFilterEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Tidak ketemu'**
  String get mascotFilterEmptyTitle;

  /// No description provided for @mascotFilterEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi untuk filter ini.'**
  String get mascotFilterEmptyBody;

  /// No description provided for @mascotReportEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data bulan ini'**
  String get mascotReportEmptyTitle;

  /// No description provided for @mascotReportEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'Laporan muncul setelah kamu mencatat pengeluaran.'**
  String get mascotReportEmptyBody;

  /// No description provided for @mascotNoBudgetTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada budget'**
  String get mascotNoBudgetTitle;

  /// No description provided for @mascotNoBudgetBody.
  ///
  /// In id, this message translates to:
  /// **'Atur budget supaya pengeluaranmu terpantau.'**
  String get mascotNoBudgetBody;

  /// No description provided for @mascotBudgetOkTitle.
  ///
  /// In id, this message translates to:
  /// **'Semua budget masih aman'**
  String get mascotBudgetOkTitle;

  /// No description provided for @mascotBudgetOkBody.
  ///
  /// In id, this message translates to:
  /// **'Pertahankan sampai akhir bulan!'**
  String get mascotBudgetOkBody;

  /// No description provided for @mascotBudgetOverTitle.
  ///
  /// In id, this message translates to:
  /// **'{count} kategori lewat budget'**
  String mascotBudgetOverTitle(int count);

  /// No description provided for @mascotBudgetOverBody.
  ///
  /// In id, this message translates to:
  /// **'{names}. Coba rem sedikit, ya.'**
  String mascotBudgetOverBody(String names);

  /// No description provided for @toastEntrySaved.
  ///
  /// In id, this message translates to:
  /// **'Catatan tersimpan'**
  String get toastEntrySaved;

  /// No description provided for @toastEntryUpdated.
  ///
  /// In id, this message translates to:
  /// **'Catatan diperbarui'**
  String get toastEntryUpdated;

  /// No description provided for @toastTxSaved.
  ///
  /// In id, this message translates to:
  /// **'Transaksi tersimpan'**
  String get toastTxSaved;

  /// No description provided for @toastBudgetOver.
  ///
  /// In id, this message translates to:
  /// **'Budget {category} terlewati'**
  String toastBudgetOver(String category);

  /// No description provided for @toastSynced.
  ///
  /// In id, this message translates to:
  /// **'Sinkron selesai'**
  String get toastSynced;

  /// No description provided for @importMm.
  ///
  /// In id, this message translates to:
  /// **'Impor dari Money Manager'**
  String get importMm;

  /// No description provided for @importMmSub.
  ///
  /// In id, this message translates to:
  /// **'File cadangan .mmbak atau ekspor .xlsx dari Money Manager (Realbyte)'**
  String get importMmSub;

  /// No description provided for @importMmReading.
  ///
  /// In id, this message translates to:
  /// **'Membaca file…'**
  String get importMmReading;

  /// No description provided for @importMmNew.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi baru'**
  String importMmNew(int count);

  /// No description provided for @importMmBreakdown.
  ///
  /// In id, this message translates to:
  /// **'{expense} pengeluaran · {income} pemasukan · {transfer} transfer'**
  String importMmBreakdown(int expense, int income, int transfer);

  /// No description provided for @importMmPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode: {from} – {to}'**
  String importMmPeriod(String from, String to);

  /// No description provided for @importMmAlready.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi sudah pernah diimpor, dilewati.'**
  String importMmAlready(int count);

  /// No description provided for @importMmSkipped.
  ///
  /// In id, this message translates to:
  /// **'{count} transfer ke dompet yang sama dilewati.'**
  String importMmSkipped(int count);

  /// No description provided for @importMmAdjust.
  ///
  /// In id, this message translates to:
  /// **'{count} baris \"Edit saldo\" dimasukkan ke saldo awal dompet.'**
  String importMmAdjust(int count);

  /// No description provided for @importMmWallets.
  ///
  /// In id, this message translates to:
  /// **'Dompet'**
  String get importMmWallets;

  /// No description provided for @importMmNewWallet.
  ///
  /// In id, this message translates to:
  /// **'dompet baru'**
  String get importMmNewWallet;

  /// No description provided for @importMmNewCategories.
  ///
  /// In id, this message translates to:
  /// **'Kategori baru ({count})'**
  String importMmNewCategories(int count);

  /// No description provided for @importMmOverlap.
  ///
  /// In id, this message translates to:
  /// **'Transaksi yang kamu catat sendiri di Nyawtat tidak dicocokkan. Setelah impor, cek tanggal yang tumpang tindih supaya tidak dobel.'**
  String get importMmOverlap;

  /// No description provided for @importMmNothing.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data baru di file ini.'**
  String get importMmNothing;

  /// No description provided for @importMmDone.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi diimpor'**
  String importMmDone(int count);

  /// No description provided for @importMmInvalid.
  ///
  /// In id, this message translates to:
  /// **'File tidak dikenali sebagai data Money Manager.'**
  String get importMmInvalid;

  /// No description provided for @archiveWallet.
  ///
  /// In id, this message translates to:
  /// **'Arsipkan dompet'**
  String get archiveWallet;

  /// No description provided for @unarchiveWallet.
  ///
  /// In id, this message translates to:
  /// **'Keluarkan dari arsip'**
  String get unarchiveWallet;

  /// No description provided for @archiveWalletHint.
  ///
  /// In id, this message translates to:
  /// **'Dompet arsip tidak tampil di daftar dan total saldo, tapi transaksinya tetap ada di riwayat dan laporan.'**
  String get archiveWalletHint;

  /// No description provided for @archivedWalletsCard.
  ///
  /// In id, this message translates to:
  /// **'Arsip ({count})'**
  String archivedWalletsCard(int count);

  /// No description provided for @archivedWalletsTitle.
  ///
  /// In id, this message translates to:
  /// **'Dompet diarsipkan'**
  String get archivedWalletsTitle;

  /// No description provided for @walletArchivedBadge.
  ///
  /// In id, this message translates to:
  /// **'Diarsipkan'**
  String get walletArchivedBadge;

  /// No description provided for @toastWalletArchived.
  ///
  /// In id, this message translates to:
  /// **'Dompet diarsipkan'**
  String get toastWalletArchived;

  /// No description provided for @toastWalletUnarchived.
  ///
  /// In id, this message translates to:
  /// **'Dompet dikeluarkan dari arsip'**
  String get toastWalletUnarchived;

  /// No description provided for @importMmArchived.
  ///
  /// In id, this message translates to:
  /// **'diarsipkan'**
  String get importMmArchived;

  /// No description provided for @importMmMoved.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi yang sudah diimpor dipindah ke dompet yang benar.'**
  String importMmMoved(int count);

  /// No description provided for @currentBalanceHint.
  ///
  /// In id, this message translates to:
  /// **'Kalau saldo diubah, selisihnya dicatat sebagai transaksi Lainnya.'**
  String get currentBalanceHint;

  /// No description provided for @balanceAdjustmentNote.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian saldo'**
  String get balanceAdjustmentNote;

  /// No description provided for @manageWallets.
  ///
  /// In id, this message translates to:
  /// **'Kelola dompet'**
  String get manageWallets;

  /// No description provided for @manageAction.
  ///
  /// In id, this message translates to:
  /// **'Kelola'**
  String get manageAction;

  /// No description provided for @activeWallets.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get activeWallets;

  /// No description provided for @walletsTotal.
  ///
  /// In id, this message translates to:
  /// **'Total saldo {count} dompet aktif'**
  String walletsTotal(int count);

  /// No description provided for @walletTxCount.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi'**
  String walletTxCount(int count);

  /// No description provided for @archivedWalletLine.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi · saldo {amount}'**
  String archivedWalletLine(int count, String amount);

  /// No description provided for @unarchiveShort.
  ///
  /// In id, this message translates to:
  /// **'Keluarkan'**
  String get unarchiveShort;

  /// No description provided for @manageCategories.
  ///
  /// In id, this message translates to:
  /// **'Kelola kategori'**
  String get manageCategories;

  /// No description provided for @categoriesSub.
  ///
  /// In id, this message translates to:
  /// **'Urutkan, sembunyikan, atau gabungkan kategori'**
  String get categoriesSub;

  /// No description provided for @categoryReorderHint.
  ///
  /// In id, this message translates to:
  /// **'Tahan pegangan di kiri lalu geser untuk mengubah urutan. Urutan ini juga dipakai di form catat transaksi.'**
  String get categoryReorderHint;

  /// No description provided for @categorySystemBadge.
  ///
  /// In id, this message translates to:
  /// **'bawaan'**
  String get categorySystemBadge;

  /// No description provided for @categoryBudgetMeta.
  ///
  /// In id, this message translates to:
  /// **'budget {amount}'**
  String categoryBudgetMeta(String amount);

  /// No description provided for @hiddenCategoriesTitle.
  ///
  /// In id, this message translates to:
  /// **'Disembunyikan ({count})'**
  String hiddenCategoriesTitle(int count);

  /// No description provided for @hiddenCategoriesHint.
  ///
  /// In id, this message translates to:
  /// **'Tidak muncul di form catat transaksi. Transaksi lamanya tetap memakai kategori ini.'**
  String get hiddenCategoriesHint;

  /// No description provided for @noHiddenCategories.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kategori yang disembunyikan.'**
  String get noHiddenCategories;

  /// No description provided for @showCategory.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan'**
  String get showCategory;

  /// No description provided for @newExpenseCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pengeluaran baru'**
  String get newExpenseCategory;

  /// No description provided for @newIncomeCategory.
  ///
  /// In id, this message translates to:
  /// **'Kategori pemasukan baru'**
  String get newIncomeCategory;

  /// No description provided for @editCategory.
  ///
  /// In id, this message translates to:
  /// **'Ubah kategori'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In id, this message translates to:
  /// **'Contoh: Kuota, Admin bank'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi nama kategori dulu ya.'**
  String get categoryNameRequired;

  /// No description provided for @systemCategoryNameNote.
  ///
  /// In id, this message translates to:
  /// **'Nama kategori bawaan mengikuti bahasa app.'**
  String get systemCategoryNameNote;

  /// No description provided for @categoryColor.
  ///
  /// In id, this message translates to:
  /// **'Warna'**
  String get categoryColor;

  /// No description provided for @hideFromForm.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan dari form'**
  String get hideFromForm;

  /// No description provided for @showInForm.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan lagi di form'**
  String get showInForm;

  /// No description provided for @mergeCategory.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan ke kategori lain…'**
  String get mergeCategory;

  /// No description provided for @mergeCategoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan {name} ke…'**
  String mergeCategoryTitle(String name);

  /// No description provided for @mergeCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi akan dipindah, lalu kategori {name} dihapus.'**
  String mergeCategoryHint(int count, String name);

  /// No description provided for @mergeConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan kategori?'**
  String get mergeConfirmTitle;

  /// No description provided for @mergeConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'{count} transaksi di {from} akan dipindah ke {to}, lalu {from} dihapus. Ini tidak bisa dibatalkan.'**
  String mergeConfirmBody(int count, String from, String to);

  /// No description provided for @mergeAction.
  ///
  /// In id, this message translates to:
  /// **'Gabungkan'**
  String get mergeAction;

  /// No description provided for @deleteCategory.
  ///
  /// In id, this message translates to:
  /// **'Hapus kategori'**
  String get deleteCategory;

  /// No description provided for @deleteSystemCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Kategori bawaan tidak bisa dihapus, tapi bisa disembunyikan.'**
  String get deleteSystemCategoryHint;

  /// No description provided for @deleteUsedCategoryHint.
  ///
  /// In id, this message translates to:
  /// **'Masih dipakai {count} transaksi. Gabungkan dulu ke kategori lain.'**
  String deleteUsedCategoryHint(int count);

  /// No description provided for @toastCategorySaved.
  ///
  /// In id, this message translates to:
  /// **'Kategori tersimpan'**
  String get toastCategorySaved;

  /// No description provided for @toastCategoryHidden.
  ///
  /// In id, this message translates to:
  /// **'{name} disembunyikan'**
  String toastCategoryHidden(String name);

  /// No description provided for @toastCategoryShown.
  ///
  /// In id, this message translates to:
  /// **'{name} ditampilkan lagi'**
  String toastCategoryShown(String name);

  /// No description provided for @toastCategoryMerged.
  ///
  /// In id, this message translates to:
  /// **'{from} digabung ke {to}'**
  String toastCategoryMerged(String from, String to);

  /// No description provided for @toastCategoryDeleted.
  ///
  /// In id, this message translates to:
  /// **'Kategori dihapus'**
  String get toastCategoryDeleted;

  /// No description provided for @categoryIcon.
  ///
  /// In id, this message translates to:
  /// **'Ikon'**
  String get categoryIcon;

  /// No description provided for @categoryIconNone.
  ///
  /// In id, this message translates to:
  /// **'Tanpa ikon (huruf awal)'**
  String get categoryIconNone;

  /// No description provided for @iconFood.
  ///
  /// In id, this message translates to:
  /// **'Makan'**
  String get iconFood;

  /// No description provided for @iconCoffee.
  ///
  /// In id, this message translates to:
  /// **'Kopi'**
  String get iconCoffee;

  /// No description provided for @iconCar.
  ///
  /// In id, this message translates to:
  /// **'Mobil'**
  String get iconCar;

  /// No description provided for @iconMotorbike.
  ///
  /// In id, this message translates to:
  /// **'Motor'**
  String get iconMotorbike;

  /// No description provided for @iconShopping.
  ///
  /// In id, this message translates to:
  /// **'Belanja'**
  String get iconShopping;

  /// No description provided for @iconBills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get iconBills;

  /// No description provided for @iconData.
  ///
  /// In id, this message translates to:
  /// **'Kuota'**
  String get iconData;

  /// No description provided for @iconEntertainment.
  ///
  /// In id, this message translates to:
  /// **'Hiburan'**
  String get iconEntertainment;

  /// No description provided for @iconHealth.
  ///
  /// In id, this message translates to:
  /// **'Kesehatan'**
  String get iconHealth;

  /// No description provided for @iconEducation.
  ///
  /// In id, this message translates to:
  /// **'Pendidikan'**
  String get iconEducation;

  /// No description provided for @iconGift.
  ///
  /// In id, this message translates to:
  /// **'Hadiah'**
  String get iconGift;

  /// No description provided for @iconClothes.
  ///
  /// In id, this message translates to:
  /// **'Pakaian'**
  String get iconClothes;

  /// No description provided for @iconHome.
  ///
  /// In id, this message translates to:
  /// **'Rumah'**
  String get iconHome;

  /// No description provided for @iconFriends.
  ///
  /// In id, this message translates to:
  /// **'Teman'**
  String get iconFriends;

  /// No description provided for @iconCharity.
  ///
  /// In id, this message translates to:
  /// **'Sedekah'**
  String get iconCharity;

  /// No description provided for @iconSalary.
  ///
  /// In id, this message translates to:
  /// **'Gaji'**
  String get iconSalary;

  /// No description provided for @iconSavings.
  ///
  /// In id, this message translates to:
  /// **'Tabungan'**
  String get iconSavings;

  /// No description provided for @iconInvestment.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get iconInvestment;

  /// No description provided for @iconTravel.
  ///
  /// In id, this message translates to:
  /// **'Perjalanan'**
  String get iconTravel;

  /// No description provided for @search.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari jurnal, catatan, kategori, nominal…'**
  String get searchHint;

  /// No description provided for @clearText.
  ///
  /// In id, this message translates to:
  /// **'Hapus teks'**
  String get clearText;

  /// No description provided for @searchScopeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get searchScopeAll;

  /// No description provided for @searchScopeTx.
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get searchScopeTx;

  /// No description provided for @periodAll.
  ///
  /// In id, this message translates to:
  /// **'Semua waktu'**
  String get periodAll;

  /// No description provided for @periodThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get periodThisMonth;

  /// No description provided for @periodThreeMonths.
  ///
  /// In id, this message translates to:
  /// **'3 bulan'**
  String get periodThreeMonths;

  /// No description provided for @recentSearches.
  ///
  /// In id, this message translates to:
  /// **'Pencarian terakhir'**
  String get recentSearches;

  /// No description provided for @clearRecentSearches.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get clearRecentSearches;

  /// No description provided for @trySearching.
  ///
  /// In id, this message translates to:
  /// **'Coba cari'**
  String get trySearching;

  /// No description provided for @searchCountEntries.
  ///
  /// In id, this message translates to:
  /// **'{count} jurnal'**
  String searchCountEntries(int count);

  /// No description provided for @searchSumOut.
  ///
  /// In id, this message translates to:
  /// **'keluar {amount}'**
  String searchSumOut(String amount);

  /// No description provided for @searchSumIn.
  ///
  /// In id, this message translates to:
  /// **'masuk {amount}'**
  String searchSumIn(String amount);

  /// No description provided for @searchNotFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ketemu'**
  String get searchNotFound;

  /// No description provided for @searchNotFoundBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jurnal atau transaksi yang cocok dengan \"{query}\".'**
  String searchNotFoundBody(String query);

  /// No description provided for @searchNotFoundPeriodBody.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jurnal atau transaksi yang cocok dengan \"{query}\" di periode ini.'**
  String searchNotFoundPeriodBody(String query);
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
